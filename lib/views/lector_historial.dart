import 'package:flutter/material.dart';
import 'package:cfe_registros/models/lector_historial.dart';
import 'package:cfe_registros/services/api_lector_historial.dart';
import 'package:cfe_registros/services/api_users.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'custom_appbar.dart';

class HistorialLectorPage extends StatefulWidget {
  @override
  _HistorialLectorPageState createState() => _HistorialLectorPageState();
}

class _HistorialLectorPageState extends State<HistorialLectorPage> {
  final HistorialLectorService _apiLectorHistorial = HistorialLectorService();
  final ApiUserService _apiUserService = ApiUserService();

  List<HistorialLector> _historial = [];
  List<HistorialLector> _filteredHistorial = [];
  List<Map<String, dynamic>> _usuarios = [];

  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedFilter = "Fecha";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    var historial = await _apiLectorHistorial.getHistorialLectores();
    var usuarios = await _apiUserService.getUsers();

    if (historial != null && usuarios != null) {
      setState(() {
        _historial = historial;
        _filteredHistorial = historial;
        _usuarios = usuarios;
        _isLoading = false;
      });
      _sortBySelectedFilter();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _filterSearchResults(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();

      if (_searchQuery.isEmpty) {
        _filteredHistorial = List.from(_historial);
      } else {
        _filteredHistorial = _historial.where((registro) {
          return registro.marca.toLowerCase().contains(_searchQuery) ||
              registro.modelo.toLowerCase().contains(_searchQuery) ||
              registro.folio.toLowerCase().contains(_searchQuery) ||
              registro.tipoConector.toLowerCase().contains(_searchQuery) ||
              _getNombreUsuario(registro.usuarioId).toLowerCase() ==
                  _searchQuery;
        }).toList();
      }
    });
  }

  void _sortBySelectedFilter() {
    setState(() {
      switch (_selectedFilter) {
        case "Marca":
          _filteredHistorial.sort((a, b) => a.marca.compareTo(b.marca));
          break;
        case "Modelo":
          _filteredHistorial.sort((a, b) => a.modelo.compareTo(b.modelo));
          break;
        case "Folio":
          _filteredHistorial.sort((a, b) => a.folio.compareTo(b.folio));
          break;
        case "Tipo de Conector":
          _filteredHistorial
              .sort((a, b) => a.tipoConector.compareTo(b.tipoConector));
          break;
        case "Usuario (RP)":
          _filteredHistorial.sort((a, b) => _getNombreUsuario(a.usuarioId)
              .compareTo(_getNombreUsuario(b.usuarioId)));
          break;
        case "Fecha":
        default:
          _filteredHistorial.sort((a, b) => a.fecha.compareTo(b.fecha));
          break;
      }
    });
  }

  String _getNombreUsuario(int id) {
    final usuario = _usuarios.firstWhere((u) => u['id'] == id,
        orElse: () => {'nombre_completo': 'N/D'});
    return usuario['nombre_completo'] ?? 'N/D';
  }

  String _getRPUsuario(int id) {
    final usuario =
        _usuarios.firstWhere((u) => u['id'] == id, orElse: () => {'rp': 'N/D'});
    return usuario['rp'] ?? 'N/D';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
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
                            borderSide:
                                const BorderSide(color: Colors.teal, width: 2),
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
                              border:
                                  Border.all(color: Colors.teal, width: 1.5),
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
                                  "Fecha",
                                  "Marca",
                                  "Modelo",
                                  "Folio",
                                  "Tipo de Conector",
                                  "Usuario (RP)"
                                ].map((String value) {
                                  return DropdownMenuItem(
                                    value: value,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: Text(value),
                                    ),
                                  );
                                }).toList(),
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
                Expanded(
                  child: DataTable2(
                    columnSpacing: 24,
                    horizontalMargin: 24,
                    minWidth: 1600,
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.teal.shade100),
                    border: TableBorder.all(color: Colors.grey),
                    columns: const [
                      DataColumn2(label: Text("#"), fixedWidth: 50),
                      DataColumn(label: Text("Acción")),
                      DataColumn(label: Text("Marca")),
                      DataColumn(label: Text("Modelo")),
                      DataColumn(label: Text("Folio")),
                      DataColumn(label: Text("Tipo de Conector")),
                      DataColumn(label: Text("Responsable (RPE)")), // 🆕
                      DataColumn(label: Text("Nombre Responsable")), // 🆕
                      DataColumn(label: Text("Usuario (RP)")),
                      DataColumn(label: Text("Área")),
                      DataColumn(label: Text("Fecha")),
                    ],
                    rows: _filteredHistorial.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final registro = entry.value;
                      final fechaFormateada = DateFormat("dd/MM/yyyy HH:mm:ss")
                          .format(registro.fecha);

                      return DataRow(cells: [
                        DataCell(Text(index.toString())),
                        DataCell(Text(registro.accion,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: registro.accion == "Creación"
                                    ? Colors.green
                                    : Colors.blue))),
                        DataCell(Text(registro.marca)),
                        DataCell(Text(registro.modelo)),
                        DataCell(Text(registro.folio)),
                        DataCell(Text(registro.tipoConector)),
                        DataCell(Text(registro.rpeResponsable)), // 🆕
                        DataCell(Text(registro.nombreResponsable)), // 🆕
                        DataCell(Text(
                            "${_getNombreUsuario(registro.usuarioId)} (RP: ${_getRPUsuario(registro.usuarioId)})")),
                        DataCell(Text(registro.area)),
                        DataCell(Text(fechaFormateada)),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
