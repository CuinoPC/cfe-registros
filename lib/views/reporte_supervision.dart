import 'package:cfe_registros/services/api_terminal_supervision_honeywell.dart';
import 'package:cfe_registros/services/api_terminales_supervision.dart';
import 'package:cfe_registros/services/api_lectores_supervision.dart';
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
  final SupervisionService _supervisionTerminalService = SupervisionService();
  final SupervisionLectorService _supervisionLectorService =
      SupervisionLectorService();
  final SupervisionHoneywellService _supervisionHoneywellService =
      SupervisionHoneywellService();
  final ApiUserService _apiUserService = ApiUserService();

  List<Map<String, dynamic>> _areas = [];
  String? _selectedArea;
  DateTime? _fechaSeleccionada;

  List<Map<String, dynamic>> _supervisionesTerminales = [];
  List<Map<String, dynamic>> _supervisionesLectores = [];
  List<Map<String, dynamic>> _supervisionesHoneywell = [];

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
    final supervisionesTerminales =
        await _supervisionTerminalService.getSupervisionesPorArea(area);
    final supervisionesLectores =
        await _supervisionLectorService.getSupervisionesPorArea(area);
    final supervisionesHoneywell = await _supervisionHoneywellService
        .getHoneywellSupervisionesByArea(area);

    setState(() {
      _supervisionesTerminales = supervisionesTerminales;
      _supervisionesLectores = supervisionesLectores;
      _supervisionesHoneywell = supervisionesHoneywell;
    });
  }

  List<Map<String, dynamic>> _getSupervisionesTerminalesFiltradas() {
    if (_fechaSeleccionada == null) return _supervisionesTerminales;
    return _supervisionesTerminales.where((data) {
      final fecha = DateTime.tryParse(data["fecha"] ?? '');
      if (fecha == null) return false;
      return fecha.year == _fechaSeleccionada!.year &&
          fecha.month == _fechaSeleccionada!.month &&
          fecha.day == _fechaSeleccionada!.day;
    }).toList();
  }

  List<Map<String, dynamic>> _getSupervisionesLectoresFiltradas() {
    if (_fechaSeleccionada == null) return _supervisionesLectores;
    return _supervisionesLectores.where((data) {
      final fecha = DateTime.tryParse(data["fecha"] ?? '');
      if (fecha == null) return false;
      return fecha.year == _fechaSeleccionada!.year &&
          fecha.month == _fechaSeleccionada!.month &&
          fecha.day == _fechaSeleccionada!.day;
    }).toList();
  }

  List<Map<String, dynamic>> _getSupervisionesHoneywellFiltradas() {
    if (_fechaSeleccionada == null) return _supervisionesHoneywell;
    return _supervisionesHoneywell.where((data) {
      final fecha = DateTime.tryParse(data["fecha"] ?? '');
      if (fecha == null) return false;
      return fecha.year == _fechaSeleccionada!.year &&
          fecha.month == _fechaSeleccionada!.month &&
          fecha.day == _fechaSeleccionada!.day;
    }).toList();
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

    final supervisionesFiltradasTerminales =
        _getSupervisionesTerminalesFiltradas();
    final supervisionesFiltradasLectores = _getSupervisionesLectoresFiltradas();
    final supervisionesFiltradasHoneywell =
        _getSupervisionesHoneywellFiltradas();

    if (supervisionesFiltradasTerminales.isEmpty &&
        supervisionesFiltradasLectores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "No hay supervisiones para esta área en la fecha seleccionada"),
        ),
      );
      return;
    }

    await generarPDFReporte(
      area: _selectedArea!,
      supervisiones: supervisionesFiltradasTerminales,
      supervisionesLectores:
          supervisionesFiltradasLectores, // 👈 aquí se agrega
      supervisorTIC: supervisorTIC,
      jefeCentro: jefeCentro,
    );
  }

  @override
  Widget build(BuildContext context) {
    final supervisionesTerminales = _getSupervisionesTerminalesFiltradas();
    final supervisionesLectores = _getSupervisionesLectoresFiltradas();
    final supervisionesHoneywell = _getSupervisionesHoneywellFiltradas();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: CustomAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _buildDropdownArea(),
              const SizedBox(height: 10),
              _buildFiltroFecha(),
              const SizedBox(height: 10),
              if (_selectedArea != null &&
                  (supervisionesTerminales.isNotEmpty ||
                      supervisionesLectores.isNotEmpty))
                _buildBotonPDF(),
              const SizedBox(height: 10),
              if (_selectedArea == null ||
                  (supervisionesTerminales.isEmpty &&
                      supervisionesLectores.isEmpty))
                const Expanded(
                  child: Center(
                    child: Text(
                      "Selecciona un área para ver el reporte de supervisión",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Colors.teal,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: 'NEWLAND'),
                          Tab(text: 'Honeywell'),
                          Tab(text: 'Lectores'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildTablaTerminales(supervisionesTerminales),
                            _buildTablaHoneywell(supervisionesHoneywell),
                            _buildTablaLectores(supervisionesLectores),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTablaTerminales(List<Map<String, dynamic>> data) {
    return DataTable2(
      columnSpacing: 32,
      horizontalMargin: 32,
      minWidth: 3500,
      headingRowColor:
          MaterialStateColor.resolveWith((states) => Colors.teal.shade100),
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
      rows: data.map((d) {
        return DataRow(cells: [
          DataCell(Text(d["fecha"]?.split("T").first ?? "-")),
          DataCell(Text(d["inventario"] ?? "-")),
          DataCell(Text(d["serie"] ?? "-")),
          DataCell(Text(d["anio_antiguedad"] ?? "-")),
          DataCell(Text(d["rpe_usuario"] ?? "-")),
          DataCell(Text('${d["fotografias_fisicas"] ?? "-"}')),
          _buildBoolCell(d["etiqueta_activo_fijo"]),
          _buildBoolCell(d["chip_con_serie_tableta"]),
          _buildBoolCell(d["foto_carcasa"]),
          _buildBoolCell(d["apn"]),
          _buildBoolCell(d["correo_gmail"]),
          _buildBoolCell(d["seguridad_desbloqueo"]),
          _buildBoolCell(d["coincide_serie_sim_imei"]),
          _buildBoolCell(d["responsiva_apn"]),
          _buildBoolCell(d["centro_trabajo_correcto"]),
          _buildBoolCell(d["responsiva"]),
          _buildBoolCell(d["serie_correcta_sistic"]),
          _buildBoolCell(d["serie_correcta_siitic"]),
          _buildBoolCell(d["asignacion_rpe_mysap"]),
          DataCell(Text(d["total"]?.toString() ?? "0")),
        ]);
      }).toList(),
    );
  }

  Widget _buildTablaLectores(List<Map<String, dynamic>> data) {
    return DataTable2(
      columnSpacing: 32,
      horizontalMargin: 32,
      minWidth: 2500,
      headingRowColor:
          MaterialStateColor.resolveWith((states) => Colors.teal.shade100),
      border: TableBorder.all(color: Colors.grey),
      columns: const [
        DataColumn(label: Text("Fecha")),
        DataColumn(label: Text("Folio")),
        DataColumn(label: Text("Marca")),
        DataColumn(label: Text("Modelo")),
        DataColumn(label: Text("Tipo Conector")),
        DataColumn(label: Text("Conector")),
        DataColumn(label: Text("Cincho/Folio")),
        DataColumn(label: Text("Cabezal")),
        DataColumn(label: Text("Registro CTRL L.")),
        DataColumn(label: Text("Ubicación CTRL L.")),
        DataColumn(label: Text("Registro SIITIC")),
        DataColumn(label: Text("Ubicación SIITIC")),
        DataColumn(label: Text("TOTAL")),
      ],
      rows: data.map((d) {
        return DataRow(cells: [
          DataCell(Text(d["fecha"]?.split("T").first ?? "-")),
          DataCell(Text(d["folio"] ?? "-")),
          DataCell(Text(d["marca"] ?? "-")),
          DataCell(Text(d["modelo"] ?? "-")),
          DataCell(Text(d["tipo_conector"] ?? "-")),
          _buildBoolCell(d["fotografia_conector"]),
          _buildBoolCell(d["fotografia_cincho_folio"]),
          _buildBoolCell(d["fotografia_cabezal"]),
          _buildBoolCell(d["registro_ctrl_lectores"]),
          _buildBoolCell(d["ubicacion_ctrl_lectores"]),
          _buildBoolCell(d["registro_siitic"]),
          _buildBoolCell(d["ubicacion_siitic"]),
          DataCell(Text(d["total"]?.toString() ?? "0")),
        ]);
      }).toList(),
    );
  }

  Widget _buildTablaHoneywell(List<Map<String, dynamic>> data) {
    return DataTable2(
      columnSpacing: 32,
      horizontalMargin: 32,
      minWidth: 2500,
      headingRowColor:
          MaterialStateColor.resolveWith((states) => Colors.teal.shade100),
      border: TableBorder.all(color: Colors.grey),
      columns: const [
        DataColumn(label: Text("Fecha")),
        DataColumn(label: Text("Serie")),
        DataColumn(label: Text("RPE Usuario")),
        DataColumn(label: Text("Coincide Serie Física vs Interna")),
        DataColumn(label: Text("Fotografías físicas")),
        DataColumn(label: Text("Asignación Usuario SISTIC")),
        DataColumn(label: Text("Registro Serie SISTIC")),
        DataColumn(label: Text("Centro Trabajo SISTIC")),
        DataColumn(label: Text("Asignación Usuario SIITIC")),
        DataColumn(label: Text("Registro Serie SIITIC")),
        DataColumn(label: Text("Centro Trabajo SIITIC")),
        DataColumn(label: Text("TOTAL")),
      ],
      rows: data.map((d) {
        return DataRow(cells: [
          DataCell(Text(d["fecha"]?.split("T").first ?? "-")),
          DataCell(Text(d["serie"] ?? "-")),
          DataCell(Text(d["rpe_usuario"] ?? "-")),
          _buildBoolCell(d["coincide_serie_fisica_vs_interna"]),
          DataCell(Text('${d["fotografias_fisicas"] ?? "-"}')),
          _buildBoolCell(d["asignacion_usuario_sistic"]),
          _buildBoolCell(d["registro_serie_sistic"]),
          _buildBoolCell(d["centro_trabajo_sistic"]),
          _buildBoolCell(d["asignacion_usuario_siitic"]),
          _buildBoolCell(d["registro_serie_siitic"]),
          _buildBoolCell(d["centro_trabajo_siitic"]),
          DataCell(Text(d["total"]?.toString() ?? "0")),
        ]);
      }).toList(),
    );
  }

  Widget _buildDropdownArea() {
    return Container(
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
          icon:
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.teal),
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
    );
  }

  Widget _buildFiltroFecha() {
    return Row(
      children: [
        const Text("Filtrar por fecha: "),
        TextButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: Text(
            _fechaSeleccionada != null
                ? "${_fechaSeleccionada!.toLocal()}".split(' ')[0]
                : "Seleccionar fecha",
          ),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2023),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _fechaSeleccionada = picked;
              });
            }
          },
        ),
        if (_fechaSeleccionada != null)
          IconButton(
            tooltip: "Quitar Filtro",
            icon: const Icon(Icons.clear, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                _fechaSeleccionada = null;
              });
            },
          )
      ],
    );
  }

  Widget _buildBotonPDF() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text("Generar PDF"),
          onPressed: _generarPDF,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  DataCell _buildBoolCell(dynamic value) {
    final display = (value == 1) ? "Sí" : "No";
    return DataCell(Text(display));
  }
}
