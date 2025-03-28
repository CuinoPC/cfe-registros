import 'package:cfe_registros/services/api_lectores_supervision.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewLectorPhotosPage extends StatefulWidget {
  final int lectorId;
  final Map<String, List<String>> fotosPorFecha;

  ViewLectorPhotosPage({required this.lectorId, required this.fotosPorFecha});

  @override
  _ViewLectorPhotosPageState createState() => _ViewLectorPhotosPageState();
}

class _ViewLectorPhotosPageState extends State<ViewLectorPhotosPage> {
  final SupervisionLectorService _supervisionService =
      SupervisionLectorService();
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
        await _supervisionService.getHistorialSupervision(widget.lectorId);

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
                                    return GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: InteractiveViewer(
                                              child: Image.network(
                                                "http://localhost:5000${fotos[i]}",
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Icon(
                                                      Icons.broken_image,
                                                      size: 50,
                                                      color: Colors.red);
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          "http://localhost:5000${fotos[i]}",
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                                Icons.broken_image,
                                                size: 50,
                                                color: Colors.red);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                ...supervisiones.map((entry) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "📝 Supervisión registrada",
                                        style: TextStyle(
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
                                              "Marca", entry["marca"]),
                                          _buildTableRow(
                                              "Modelo", entry["modelo"]),
                                          _buildTableRow(
                                              "Folio", entry["folio"]),
                                          _buildTableRow("Tipo Conector",
                                              entry["tipo_conector"]),
                                          _buildTableRowBoolean(
                                              "Fotografía conector",
                                              entry["fotografia_conector"]),
                                          _buildTableRowBoolean(
                                              "Fotografía cincho/folio",
                                              entry["fotografia_cincho_folio"]),
                                          _buildTableRowBoolean(
                                              "Fotografía cabezal",
                                              entry["fotografia_cabezal"]),
                                          _buildTableRowBoolean(
                                              "Registro Ctrl Lectores",
                                              entry["registro_ctrl_lectores"]),
                                          _buildTableRowBoolean(
                                              "Ubicación Ctrl Lectores",
                                              entry["ubicacion_ctrl_lectores"]),
                                          _buildTableRowBoolean(
                                              "Registro SIITIC",
                                              entry["registro_siitic"]),
                                          _buildTableRowBoolean(
                                              "Ubicación SIITIC",
                                              entry["ubicacion_siitic"]),
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
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(displayValue),
        ),
      ],
    );
  }
}
