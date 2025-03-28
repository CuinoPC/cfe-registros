import 'dart:convert';
import 'dart:io';
import 'package:cfe_registros/services/api_terminal.dart';
import 'package:cfe_registros/services/api_terminal_supervision_honeywell.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/terminal.dart';

class UploadPhotosHoneywellPage extends StatefulWidget {
  final int terminalId;

  UploadPhotosHoneywellPage({required this.terminalId});

  @override
  _UploadPhotosHoneywellPageState createState() =>
      _UploadPhotosHoneywellPageState();
}

class _UploadPhotosHoneywellPageState extends State<UploadPhotosHoneywellPage> {
  final TerminalService _terminalService = TerminalService();
  final SupervisionHoneywellService _honeywellService =
      SupervisionHoneywellService();

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
              "rpe_usuario": "",
              "coincide_serie_fisica_vs_interna": 0,
              "fotografias_fisicas": "",
              "asignacion_usuario_sistic": 0,
              "registro_serie_sistic": 0,
              "centro_trabajo_sistic": 0,
              "asignacion_usuario_siitic": 0,
              "registro_serie_siitic": 0,
              "centro_trabajo_siitic": 0,
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
        "terminal_id": terminalId,
        "area": terminal.area,
        ...supervisiones,
        "total": total,
      };

      bool supervisionGuardada =
          await _honeywellService.saveHoneywellSupervision(data);
      if (!supervisionGuardada) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Error al guardar supervisión para terminal ID: $terminalId")),
        );
        return; // ⛔ No subir fotos si falla la supervisión
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
      return; // ⛔ No continuar si fallan las fotos
    }

    // ✅ Si todo bien
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

    if (kIsWeb) {
      List<String> base64Images = [];
      for (var file in _selectedPhotos) {
        Uint8List bytes = await file.readAsBytes();
        String base64String = base64Encode(bytes);
        base64Images.add(base64String);
      }
      await prefs.setStringList(
          'draft_fotos_honeywell_${widget.terminalId}', base64Images);
    } else {
      List<String> paths = _selectedPhotos.map((x) => x.path).toList();
      await prefs.setStringList(
          'draft_fotos_honeywell_${widget.terminalId}', paths);
    }

    Map<String, dynamic> convertedMap = _supervisionData.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    String jsonData = jsonEncode(convertedMap);
    await prefs.setString(
        'draft_data_honeywell_${widget.terminalId}', jsonData);
  }

  Future<void> _loadDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? storedData =
        prefs.getStringList('draft_fotos_honeywell_${widget.terminalId}');
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

    String? dataJson =
        prefs.getString('draft_data_honeywell_${widget.terminalId}');
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
    await prefs.remove('draft_fotos_honeywell_${widget.terminalId}');
    await prefs.remove('draft_data_honeywell_${widget.terminalId}');
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
                  minWidth: 2200,
                  headingRowColor: MaterialStateColor.resolveWith(
                      (states) => Colors.teal.shade100),
                  border: TableBorder.all(color: Colors.grey),
                  columns: const [
                    DataColumn(label: Text("Serie")),
                    DataColumn(label: Text("Inventario")),
                    DataColumn(label: Text("RPE Usuario")),
                    DataColumn(label: Text("Coincide serie física/interna")),
                    DataColumn(label: Text("Fotografías físicas (6)")),
                    DataColumn(label: Text("Asignación usuario SISTIC")),
                    DataColumn(label: Text("Registro serie SISTIC")),
                    DataColumn(label: Text("Centro trabajo SISTIC")),
                    DataColumn(label: Text("Asignación usuario SIITIC")),
                    DataColumn(label: Text("Registro serie SIITIC")),
                    DataColumn(label: Text("Centro trabajo SIITIC")),
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
