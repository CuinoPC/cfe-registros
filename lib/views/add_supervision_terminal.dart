import 'dart:convert';
import 'dart:io';
import 'package:cfe_registros/services/api_terminal.dart';
import 'package:cfe_registros/services/api_terminales_supervision.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/terminal.dart';

class UploadPhotosPage extends StatefulWidget {
  final int terminalId;

  UploadPhotosPage({required this.terminalId});

  @override
  _UploadPhotosPageState createState() => _UploadPhotosPageState();
}

class _UploadPhotosPageState extends State<UploadPhotosPage> {
  final TerminalService _terminalService = TerminalService();
  final SupervisionService _supervisionService = SupervisionService();

  List<XFile> _selectedPhotos = [];
  bool _isUploading = false;
  List<Terminal> _terminales = [];
  Map<int, Map<String, dynamic>> _supervisionData = {};

  @override
  void initState() {
    super.initState();
    _fetchSupervisionData();
    _loadDraft();
  }

  Future<void> _fetchSupervisionData() async {
    List<Terminal>? terminales = await _terminalService.getTerminales();
    if (terminales != null) {
      setState(() {
        _terminales =
            terminales.where((t) => t.id == widget.terminalId).toList();

        for (var terminal in _terminales) {
          if (!_supervisionData.containsKey(terminal.id)) {
            _supervisionData[terminal.id] = {
              "anio_antiguedad": "",
              "rpe_usuario": "",
              "fotografias_fisicas": "",
              "etiqueta_activo_fijo": 0,
              "chip_con_serie_tableta": 0,
              "foto_carcasa": 0,
              "apn": 0,
              "correo_gmail": 0,
              "seguridad_desbloqueo": 0,
              "coincide_serie_sim_imei": 0,
              "responsiva_apn": 0,
              "centro_trabajo_correcto": 0,
              "responsiva": 0,
              "serie_correcta_sistic": 0,
              "serie_correcta_siitic": 0,
              "asignacion_rpe_mysap": 0,
            };
          }
        }
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.length <= 10) {
      setState(() {
        _selectedPhotos = pickedFiles;
      });
      _saveDraft();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Máximo 10 imágenes permitidas")),
      );
    }
  }

  Future<void> _subirTodo() async {
    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona al menos una imagen")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // 🔹 Primero guardar supervisión
    for (var terminalId in _supervisionData.keys) {
      final supervisiones = _supervisionData[terminalId]!;
      final total = calcularTotal(supervisiones);
      final terminal = _terminales.firstWhere((t) => t.id == terminalId);

      Map<String, dynamic> data = {
        "terminal_id": terminalId.toString(),
        "area": terminal.area,
        ...supervisiones,
        "total": total,
      };

      bool supervisionGuardada =
          await _supervisionService.saveSupervisionData(data);
      if (!supervisionGuardada) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Error al guardar supervisión para terminal ID: $terminalId")),
        );
        return;
      }
    }

    // 🔹 Si TODAS las supervisiones se guardaron bien, subir las fotos
    bool fotosSubidas = await _terminalService.uploadTerminalPhotos(
        widget.terminalId, _selectedPhotos);

