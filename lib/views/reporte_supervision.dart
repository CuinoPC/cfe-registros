import 'package:flutter/material.dart';
import '../services/api_terminales.dart';
import '../services/api_users.dart';
import '../models/terminal.dart';

class ReporteSupervision extends StatefulWidget {
  @override
  _ReporteSupervisionState createState() => _ReporteSupervisionState();
}

class _ReporteSupervisionState extends State<ReporteSupervision> {
  final ApiTerminalService _apiTerminalService = ApiTerminalService();
  final ApiUserService _apiUserService = ApiUserService();

  List<Map<String, dynamic>> _areas = [];
  String? _selectedArea;
  List<Terminal> _terminales = [];
  Map<int, Map<String, dynamic>> _supervisionData = {};

  @override
  void initState() {
    super.initState();
    _fetchAreas();
  }

  Future<void> _fetchAreas() async {
    List<Map<String, dynamic>>? areas = await _apiUserService.getAreas();
    if (areas != null) {
      setState(() {
        _areas = areas;
      });
    }
  }

  Future<void> _fetchTerminales(String area) async {
    List<Terminal>? terminales =
        await _apiTerminalService.getTerminalesPorArea(area);
    if (terminales != null) {
      setState(() {
        _terminales = terminales;
        // Inicializar valores de supervisión
        _supervisionData = {
          for (var terminal in terminales)
            terminal.id: {
              "anio_antiguedad": "",
              "rpe_usuario": "",
              "fotografias_fisicas": "",
              "etiqueta_activo_fijo": 1,
              "chip_con_serie_tableta": 1,
              "foto_carcasa": 1,
              "apn": 1,
              "correo_gmail": 1,
              "seguridad_desbloqueo": 1,
              "coincide_serie_sim_imei": 1,
              "responsiva_apn": 1,
              "centro_trabajo_correcto": 1,
              "responsiva": 0,
              "serie_correcta_sistic": 1,
              "serie_correcta_siitic": 1,
              "asignacion_rpe_mysap": 1,
            }
        };
      });
    }
  }

  // ✅ Función para guardar cambios SOLO cuando se presiona Enter
  Future<void> _guardarCambio(int terminalId) async {
    if (!_supervisionData.containsKey(terminalId)) return;

    Map<String, dynamic> data = {
      "terminal_id": terminalId,
      ..._supervisionData[terminalId]!,
      "total": calcularTotal(_supervisionData[terminalId]!),
    };

    bool success = await _apiTerminalService.saveSupervisionData(data);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al actualizar los datos de supervisión")),
      );
    }
  }

  int calcularTotal(Map<String, dynamic> terminal) {
    return terminal.values.where((value) => value == 1).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reporte de Supervisión")),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔽 Selector de área
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Selecciona un área"),
              value: _selectedArea,
              items: _areas.map((area) {
                return DropdownMenuItem<String>(
                  value: area['nom_area'],
                  child: Text(area['nom_area']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedArea = value;
                  _fetchTerminales(value!);
                });
              },
            ),
            SizedBox(height: 10),

            // 📋 Tabla de terminales
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Inventario")),
                    DataColumn(label: Text("Serie")),
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
                      DataCell(Text(terminal.inventario)),
                      DataCell(Text(terminal.serie)),

                      // 🔹 Campos editables (Solo guardan al presionar Enter)
                      DataCell(TextFormField(
                        initialValue:
                            _supervisionData[terminal.id]!["anio_antiguedad"],
                        textInputAction:
                            TextInputAction.done, // 🔹 Habilita Enter
                        onFieldSubmitted: (value) {
                          _supervisionData[terminal.id]!["anio_antiguedad"] =
                              value;
                          _guardarCambio(terminal.id);
                        },
                      )),
                      DataCell(TextFormField(
                        initialValue:
                            _supervisionData[terminal.id]!["rpe_usuario"],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (value) {
                          _supervisionData[terminal.id]!["rpe_usuario"] = value;
                          _guardarCambio(terminal.id);
                        },
                      )),
                      DataCell(TextFormField(
                        initialValue: _supervisionData[terminal.id]![
                            "fotografias_fisicas"],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (value) {
                          _supervisionData[terminal.id]![
                              "fotografias_fisicas"] = value;
                          _guardarCambio(terminal.id);
                        },
                      )),

                      // 🔹 Opciones "Sí/No"
                      ..._supervisionData[terminal.id]!.keys.skip(3).map((key) {
                        return DataCell(DropdownButton<int>(
                          value: _supervisionData[terminal.id]![key],
                          items: [
                            DropdownMenuItem(value: 1, child: Text("Sí")),
                            DropdownMenuItem(value: 0, child: Text("No")),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _supervisionData[terminal.id]![key] = value!;
                              _guardarCambio(terminal.id);
                            });
                          },
                        ));
                      }).toList(),

                      // 🔹 Campo TOTAL (Se actualiza en tiempo real)
                      DataCell(Text(
                          calcularTotal(_supervisionData[terminal.id]!)
                              .toString())),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
