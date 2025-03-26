import 'package:cfe_registros/services/api_terminales_supervision.dart';
import 'package:cfe_registros/utils/pdf_generator.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import '../services/api_users.dart';

class ReporteSupervision extends StatefulWidget {
  @override
  _ReporteSupervisionState createState() => _ReporteSupervisionState();
}

class _ReporteSupervisionState extends State<ReporteSupervision> {
  final SupervisionService _supervisionService = SupervisionService();
  final ApiUserService _apiUserService = ApiUserService();

  List<Map<String, dynamic>> _areas = [];
  String? _selectedArea;
  List<Map<String, dynamic>> _supervisionesDeArea = [];

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

  Future<void> _fetchSupervisionesPorArea(String area) async {
    final supervisiones =
        await _supervisionService.getSupervisionesPorArea(area);
    setState(() {
      _supervisionesDeArea = supervisiones;
    });
  }

  Future<void> _generarPDF() async {
    if (_selectedArea == null) return;

    final usuarios = await _apiUserService.getUsers();
    final jefe = usuarios?.firstWhere(
      (u) => u['es_centro'] == true && u['nom_area'] == _selectedArea,
      orElse: () => <String, dynamic>{},
    );

    final jefeCentro = jefe != null && jefe.isNotEmpty
        ? "${jefe['rp']}, ${jefe['nombre_completo']}"
        : "No asignado";

    const supervisorTIC = "9MAE4, ARTURO ALEJANDRO GIADANS PRIETO";

    if (_supervisionesDeArea.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay supervisiones para esta área")),
      );
      return;
    }

    await generarPDFReporte(
      area: _selectedArea!,
      supervisiones: _supervisionesDeArea,
      supervisorTIC: supervisorTIC,
      jefeCentro: jefeCentro,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Dropdown de área
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
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
                    });
                    _fetchSupervisionesPorArea(value!);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Botones PDF y Excel
            if (_selectedArea != null && _supervisionesDeArea.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Generar PDF"),
                    onPressed: _generarPDF,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 10),

            // Tabla
            Expanded(
              child: _selectedArea == null || _supervisionesDeArea.isEmpty
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
                        rows: _supervisionesDeArea.map((data) {
                          return DataRow(cells: [
                            DataCell(
                                Text(data["fecha"]?.split("T").first ?? "-")),
                            DataCell(Text(data["inventario"] ?? "-")),
                            DataCell(Text(data["serie"] ?? "-")),
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
