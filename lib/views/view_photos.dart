import 'package:cfe_registros/services/api_terminales.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewPhotosPage extends StatefulWidget {
  final int terminalId;
  final Map<String, List<String>> fotosPorFecha;

  ViewPhotosPage({required this.terminalId, required this.fotosPorFecha});

  @override
  _ViewPhotosPageState createState() => _ViewPhotosPageState();
}

class _ViewPhotosPageState extends State<ViewPhotosPage> {
  final ApiTerminalService _apiService = ApiTerminalService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _historialSupervision = [];
  Map<String, List<Map<String, dynamic>>> _supervisionPorFecha = {};

  @override
  void initState() {
    super.initState();
    _fetchSupervisionHistorial();
  }

  Future<void> _fetchSupervisionHistorial() async {
    final historial =
        await _apiService.getHistorialSupervision(widget.terminalId);

    // Agrupar supervisiones por fecha (yyyy-MM-dd)
    Map<String, List<Map<String, dynamic>>> agrupado = {};
    for (var entry in historial) {
      String fecha = entry["fecha"]?.split("T")?.first ?? "sin_fecha";
      if (!agrupado.containsKey(fecha)) {
        agrupado[fecha] = [];
      }
      agrupado[fecha]!.add(entry);
    }

    setState(() {
      _historialSupervision = historial;
      _supervisionPorFecha = agrupado;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.fotosPorFecha.isEmpty
                      ? const Center(child: Text("No hay fotos disponibles"))
                      : Column(
                          children: widget.fotosPorFecha.entries.map((entry) {
                            String fechaISO = entry.key;
                            DateTime fecha = DateTime.parse(fechaISO);
                            String fechaFormateada =
                                DateFormat("dd/MM/yyyy").format(fecha);

                            List<String> fotos = entry.value;

                            // Supervisiones de esta misma fecha
                            List<Map<String, dynamic>> supervisiones =
                                _supervisionPorFecha[fechaISO] ?? [];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "📅 $fechaFormateada",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 5),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount: fotos.length,
                                  itemBuilder: (context, i) {
                                    return Image.network(
                                      "http://localhost:5000${fotos[i]}",
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.broken_image,
                                            size: 50, color: Colors.red);
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),

                                // Si hay supervisión para esta fecha, mostrarla aquí
                                ...supervisiones.map((entry) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "📝 Supervisión registrada",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 5),
                                      Table(
                                        border: TableBorder.all(),
                                        columnWidths: const {
                                          0: FlexColumnWidth(2),
                                          1: FlexColumnWidth(1),
                                        },
                                        children: [
                                          _buildTableRow(
                                              "Serie", entry["serie"]),
                                          _buildTableRow("Inventario",
                                              entry["inventario"]),
                                          _buildTableRow("Año de antigüedad",
                                              entry["anio_antiguedad"]),
                                          _buildTableRow("RPE Usuario",
                                              entry["rpe_usuario"]),
                                          _buildTableRow(
                                              "Fotografías físicas (6)",
                                              entry["fotografias_fisicas"]),
                                          _buildTableRowBoolean(
                                              "Etiqueta Activo Fijo",
                                              entry["etiqueta_activo_fijo"]),
                                          _buildTableRowBoolean(
                                              "Chip con serie Tableta",
                                              entry["chip_con_serie_tableta"]),
                                          _buildTableRowBoolean(
                                              "Foto de carcasa",
                                              entry["foto_carcasa"]),
                                          _buildTableRowBoolean(
                                              "APN", entry["apn"]),
                                          _buildTableRowBoolean("Correo GMAIL",
                                              entry["correo_gmail"]),
                                          _buildTableRowBoolean(
                                              "Seguridad de desbloqueo",
                                              entry["seguridad_desbloqueo"]),
                                          _buildTableRowBoolean(
                                              "Coincide Serie, SIM, IMEI",
                                              entry["coincide_serie_sim_imei"]),
                                          _buildTableRowBoolean(
                                              "Responsiva APN",
                                              entry["responsiva_apn"]),
                                          _buildTableRowBoolean(
                                              "Centro de trabajo correcto",
                                              entry["centro_trabajo_correcto"]),
                                          _buildTableRowBoolean("Responsiva",
                                              entry["responsiva"]),
                                          _buildTableRowBoolean(
                                              "Serie correcta en SISTIC",
                                              entry["serie_correcta_sistic"]),
                                          _buildTableRowBoolean(
                                              "Serie correcta en SIITIC",
                                              entry["serie_correcta_siitic"]),
                                          _buildTableRowBoolean(
                                              "Asignación de RPE vs MySAP",
                                              entry["asignacion_rpe_mysap"]),
                                          _buildTableRow(
                                              "TOTAL", entry["total"]),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  );
                                }),
                              ],
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }

  TableRow _buildTableRow(String label, dynamic value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value?.toString() ?? "N/A"),
        ),
      ],
    );
  }

  TableRow _buildTableRowBoolean(String label, dynamic value) {
    String displayValue = (value == 1) ? "Sí" : "No";
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(displayValue),
        ),
      ],
    );
  }
}
