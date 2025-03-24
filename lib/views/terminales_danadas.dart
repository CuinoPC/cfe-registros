import 'package:cfe_registros/models/terminal_danada.dart';
import 'package:cfe_registros/services/api_terminales.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:cfe_registros/views/piezas_tps_page.dart';
import 'package:cfe_registros/views/terminales_costo.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 📌 Importamos para formatear fechas
import 'package:shared_preferences/shared_preferences.dart';
import '../models/terminal.dart';
import 'package:url_launcher/url_launcher.dart';

class TerminalesDanadasPage extends StatefulWidget {
  final List<Terminal> terminalesDanadas;

  TerminalesDanadasPage({required this.terminalesDanadas});

  @override
  _TerminalesDanadasPageState createState() => _TerminalesDanadasPageState();
}

class _TerminalesDanadasPageState extends State<TerminalesDanadasPage> {
  List<TerminalDanada> _terminalesDanadas = [];
  List<TerminalDanada> _filteredTerminalesDanadas = [];
  final ApiTerminalService _apiService = ApiTerminalService();
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedFilter = "Fecha Reporte";

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    List<TerminalDanada> terminales = await _apiService.getTerminalesDanadas();
    setState(() {
      _terminalesDanadas = terminales;
      _filteredTerminalesDanadas = terminales;
      _isLoading = false;
    });
  }

  /// 🔍 **Filtrar la lista según el texto de búsqueda (coincidencias exactas)**
  void _filterSearchResults(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();

      if (_searchQuery.isEmpty) {
        // ✅ Si el campo de búsqueda está vacío, restaurar todos los registros
        _filteredTerminalesDanadas = List.from(_terminalesDanadas);
      } else {
        // ✅ Buscar solo coincidencias exactas
        _filteredTerminalesDanadas = _terminalesDanadas.where((terminal) {
          return terminal.marca.trim().toLowerCase() == _searchQuery ||
              terminal.modelo.trim().toLowerCase() == _searchQuery ||
              terminal.serie.trim().toLowerCase() == _searchQuery ||
              terminal.inventario.trim().toLowerCase() == _searchQuery ||
              (terminal.fechaReporte?.trim().toLowerCase() ?? "") ==
                  _searchQuery ||
              (terminal.fechaReparacion?.trim().toLowerCase() ?? "") ==
                  _searchQuery;
        }).toList();
      }
    });
  }

  /// 🔽 **Ordenar la lista según el filtro seleccionado**
  void _sortBySelectedFilter() {
    setState(() {
      switch (_selectedFilter) {
        case "Marca":
          _filteredTerminalesDanadas.sort((a, b) => a.marca.compareTo(b.marca));
          break;
        case "Modelo":
          _filteredTerminalesDanadas
              .sort((a, b) => a.modelo.compareTo(b.modelo));
          break;
        case "Serie":
          _filteredTerminalesDanadas.sort((a, b) => a.serie.compareTo(b.serie));
          break;
        case "Inventario":
          _filteredTerminalesDanadas
              .sort((a, b) => a.inventario.compareTo(b.inventario));
          break;
        case "Fecha Reporte":
          _filteredTerminalesDanadas.sort(
              (a, b) => (b.fechaReporte ?? "").compareTo(a.fechaReporte ?? ""));
          break;
        case "Fecha Reparación":
          _filteredTerminalesDanadas.sort((a, b) =>
              (b.fechaReparacion ?? "").compareTo(a.fechaReparacion ?? ""));
          break;
      }
    });
  }

  /// 📌 Método para abrir el DatePicker y actualizar la fecha en `dd/MM/yyyy`
  Future<void> _selectDate(
      BuildContext context, TerminalDanada terminal, String field) async {
    DateTime initialDate = DateTime.now();

    if (terminal.toMap()[field] != null &&
        terminal.toMap()[field]!.isNotEmpty) {
      try {
        initialDate = DateTime.parse(terminal.toMap()[field]!);
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
      String formattedDate = DateFormat('yyyy-MM-dd')
          .format(picked); // ✅ Guardamos en la BD como YYYY-MM-DD

      setState(() {
        switch (field) {
          case 'fechaReporte':
            terminal.fechaReporte = formattedDate;
            break;
          case 'fechaGuia':
            terminal.fechaGuia = formattedDate;
            break;
          case 'fechaDiagnostico':
            terminal.fechaDiagnostico = formattedDate;
            break;
          case 'fechaAutorizacion':
            terminal.fechaAutorizacion = formattedDate;
            break;
          case 'fechaReparacion':
            terminal.fechaReparacion = formattedDate;
            break;
        }
      });

      print("Fecha seleccionada ($field): $formattedDate");

      // ✅ Enviar actualización al backend
      await _apiService.updateTerminalDanada(terminal);

      // ✅ Guardar la reparación en SharedPreferences para que TerminalList lo desmarque
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'terminal_reparada_${terminal.serie}', formattedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _terminalesDanadas.isEmpty
              ? const Center(child: Text("No hay terminales dañadas."))
              : Column(
                  children: [
                    // 📌 **Encabezado con título, costos, búsqueda y filtros**
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Lista de Terminales Dañadas",
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
                                                CostosTerminalesPage()),
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
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            PiezasTPSPage()), // Nueva página
                                  );
                                },
                                icon: const Icon(Icons.settings),
                                label: const Text("Ver piezas TPS"),
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

                          // 🔽 **Filtro de orden**
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
                                        fontSize: 14),
                                    dropdownColor: Colors.white,
                                    items: [
                                      "Fecha Reporte",
                                      "Fecha Reparación",
                                      "Marca",
                                      "Modelo",
                                      "Serie",
                                      "Inventario"
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
                          dataRowHeight: 80,
                          columnSpacing: 24,
                          horizontalMargin: 24,
                          minWidth: 2800,
                          headingRowColor: MaterialStateColor.resolveWith(
                              (states) => Colors.teal.shade100),
                          border: TableBorder.all(color: Colors.grey),
                          columns: const [
                            DataColumn(
                                label: Text(
                                    "#")), // 📌 Nueva columna para numeración
                            DataColumn(label: Text("Marca")),
                            DataColumn(label: Text("Modelo")),
                            DataColumn(label: Text("Serie")),
                            DataColumn(label: Text("Inventario")),
                            DataColumn(label: Text("Fecha Reporte")),
                            DataColumn(label: Text("Fecha Guía")),
                            DataColumn(label: Text("Fecha Diagnóstico")),
                            DataColumn(label: Text("Fecha Autorización")),
                            DataColumn(label: Text("Fecha Reparación")),
                            DataColumn(label: Text("Días de Reparación")),
                            DataColumn(label: Text("Costo")),
                            DataColumn(label: Text("Pieza Reparada")),
                            DataColumn(label: Text("observaciones")),
                            DataColumn(label: Text("Archivo PDF")),
                          ],
                          rows: List.generate(_filteredTerminalesDanadas.length,
                              (index) {
                            final terminal = _filteredTerminalesDanadas[index];
                            return DataRow(cells: [
                              DataCell(Text(
                                  "${index + 1}")), // 📌 Numeración de filas
                              DataCell(Text(terminal.marca)),
                              DataCell(Text(terminal.modelo)),
                              DataCell(Text(terminal.serie)),
                              DataCell(Text(terminal.inventario)),
                              _buildEditableDateCell(terminal, "fechaReporte"),
                              _buildEditableDateCell(terminal, "fechaGuia"),
                              _buildEditableDateCell(
                                  terminal, "fechaDiagnostico"),
                              _buildEditableDateCell(
                                  terminal, "fechaAutorizacion"),
                              _buildEditableDateCell(
                                  terminal, "fechaReparacion"),
                              _buildDiasReparacionCell(terminal),
                              _buildEditableNumberCell(terminal, "costo"),
                              _buildPiezaSelectorCell(terminal),
                              _buildEditableTextCell(terminal, "observaciones"),
                              _buildArchivoPDFCell(terminal),
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
  DataCell _buildEditableDateCell(TerminalDanada terminal, String field) {
    String? fecha = terminal.toMap()[field];

    // 📌 Convertimos de `YYYY-MM-DDTHH:MM:SSZ` a `DD/MM/YYYY`
    String formattedFecha = fecha != null && fecha.isNotEmpty
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha))
        : "Seleccionar";

    return DataCell(
      InkWell(
        onTap: () => _selectDate(context, terminal, field),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool showText = MediaQuery.of(context).size.width >
                700; // 📌 Si la pantalla es grande, mostrar la fecha

            return Container(
              width: constraints
                  .maxWidth, // 📌 Asegura que el contenido no se desborde
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.teal),
                  if (showText) // 📌 Si la pantalla es grande, mostrar la fecha
                    Expanded(
                      // 📌 Asegura que el texto se ajuste sin desbordar
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          formattedFecha,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow
                              .ellipsis, // 📌 Evita que la fecha se desborde
                          softWrap:
                              false, // 📌 Evita que la fecha haga salto de línea
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
  DataCell _buildEditableNumberCell(TerminalDanada terminal, String field) {
    final controller = TextEditingController(
      text: terminal.toMap()[field]?.toString() ?? "",
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
            terminal.diasReparacion = int.tryParse(value) ?? 0;
          } else if (field == "costo") {
            terminal.costo = double.tryParse(value) ?? 0.0;
          }
        },
        onFieldSubmitted: (value) {
          _apiService.updateTerminalDanada(terminal);
        },
      ),
    );
  }

  DataCell _buildDiasReparacionCell(TerminalDanada terminal) {
    int diasReparacion = _calcularDiasReparacion(
        terminal.fechaReporte, terminal.fechaReparacion);

    return DataCell(
      Text(
        diasReparacion >= 0 ? diasReparacion.toString() : "-",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 📌 Método para calcular los días de reparación
  int _calcularDiasReparacion(String? fechaReporte, String? fechaReparacion) {
    if (fechaReporte == null || fechaReparacion == null) return -1;

    try {
      DateTime reporte = DateTime.parse(fechaReporte);
      DateTime reparacion = DateTime.parse(fechaReparacion);
      return reparacion.difference(reporte).inDays;
    } catch (e) {
      print("Error al calcular días de reparación: $e");
      return -1;
    }
  }

  DataCell _buildEditableTextCell(TerminalDanada terminal, String field) {
    return DataCell(
      TextFormField(
        initialValue: terminal.toMap()[field]?.toString() ?? "",
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {
            if (field == "piezasReparadas") {
              terminal.piezasReparadas = value;
            } else if (field == "observaciones") {
              terminal.observaciones = value;
            }
          });
        },
        onFieldSubmitted: (value) {
          _apiService.updateTerminalDanada(terminal);
        },
      ),
    );
  }

  DataCell _buildPiezaSelectorCell(TerminalDanada terminal) {
    return DataCell(
      TextButton(
        onPressed: () async {
          List<Map<String, dynamic>> piezas = await _apiService.getPiezasTPS();

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

                          // 🔍 Verificar si la pieza ya está en la lista
                          List<String> piezasActuales = terminal.piezasReparadas
                              .split(',')
                              .map((p) => p.trim().toLowerCase())
                              .toList();

                          if (!piezasActuales
                              .contains(nuevaPieza.toLowerCase())) {
                            // ✅ Agregar la nueva pieza al string
                            if (terminal.piezasReparadas.trim().isEmpty) {
                              terminal.piezasReparadas = nuevaPieza;
                            } else {
                              terminal.piezasReparadas += ', $nuevaPieza';
                            }

                            // ✅ Sumar su costo
                            terminal.costo += costoPieza;
                          } else {
                            // 🟡 Opcional: mostrar alerta si ya fue agregada
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  "La pieza '$nuevaPieza' ya fue seleccionada."),
                              duration: const Duration(seconds: 2),
                            ));
                          }
                        });

                        Navigator.pop(context);
                        await _apiService.updateTerminalDanada(terminal);
                      });
                }).toList(),
              );
            },
          );
        },
        child: Text(
          terminal.piezasReparadas.isEmpty
              ? "Seleccionar pieza"
              : terminal.piezasReparadas,
          softWrap: true,
          overflow: TextOverflow.visible,
          maxLines: null,
        ),
      ),
    );
  }

  DataCell _buildArchivoPDFCell(TerminalDanada terminal) {
    return DataCell(
      Row(
        children: [
          if (terminal.archivoPdf.isEmpty)
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text("Subir PDF"),
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );

                if (result != null && result.files.single.bytes != null) {
                  final archivo = result.files.single;

                  final success = await _apiService.subirArchivoPDF(
                    terminal.id!,
                    archivo.bytes!,
                    archivo.name,
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Archivo subido correctamente")),
                    );
                    _cargarDatos(); // ✅ Recargar para reflejar el cambio
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
                    Uri.parse("http://localhost:5000${terminal.archivoPdf}");
                await launchUrl(url,
                    webOnlyWindowName: '_blank'); // 🧠 Abre en nueva pestaña
              },
            ),
        ],
      ),
    );
  }
}
