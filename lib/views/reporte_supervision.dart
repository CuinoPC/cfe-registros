import 'package:cfe_registros/services/api_terminal.dart';
import 'package:cfe_registros/services/api_terminales_supervision.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import '../services/api_users.dart';
import '../models/terminal.dart';

class ReporteSupervision extends StatefulWidget {
  @override
  _ReporteSupervisionState createState() => _ReporteSupervisionState();
}

class _ReporteSupervisionState extends State<ReporteSupervision> {
  final TerminalService _apiTerminalService = TerminalService();
  final SupervisionService _supervisionService = SupervisionService();
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
      });

      // 🔄 Recuperar los datos guardados desde el backend
      for (var terminal in terminales) {
        final historial =
            await _supervisionService.getHistorialSupervision(terminal.id);
        if (historial.isNotEmpty) {
          setState(() {
            _supervisionData[terminal.id] = historial.first;
          });
        }
      }
    }
  }

  int calcularTotal(Map<String, dynamic> terminal) {
    return terminal.values.where((value) => value == 1).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.teal.shade200, width: 1.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration.collapsed(hintText: ''),
                  value: _selectedArea,
                  isExpanded: true,
                  hint: const Text("Selecciona un área"),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.teal),
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  dropdownColor: Colors.white,
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
              ),
            ),

            const SizedBox(height: 10),

            /// 🔽 Mostrar mensaje si no se ha seleccionado nada o no hay datos
            Expanded(
              child: _selectedArea == null || _terminales.isEmpty
                  ? const Center(
                      child: Text(
                        "Selecciona un área para ver el reporte de supervisión",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DataTable2(
                        columnSpacing: 32,
                        horizontalMargin: 32,
                        minWidth: 3500,
                        headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors.teal.shade100),
                        border: TableBorder.all(color: Colors.grey),
                        columns: const [
                          DataColumn(label: Text("Fecha")),
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
                          final data = _supervisionData[terminal.id] ?? {};
                          return DataRow(cells: [
                            DataCell(
                                Text(data["fecha"]?.split("T").first ?? "-")),
                            DataCell(Text(terminal.inventario)),
                            DataCell(Text(terminal.serie)),
                            DataCell(Text(data["anio_antiguedad"] ?? "-")),
                            DataCell(Text(data["rpe_usuario"] ?? "-")),
                            DataCell(
                                Text('${data["fotografias_fisicas"] ?? "-"}')),
                            _buildBoolCell(data["etiqueta_activo_fijo"]),
                            _buildBoolCell(data["chip_con_serie_tableta"]),
                            _buildBoolCell(data["foto_carcasa"]),
                            _buildBoolCell(data["apn"]),
                            _buildBoolCell(data["correo_gmail"]),
                            _buildBoolCell(data["seguridad_desbloqueo"]),
                            _buildBoolCell(data["coincide_serie_sim_imei"]),
                            _buildBoolCell(data["responsiva_apn"]),
                            _buildBoolCell(data["centro_trabajo_correcto"]),
                            _buildBoolCell(data["responsiva"]),
                            _buildBoolCell(data["serie_correcta_sistic"]),
                            _buildBoolCell(data["serie_correcta_siitic"]),
                            _buildBoolCell(data["asignacion_rpe_mysap"]),
                            DataCell(Text(data["total"]?.toString() ?? "0")),
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

  DataCell _buildBoolCell(dynamic value) {
    final display = (value == 1) ? "Sí" : "No";
    return DataCell(Text(display));
  }
}
