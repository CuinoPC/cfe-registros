import 'dart:convert';
import 'dart:io';
import 'package:cfe_registros/services/api_lector.dart';
import 'package:cfe_registros/services/api_lectores_supervision.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lector.dart';

class UploadLectorPhotosPage extends StatefulWidget {
  final int lectorId;

  const UploadLectorPhotosPage({super.key, required this.lectorId});

  @override
  State<UploadLectorPhotosPage> createState() => _UploadLectorPhotosPageState();
}

class _UploadLectorPhotosPageState extends State<UploadLectorPhotosPage> {
  final LectorService _lectorService = LectorService();
  final SupervisionLectorService _supervisionService =
      SupervisionLectorService();

  List<XFile> _selectedPhotos = [];
  bool _isUploading = false;
  List<Lector> _lectores = [];
  Map<int, Map<String, dynamic>> _supervisionData = {};

  @override
  void initState() {
    super.initState();
    _fetchSupervisionData();
    _loadDraft();
  }

  Future<void> _fetchSupervisionData() async {
    List<Lector>? lectores = await _lectorService.getLectores();
    if (lectores != null) {
      setState(() {
        _lectores = lectores.where((l) => l.id == widget.lectorId).toList();

        for (var lector in _lectores) {
          if (!_supervisionData.containsKey(lector.id)) {
            _supervisionData[lector.id] = {
              "fotografia_conector": 0,
              "fotografia_cincho_folio": 0,
              "fotografia_cabezal": 0,
              "registro_ctrl_lectores": 0,
              "ubicacion_ctrl_lectores": 0,
              "registro_siitic": 0,
              "ubicacion_siitic": 0,
            };
          }
        }
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.length <= 7) {
      setState(() => _selectedPhotos = pickedFiles);
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

    bool fotosSubidas = await _lectorService.uploadLectorPhotos(
        widget.lectorId, _selectedPhotos);

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

    for (var lectorId in _supervisionData.keys) {
      final supervisiones = _supervisionData[lectorId]!;
      final total = calcularTotal(supervisiones);
      final lector = _lectores.firstWhere((l) => l.id == lectorId);

      Map<String, dynamic> data = {
        "lector_id": lectorId.toString(),
        "area": lector.area,
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
                  "Error al guardar supervisión para lector ID: $lectorId")),
        );
        return;
      }
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

  int calcularTotal(Map<String, dynamic> data) {
    int total = 0;

    data.forEach((key, value) {
      if (value == 1) {
        total++;
      } else if (key == "fotografias_fisicas") {
        int? fotos = int.tryParse(value.toString());
        if (fotos != null) total += fotos;
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
        base64Images.add(base64Encode(bytes));
      }
      await prefs.setStringList(
          'draft_fotos_lector_${widget.lectorId}', base64Images);
    } else {
      List<String> paths = _selectedPhotos.map((x) => x.path).toList();
      await prefs.setStringList('draft_fotos_lector_${widget.lectorId}', paths);
    }

    final jsonData = jsonEncode(
      _supervisionData.map((k, v) => MapEntry(k.toString(), v)),
    );
    await prefs.setString('draft_data_lector_${widget.lectorId}', jsonData);
  }

  Future<void> _loadDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final storedData =
        prefs.getStringList('draft_fotos_lector_${widget.lectorId}');
    if (storedData != null) {
      if (kIsWeb) {
        setState(() {
          _selectedPhotos = storedData
              .map((b64) => XFile.fromData(base64Decode(b64)))
              .toList();
        });
      } else {
        setState(() {
          _selectedPhotos = storedData.map((p) => XFile(p)).toList();
        });
      }
    }

    String? dataJson = prefs.getString('draft_data_lector_${widget.lectorId}');
    if (dataJson != null) {
      Map<String, dynamic> dataMap = jsonDecode(dataJson);
      setState(() {
        _supervisionData = dataMap.map(
          (k, v) => MapEntry(int.parse(k), Map<String, dynamic>.from(v)),
        );
      });
    }
  }

  Future<void> _clearDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_fotos_lector_${widget.lectorId}');
    await prefs.remove('draft_data_lector_${widget.lectorId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 📸 Botón de selección de fotos
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

            // 🖼️ Galería de fotos
            Expanded(
              child: GridView.builder(
                itemCount: _selectedPhotos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (_, index) {
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

            // 📋 Tabla de supervisión
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DataTable2(
                  columnSpacing: 60,
                  horizontalMargin: 60,
                  minWidth: 3500,
                  headingRowColor: MaterialStateColor.resolveWith(
                      (states) => Colors.teal.shade100),
                  border: TableBorder.all(color: Colors.grey),
                  columns: const [
                    DataColumn(label: Text("Marca")),
                    DataColumn(label: Text("Modelo")),
                    DataColumn(label: Text("Folio")),
                    DataColumn(label: Text("Tipo de Conector")),
                    DataColumn(label: Text("Fotografía conector")),
                    DataColumn(label: Text("Fotografía cincho/folio")),
                    DataColumn(label: Text("Fotografía cabezal")),
                    DataColumn(label: Text("Registro Ctrl Lectores")),
                    DataColumn(label: Text("Ubicación Ctrl Lectores")),
                    DataColumn(label: Text("Registro SIITIC")),
                    DataColumn(label: Text("Ubicación SIITIC")),
                    DataColumn(label: Text("TOTAL")),
                  ],
                  rows: _lectores.map((lector) {
                    final supervisiones = _supervisionData[lector.id]!;
                    return DataRow(cells: [
                      DataCell(Text(lector.marca)),
                      DataCell(Text(lector.modelo)),
                      DataCell(Text(lector.folio)),
                      DataCell(Text(lector.tipoConector)),
                      ...supervisiones.entries.map((entry) {
                        return DataCell(
                          entry.value is int
                              ? Checkbox(
                                  value: entry.value == 1,
                                  onChanged: (bool? newValue) {
                                    setState(() {
                                      supervisiones[entry.key] =
                                          newValue! ? 1 : 0;
                                    });
                                    _saveDraft();
                                  },
                                )
                              : TextFormField(
                                  initialValue: entry.value.toString(),
                                  onChanged: (value) {
                                    setState(() {
                                      supervisiones[entry.key] = value;
                                    });
                                    _saveDraft();
                                  },
                                ),
                        );
                      }).toList(),
                      DataCell(Text(calcularTotal(supervisiones).toString())),
                    ]);
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ⬆️ Botón de subir
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
