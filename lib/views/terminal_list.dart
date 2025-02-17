import 'package:cfe_registros/services/api_terminales.dart';
import 'package:cfe_registros/services/api_users.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:cfe_registros/views/historial_page.dart';
import 'package:cfe_registros/views/upload_photos.dart';
import 'package:cfe_registros/views/view_photos.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/terminal.dart';
import 'add_terminal.dart';
import 'update_terminal.dart';

class TerminalList extends StatefulWidget {
  @override
  _TerminalListState createState() => _TerminalListState();
}

class _TerminalListState extends State<TerminalList> {
  final ApiTerminalService _ApiTerminalService = ApiTerminalService();
  final ApiUserService _ApiUserService = ApiUserService();
  List<Terminal> _terminales = [];
  List<Terminal> _filteredTerminales = [];
  List<Map<String, dynamic>> _usuarios = []; // Lista de usuarios
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedFilter = "Fecha"; // ✅ Filtro por defecto

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    List<Terminal>? terminales = await _ApiTerminalService.getTerminales();
    List<Map<String, dynamic>>? usuariosData = await _ApiUserService.getUsers();

    if (terminales != null && usuariosData != null) {
      setState(() {
        _terminales = terminales;
        _filteredTerminales = terminales;
        _usuarios = usuariosData;
        _isLoading = false;
      });
    }
  }

  // 🔹 Filtrar la lista según el texto de búsqueda
  void _filterSearchResults(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredTerminales = _terminales.where((terminal) {
        return terminal.marca.toLowerCase().contains(_searchQuery) ||
            terminal.modelo.toLowerCase().contains(_searchQuery) ||
            terminal.serie.toLowerCase().contains(_searchQuery) ||
            terminal.nombreResponsable.toLowerCase().contains(_searchQuery) ||
            _getNombreUsuario(terminal.usuarioId)
                .toLowerCase()
                .contains(_searchQuery);
      }).toList();
    });
  }

  // 🔹 Ordenar la lista según el filtro seleccionado
  void _sortBySelectedFilter() {
    setState(() {
      switch (_selectedFilter) {
        case "Marca":
          _filteredTerminales.sort((a, b) => a.marca.compareTo(b.marca));
          break;
        case "Modelo":
          _filteredTerminales.sort((a, b) => a.modelo.compareTo(b.modelo));
          break;
        case "Serie":
          _filteredTerminales.sort((a, b) => a.serie.compareTo(b.serie));
          break;
        case "Nombre Responsable":
          _filteredTerminales.sort(
              (a, b) => a.nombreResponsable.compareTo(b.nombreResponsable));
          break;
        case "Usuario (RP)":
          _filteredTerminales.sort((a, b) => _getNombreUsuario(a.usuarioId)
              .compareTo(_getNombreUsuario(b.usuarioId)));
          break;
        case "Fecha":
        default:
          _filteredTerminales.sort((a, b) =>
              b.id.compareTo(a.id)); // ✅ Ordenar por ID (más reciente primero)
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

  Future<void> _deleteTerminal(int id) async {
    bool success = await _ApiTerminalService.deleteTerminal(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terminal eliminada correctamente")),
      );
      _fetchData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar la terminal")),
      );
    }
  }

  void _navigateToUploadPhotos(int terminalId) async {
    bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadPhotosPage(terminalId: terminalId),
      ),
    );

    if (updated == true) {
      setState(() {
        _isLoading = true;
      });

      await _fetchData(); // ✅ Recargar la lista con las nuevas fotos

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToViewPhotos(Map<String, List<String>> fotosPorFecha) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewPhotosPage(fotosPorFecha: fotosPorFecha),
      ),
    );
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
                      // ✅ Encabezado con título y botón de historial
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Lista de Terminales",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HistorialPage()),
                              );
                            },
                            icon: const Icon(Icons.history),
                            label: const Text("Histórico"),
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
                      const SizedBox(height: 10),

                      // 🔍 Barra de búsqueda con diseño mejorado
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

                      // 🔽 Filtro de Orden con diseño mejorado
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
                Expanded(
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 900,
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.teal.shade100),
                    border: TableBorder.all(color: Colors.grey),
                    columns: const [
                      DataColumn(label: Text("#")),
                      DataColumn(label: Text("Marca")),
                      DataColumn(label: Text("Modelo")),
                      DataColumn(label: Text("Serie")),
                      DataColumn(label: Text("Inventario")),
                      DataColumn(label: Text("Responsable (RPE)")),
                      DataColumn(label: Text("Nombre Responsable")),
                      DataColumn(label: Text("Usuario (RP)")),
                      DataColumn(label: Text("Área del Usuario")),
                      DataColumn(label: Text("Fotos")),
                      DataColumn(label: Text("Fotos Nuevas")),
                      DataColumn(label: Text("Opciones")),
                    ],
                    rows: _terminales.asMap().entries.map((entry) {
                      int index = entry.key + 1;
                      Terminal terminal = entry.value;
                      return DataRow(cells: [
                        DataCell(Text(index.toString())),
                        DataCell(Text(terminal.marca)),
                        DataCell(Text(terminal.modelo)),
                        DataCell(Text(terminal.serie)),
                        DataCell(Text(terminal.inventario)),
                        DataCell(Text(terminal.rpeResponsable.toString())),
                        DataCell(Text(terminal.nombreResponsable)),
                        DataCell(
                          Text(
                            "${_getNombreUsuario(terminal.usuarioId)} (RP: ${_getRpUsuario(terminal.usuarioId)})",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ), // ✅ Nombre del Usuario + RP
                        DataCell(Text(_getAreaUsuario(
                            terminal.usuarioId))), // ✅ Área del Usuario
                        DataCell(
                          TextButton(
                            onPressed: () {
                              if (terminal.fotos.isNotEmpty) {
                                _navigateToViewPhotos(terminal.fotos);
                              } else {
                                _navigateToUploadPhotos(terminal.id);
                              }
                            },
                            child: Text(
                              terminal.fotos.isNotEmpty
                                  ? "Ver Fotos"
                                  : "Cargar Fotos",
                              style: TextStyle(
                                color: terminal.fotos.isNotEmpty
                                    ? Colors.green
                                    : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          terminal.fotos.isEmpty
                              ? const Text(
                                  "-") // ✅ Si no hay fotos, mostrar "-"
                              : TextButton(
                                  onPressed: () {
                                    _navigateToUploadPhotos(terminal.id);
                                  },
                                  child: const Text(
                                    "Cargar Fotos Nuevas",
                                    style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          UpdateTerminal(terminal: terminal),
                                    ),
                                  ).then((updated) {
                                    if (updated == true) _fetchData();
                                  });
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteTerminal(terminal.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTerminal()),
          ).then((_) => _fetchData());
        },
        backgroundColor: Colors.teal.shade100,
        child: Icon(Icons.add, color: Colors.teal.shade900),
        tooltip: "Añadir Terminal",
      ),
    );
  }
}
