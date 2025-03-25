import 'package:cfe_registros/models/historial.dart';
import 'package:cfe_registros/services/api_terminal_historial.dart';
import 'package:cfe_registros/services/api_users.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'custom_appbar.dart';

class HistorialPage extends StatefulWidget {
  @override
  _HistorialPageState createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final HistorialService _ApiTerminalService = HistorialService();
  final ApiUserService _ApiUserService = ApiUserService();
  List<HistorialRegistro> _historial = [];
  List<HistorialRegistro> _filteredHistorial = [];
  List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedFilter = "Fecha"; // ✅ Filtro por defecto

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    List<HistorialRegistro>? historial =
        await _ApiTerminalService.getHistorial();
    List<Map<String, dynamic>>? usuariosData = await _ApiUserService.getUsers();

    if (historial != null && usuariosData != null) {
      setState(() {
        _historial = historial;
        _filteredHistorial = historial;
        _usuarios = usuariosData;
        _isLoading = false;
      });
      _sortBySelectedFilter(); // ✅ Aplicar el orden correcto al cargar
    } else {
      setState(() {
        _isLoading = false;
      });
      print("No hay registros en el historial.");
    }
  }

  /// 🔍 **Filtrar la lista según el texto de búsqueda (coincidencias exactas)**
  void _filterSearchResults(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();

      if (_searchQuery.isEmpty) {
        // ✅ Si la búsqueda está vacía, restauramos todos los registros
        _filteredHistorial = List.from(_historial);
      } else {
        // ✅ Filtrar solo coincidencias exactas
        _filteredHistorial = _historial.where((registro) {
          return registro.rpeResponsable.trim().toLowerCase() == _searchQuery ||
              _getAreaUsuario(registro.usuarioId).trim().toLowerCase() ==
                  _searchQuery ||
              registro.serie.trim().toLowerCase() == _searchQuery ||
              registro.inventario.trim().toLowerCase() == _searchQuery ||
              registro.nombreResponsable.trim().toLowerCase() == _searchQuery ||
              _getNombreUsuario(registro.usuarioId).trim().toLowerCase() ==
                  _searchQuery;
        }).toList();
      }
    });
  }

  // 🔹 Ordenar la lista según el filtro seleccionado
  void _sortBySelectedFilter() {
    setState(() {
      switch (_selectedFilter) {
        case "Marca":
          _filteredHistorial.sort((a, b) => a.marca.compareTo(b.marca));
          break;
        case "Modelo":
          _filteredHistorial.sort((a, b) => a.modelo.compareTo(b.modelo));
          break;
        case "Serie":
          _filteredHistorial.sort((a, b) => a.serie.compareTo(b.serie));
          break;
        case "Inventario":
          _filteredHistorial
              .sort((a, b) => a.inventario.compareTo(b.inventario));
          break;
        case "Nombre Responsable":
          _filteredHistorial.sort(
              (a, b) => a.nombreResponsable.compareTo(b.nombreResponsable));
          break;
        case "Usuario (RP)":
          _filteredHistorial.sort((a, b) => _getNombreUsuario(a.usuarioId)
              .compareTo(_getNombreUsuario(b.usuarioId)));
          break;
        case "Fecha":
        default:
          _filteredHistorial.sort((a, b) => a.fecha
              .compareTo(b.fecha)); // ✅ Ordenar por fecha (más antiguo primero)
          break;
      }
    });
  }

  // 🔹 Obtener el nombre del usuario
  String _getNombreUsuario(int usuarioId) {
    var usuario = _usuarios.firstWhere((user) => user['id'] == usuarioId,
        orElse: () => {'nombre_completo': "No disponible"});
    return usuario['nombre_completo'].toString();
  }

  // 🔹 Obtener el RP del usuario
  String _getRpUsuario(int usuarioId) {
    var usuario = _usuarios.firstWhere((user) => user['id'] == usuarioId,
        orElse: () => {'rp': "No disponible"});
    return usuario['rp'].toString();
  }

  // 🔹 Obtener el área del usuario
  String _getAreaUsuario(int usuarioId) {
    var usuario = _usuarios.firstWhere((user) => user['id'] == usuarioId,
        orElse: () => {'nom_area': "No disponible"});
    return usuario['nom_area'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ✅ Cabecera con Título, Buscador y Filtro
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
                      // 🔍 Barra de búsqueda
                      TextField(
                        onChanged: _filterSearchResults,
                        decoration: InputDecoration(
                          labelText: "Buscar...",
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.teal), // Ícono de búsqueda
                          filled: true,
                          fillColor: Colors.teal.shade50, // Fondo sutil
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12), // Bordes redondeados
                            borderSide: BorderSide.none, // Sin bordes duros
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Colors.teal,
                                width: 2), // Borde resaltado
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 🔽 Filtro de Orden
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
                              color: Colors.teal.shade50, // Fondo suave
                              borderRadius: BorderRadius.circular(
                                  12), // Bordes redondeados
                              border: Border.all(
                                  color: Colors.teal,
                                  width: 1.5), // Borde delgado
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedFilter,
                                icon: const Icon(Icons.filter_list,
                                    color: Colors.teal), // Ícono de filtro
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
                                  "Serie",
                                  "Inventario",
                                  "Nombre Responsable",
                                  "Usuario (RP)"
                                ]
                                    .map((String value) => DropdownMenuItem(
                                          value: value,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
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
                // ✅ Tabla con los datos del historial
                Expanded(
                  child: DataTable2(
                    columnSpacing: 24,
                    horizontalMargin: 24,
                    minWidth: 2000,
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.teal.shade100),
                    border: TableBorder.all(color: Colors.grey),
                    columns: const [
                      DataColumn(label: Text("#")),
                      DataColumn(label: Text("Acción")),
                      DataColumn(label: Text("Marca")),
                      DataColumn(label: Text("Modelo")),
                      DataColumn(label: Text("Serie")),
                      DataColumn(label: Text("Inventario")),
                      DataColumn(label: Text("Responsable (RPE)")),
                      DataColumn(label: Text("Nombre Responsable")),
                      DataColumn(label: Text("Usuario (RP)")),
                      DataColumn(label: Text("Área")),
                      DataColumn(label: Text("Fecha")),
                    ],
                    rows: _filteredHistorial.asMap().entries.map((entry) {
                      int index = entry.key + 1;
                      HistorialRegistro registro = entry.value;
                      String fechaFormateada = DateFormat("dd/MM/yyyy HH:mm:ss")
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
                        DataCell(Text(registro.serie)),
                        DataCell(Text(registro.inventario)),
                        DataCell(Text(registro.rpeResponsable.toString())),
                        DataCell(Text(registro.nombreResponsable)),
                        DataCell(Text(
                            "${_getNombreUsuario(registro.usuarioId)} (RP: ${_getRpUsuario(registro.usuarioId)})")),
                        DataCell(Text(_getAreaUsuario(registro.usuarioId))),
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