    if (!fotosSubidas) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No puedes subir más de 10 fotos en una semana")),
      );
      return;
    }

    setState(() {
      _isUploading = false;
    });

    await _clearDraft();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Fotos y supervisión guardadas correctamente")),
    );

    Navigator.pop(context, true);
  }

  int calcularTotal(Map<String, dynamic> terminal) {
    int total = 0;

    terminal.forEach((key, value) {
      if (value == 1) {
        total++;
      } else if (key == "fotografias_fisicas") {
        int? fotos = int.tryParse(value.toString());
        if (fotos != null) {
          total += fotos;
        }
      }
    });

    return total;
  }

  Future<void> _saveDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Guardar imágenes en Base64 si está en Web
    if (kIsWeb) {
      List<String> base64Images = [];
      for (var file in _selectedPhotos) {
        Uint8List bytes = await file.readAsBytes();
        String base64String = base64Encode(bytes);
        base64Images.add(base64String);
      }
      await prefs.setStringList(
          'draft_fotos_${widget.terminalId}', base64Images);
    } else {
      List<String> paths = _selectedPhotos.map((x) => x.path).toList();
      await prefs.setStringList('draft_fotos_${widget.terminalId}', paths);
    }

    // Convertir claves int a String antes de guardar
    Map<String, dynamic> convertedMap = _supervisionData.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    String jsonData = jsonEncode(convertedMap);
    await prefs.setString('draft_data_${widget.terminalId}', jsonData);
  }

  Future<void> _loadDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? storedData =
        prefs.getStringList('draft_fotos_${widget.terminalId}');
    if (storedData != null) {
      if (kIsWeb) {
        setState(() {
          _selectedPhotos = storedData.map((b64) {
            Uint8List bytes = base64Decode(b64);
            return XFile.fromData(bytes);
          }).toList();
        });
      } else {
        setState(() {
          _selectedPhotos = storedData.map((p) => XFile(p)).toList();
        });
      }
    }

    String? dataJson = prefs.getString('draft_data_${widget.terminalId}');
    if (dataJson != null) {
      Map<String, dynamic> dataMap = jsonDecode(dataJson);

      setState(() {
        _supervisionData = dataMap.map(
            (k, v) => MapEntry(int.parse(k), Map<String, dynamic>.from(v)));
      });
    }
  }

  Future<void> _clearDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_fotos_${widget.terminalId}');
    await prefs.remove('draft_data_${widget.terminalId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Seleccionar Fotos",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _selectedPhotos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: InteractiveViewer(
                            child: kIsWeb
                                ? Image.network(_selectedPhotos[index].path)
                                : Image.file(File(_selectedPhotos[index].path)),
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 200,
                      height: 250,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: kIsWeb
                            ? Image.network(
                                _selectedPhotos[index].path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_selectedPhotos[index].path),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DataTable2(
                  columnSpacing: 60,
                  horizontalMargin: 60,
                  minWidth:
                      3500, // Se ajusta el ancho mínimo igual que en la Tabla 2
                  headingRowColor: MaterialStateColor.resolveWith(
                      (states) => Colors.teal.shade100),
                  border: TableBorder.all(
                      color: Colors.grey), // Bordes en toda la tabla
                  columns: const [
                    DataColumn(label: Text("Serie")),
                    DataColumn(label: Text("Inventario")),
                    DataColumn(label: Text("Año de antigüedad")),
                    DataColumn(label: Text("RPE Usuario")),
                    DataColumn(label: Text("Fotografías físicas (6)")),
                    DataColumn(label: Text("Etiqueta Activo Fijo")),
                    DataColumn(label: Text("Chip con serie Tableta")),
                    DataColumn(label: Text("Foto de carcasa")),
                    DataColumn(label: Text("APN")),
                    DataColumn(label: Text("Correo GMAIL")),
                    DataColumn(label: Text("Seguridad de desbloqueo")),
                    DataColumn(label: Text("Coincide Serie, SIM, IMEI")),
                    DataColumn(label: Text("Responsiva APN")),
                    DataColumn(label: Text("Centro de trabajo correcto")),
                    DataColumn(label: Text("Responsiva")),
                    DataColumn(label: Text("Serie correcta en SISTIC")),
                    DataColumn(label: Text("Serie correcta en SIITIC")),
                    DataColumn(label: Text("Asignación de RPE vs MySAP")),
                    DataColumn(label: Text("TOTAL")),
                  ],
                  rows: _terminales.map((terminal) {
                    return DataRow(cells: [
                      DataCell(Text(terminal.serie)),
                      DataCell(Text(terminal.inventario)),
                      ..._supervisionData[terminal.id]!.entries.map((entry) {
                        return DataCell(
                          entry.value is int
                              ? Checkbox(
                                  value: entry.value == 1,
                                  onChanged: (bool? newValue) {
                                    setState(() {
                                      _supervisionData[terminal.id]![
                                          entry.key] = newValue! ? 1 : 0;
                                    });
                                    _saveDraft();
                                  },
                                )
                              : TextFormField(
                                  initialValue: entry.value.toString(),
                                  onChanged: (value) {
                                    setState(() {
                                      _supervisionData[terminal.id]![
                                          entry.key] = value;
                                    });
                                    _saveDraft();
                                  },
                                ),
                        );
                      }).toList(),
                      DataCell(Text(
                          calcularTotal(_supervisionData[terminal.id]!)
                              .toString())),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _subirTodo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Subir Fotos y Guardar Supervisión",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
