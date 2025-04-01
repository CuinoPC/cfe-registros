import 'package:cfe_registros/models/lector_danado.dart';
import 'package:cfe_registros/services/api_piezas_lectores.dart';
import 'package:cfe_registros/services/api_lector_danado.dart';
import 'package:cfe_registros/services/api_users.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:cfe_registros/views/piezas_lectores_page.dart';
import 'package:cfe_registros/views/lectores_costo.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lector.dart';
import 'package:url_launcher/url_launcher.dart';

class LectoresDanadosPage extends StatefulWidget {
  final List<Lector> lectoresDanados;

  LectoresDanadosPage({required this.lectoresDanados});

  @override
  _LectoresDanadosPageState createState() => _LectoresDanadosPageState();
}

class _LectoresDanadosPageState extends State<LectoresDanadosPage> {
  List<LectorDanado> _lectoresDanados = [];
  List<LectorDanado> _filteredLectoresDanados = [];
  List<Map<String, dynamic>> _usuarios = [];
  final ApiUserService _apiUserService = ApiUserService();
  final LectorDanadoService _apiDanadosService = LectorDanadoService();
  final PiezasLectoresService _piezasService = PiezasLectoresService();

  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedFilter = "Fecha Reporte";

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    List<LectorDanado> lectores = await _apiDanadosService.getLectoresDanados();
    List<Map<String, dynamic>> usuarios =
        await _apiUserService.getUsers() ?? [];

    setState(() {
      _lectoresDanados = lectores;
      _filteredLectoresDanados = lectores;
      _usuarios = usuarios;
      _isLoading = false;
    });
  }

  void _filterSearchResults(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();

      if (_searchQuery.isEmpty) {
        _filteredLectoresDanados = List.from(_lectoresDanados);
      } else {
        _filteredLectoresDanados = _lectoresDanados.where((lector) {
          return lector.ticket.trim().toLowerCase() == _searchQuery ||
              lector.area.trim().toLowerCase() == _searchQuery ||
              lector.folio.trim().toLowerCase() == _searchQuery ||
              lector.tipoConector.trim().toLowerCase() == _searchQuery ||
              (lector.fechaReporte?.trim().toLowerCase() ?? "") ==
                  _searchQuery ||
              (lector.fechaReparacion?.trim().toLowerCase() ?? "") ==
                  _searchQuery;
        }).toList();
      }
    });
  }

  void _sortBySelectedFilter() {
    setState(() {
      switch (_selectedFilter) {
        case "Ticket":
          _filteredLectoresDanados.sort((a, b) => a.ticket.compareTo(b.ticket));
          break;
        case "Área":
          _filteredLectoresDanados.sort((a, b) => a.area.compareTo(b.area));
          break;
        case "Folio":
          _filteredLectoresDanados.sort((a, b) => a.folio.compareTo(b.folio));
          break;
        case "Tipo Conector":
          _filteredLectoresDanados
              .sort((a, b) => a.tipoConector.compareTo(b.tipoConector));
          break;
        case "Fecha Reporte":
          _filteredLectoresDanados.sort(
              (a, b) => (b.fechaReporte ?? "").compareTo(a.fechaReporte ?? ""));
          break;
        case "Fecha Reparación":
          _filteredLectoresDanados.sort((a, b) =>
              (b.fechaReparacion ?? "").compareTo(a.fechaReparacion ?? ""));
          break;
      }
    });
  }

  Future<void> _selectDate(
      BuildContext context, LectorDanado lector, String field) async {
    DateTime initialDate = DateTime.now();

    if (lector.toMap()[field] != null && lector.toMap()[field]!.isNotEmpty) {
      try {
        initialDate = DateTime.parse(lector.toMap()[field]!);
      } catch (e) {
        print("Error al parsear fecha: $e");
      }
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked);

      setState(() {
        switch (field) {
          case 'fechaReporte':
            lector.fechaReporte = formattedDate;
            break;
          case 'fechaGuia':
            lector.fechaGuia = formattedDate;
            break;
          case 'fechaDiagnostico':
            lector.fechaDiagnostico = formattedDate;
            break;
          case 'fechaAutorizacion':
            lector.fechaAutorizacion = formattedDate;
            break;
          case 'fechaReparacion':
            lector.fechaReparacion = formattedDate;
            break;
        }
      });

      await _apiDanadosService.updateLectorDanado(lector);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('lector_reparado_${lector.folio}', formattedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lectoresDanados.isEmpty
              ? const Center(child: Text("No hay lectores dañados."))
              : Column(
                  children: [
                    // 📌 Encabezado con título, botones, búsqueda y filtros
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Lista de Lectores Dañados",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                CostosLectoresPage()),
                                      );
                                    },
                                    icon: const Icon(Icons.attach_money,
                                        color: Colors.white),
                                    label: const Text("Costos"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PiezasLectoresPage()),
                                      );
                                    },
                                    icon: const Icon(Icons.settings,
                                        color: Colors.white),
                                    label: const Text("Ver piezas lectores"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            onChanged: _filterSearchResults,
                            decoration: InputDecoration(
                              labelText: "Buscar...",
                              prefixIcon:
                                  const Icon(Icons.search, color: Colors.teal),
                              filled: true,
                              fillColor: Colors.teal.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.teal, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Ordenar por:",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.teal, width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedFilter,
                                    icon: const Icon(Icons.filter_list,
                                        color: Colors.teal),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    dropdownColor: Colors.white,
                                    items: [
                                      "Fecha Reporte",
                                      "Fecha Reparación",
                                      "Ticket",
                                      "Área",
                                      "Folio",
                                      "Tipo de Conector"
                                    ]
                                        .map((String value) => DropdownMenuItem(
                                              value: value,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5),
                                                child: Text(value),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedFilter = newValue;
                                          _sortBySelectedFilter();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DataTable2(
                          dataRowHeight: 100,
                          columnSpacing: 24,
                          horizontalMargin: 24,
                          minWidth: 3500,
                          headingRowColor: MaterialStateColor.resolveWith(
                              (states) => Colors.teal.shade100),
                          border: TableBorder.all(color: Colors.grey),
                          columns: const [
                            DataColumn2(label: Text("#"), fixedWidth: 50),
                            DataColumn(label: Text("Ticket")),
                            DataColumn(label: Text("Área")),
                            DataColumn(label: Text("Marca")),
                            DataColumn(label: Text("Modelo")),
                            DataColumn(label: Text("Folio")),
                            DataColumn(label: Text("Tipo de Conector")),
                            DataColumn(label: Text("Fecha Reporte")),
                            DataColumn(label: Text("Fecha Guía")),
                            DataColumn(label: Text("Fecha Diagnóstico")),
                            DataColumn(label: Text("Fecha Autorización")),
                            DataColumn(label: Text("Fecha Reparación")),
                            DataColumn(label: Text("Días de Reparación")),
                            DataColumn(label: Text("Costo")),
                            DataColumn2(
                                label: Text("Pieza Reparada"), fixedWidth: 300),
                            DataColumn2(
                                label: Text("Observaciones"), fixedWidth: 500),
                            DataColumn2(
                                label: Text("Archivo PDF"), fixedWidth: 160),
                          ],
                          rows: List.generate(_filteredLectoresDanados.length,
                              (index) {
                            final lector = _filteredLectoresDanados[index];
                            return DataRow(cells: [
                              DataCell(Text("${index + 1}")),
                              _buildEditableTextCell(lector, "ticket"),
                              DataCell(SelectableText(lector.area)),
                              DataCell(SelectableText(lector.marca)),
                              DataCell(SelectableText(lector.modelo)),
                              DataCell(SelectableText(lector.folio)),
                              DataCell(SelectableText(lector.tipoConector)),
                              _buildEditableDateCell(lector, "fechaReporte"),
                              _buildEditableDateCell(lector, "fechaGuia"),
                              _buildEditableDateCell(
                                  lector, "fechaDiagnostico"),
                              _buildEditableDateCell(
                                  lector, "fechaAutorizacion"),
                              _buildEditableDateCell(lector, "fechaReparacion"),
                              _buildDiasReparacionCell(lector),
                              _buildEditableNumberCell(lector, "costo"),
                              _buildPiezaSelectorCell(lector),
                              _buildEditableTextCell(lector, "observaciones"),
                              _buildArchivoPDFCell(lector),
                            ]);
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  /// 📌 Widget para las celdas editables de Fecha (con DatePicker + Ícono de Calendario)
  DataCell _buildEditableDateCell(LectorDanado lector, String field) {
    String? fecha = lector.toMap()[field];

    String formattedFecha = fecha != null && fecha.isNotEmpty
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha))
        : "Seleccionar";

    return DataCell(
      InkWell(
        onTap: () => _selectDate(context, lector, field),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool showText = MediaQuery.of(context).size.width > 700;

            return Container(
              width: constraints.maxWidth,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.teal),
                  if (showText)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          formattedFecha,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 📌 Widget para las celdas editables de Números (Días y Costo)
  DataCell _buildEditableNumberCell(LectorDanado lector, String field) {
    final controller = TextEditingController(
      text: lector.toMap()[field]?.toString() ?? "",
    );

    return DataCell(
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: (value) {
          if (field == "diasReparacion") {
            lector.diasReparacion = int.tryParse(value) ?? 0;
          } else if (field == "costo") {
            lector.costo = double.tryParse(value) ?? 0.0;
          }
        },
        onFieldSubmitted: (value) {
          _apiDanadosService.updateLectorDanado(lector);
        },
      ),
    );
  }

  DataCell _buildDiasReparacionCell(LectorDanado lector) {
    int dias =
        _calcularDiasReparacion(lector.fechaReporte, lector.fechaReparacion);
    return DataCell(
      Text(
        dias >= 0 ? dias.toString() : "-",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  int _calcularDiasReparacion(String? fechaReporte, String? fechaReparacion) {
    if (fechaReporte == null || fechaReparacion == null) return -1;

    try {
      DateTime inicio = DateTime.parse(fechaReporte);
      DateTime fin = DateTime.parse(fechaReparacion);
      return fin.difference(inicio).inDays;
    } catch (e) {
      print("Error al calcular días: $e");
      return -1;
    }
  }

  DataCell _buildEditableTextCell(LectorDanado lector, String field) {
    return DataCell(
      TextFormField(
        initialValue: lector.toMap()[field]?.toString() ?? "",
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {
            if (field == "piezasReparadas") {
              lector.piezasReparadas = value;
            } else if (field == "observaciones") {
              lector.observaciones = value;
            } else if (field == "ticket") {
              lector.ticket = value;
            }
          });
        },
        onFieldSubmitted: (value) {
          _apiDanadosService.updateLectorDanado(lector);
        },
      ),
    );
  }

  DataCell _buildPiezaSelectorCell(LectorDanado lector) {
    return DataCell(
      TextButton(
        onPressed: () async {
          List<Map<String, dynamic>> piezas =
              await _piezasService.getPiezasLectores();

          showModalBottomSheet(
            context: context,
            builder: (context) {
              return ListView(
                children: piezas.map((pieza) {
                  return ListTile(
                    title: Text(pieza['nombre_pieza']),
                    onTap: () async {
                      setState(() {
                        String nuevaPieza = pieza['nombre_pieza'];
                        double costoPieza =
                            double.tryParse(pieza['costo'].toString()) ?? 0.0;

                        List<String> piezasActuales = lector.piezasReparadas
                            .split(',')
                            .map((p) => p.trim().toLowerCase())
                            .toList();

                        if (!piezasActuales
                            .contains(nuevaPieza.toLowerCase())) {
                          if (lector.piezasReparadas.trim().isEmpty) {
                            lector.piezasReparadas = nuevaPieza;
                          } else {
                            lector.piezasReparadas += ', $nuevaPieza';
                          }

                          lector.costo += costoPieza;
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "La pieza '$nuevaPieza' ya fue seleccionada."),
                            duration: const Duration(seconds: 2),
                          ));
                        }
                      });

                      Navigator.pop(context);
                      await _apiDanadosService.updateLectorDanado(lector);
                    },
                  );
                }).toList(),
              );
            },
          );
        },
        child: Text(
          lector.piezasReparadas.isEmpty
              ? "Seleccionar pieza"
              : lector.piezasReparadas,
          softWrap: true,
          overflow: TextOverflow.visible,
          maxLines: null,
        ),
      ),
    );
  }

  DataCell _buildArchivoPDFCell(LectorDanado lector) {
    return DataCell(
      Row(
        children: [
          if (lector.archivoPdf.isEmpty)
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text("Subir PDF"),
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                  withData: true,
                );

                if (result != null && result.files.single.bytes != null) {
                  final archivo = result.files.single;

                  final success = await _apiDanadosService.subirArchivoPDF(
                    lector.id!,
                    archivo.bytes!,
                    archivo.name,
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Archivo subido correctamente")),
                    );
                    _cargarDatos();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Error al subir archivo")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Selecciona un archivo PDF válido")),
                  );
                }
              },
            )
          else
            TextButton.icon(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              label: const Text("Ver PDF"),
              onPressed: () async {
                final url =
                    Uri.parse("http://localhost:5000${lector.archivoPdf}");
                await launchUrl(url, webOnlyWindowName: '_blank');
              },
            ),
        ],
      ),
    );
  }
}
