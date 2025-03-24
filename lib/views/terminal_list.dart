import 'package:cfe_registros/models/terminal_danada.dart';
import 'package:cfe_registros/services/api_terminales.dart';
import 'package:cfe_registros/services/api_users.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:cfe_registros/views/historial_page.dart';
import 'package:cfe_registros/views/terminales_danadas.dart';
import 'package:cfe_registros/views/upload_photos.dart';
import 'package:cfe_registros/views/view_photos.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _esCentro = false;
  bool _esAdmin = false;
  Set<Terminal> _terminalesDanadas = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool esAdmin = prefs.getBool('esAdmin') ?? false;
    bool esCentro = prefs.getBool('esCentro') ?? false;
    String currentUserRP = prefs.getString('rp') ?? "No disponible";

    List<Terminal>? terminales = await _ApiTerminalService.getTerminales();
    List<Map<String, dynamic>>? usuariosData = await _ApiUserService.getUsers();
    List<TerminalDanada> terminalesDanadas =
        await _ApiTerminalService.getTerminalesDanadas();

    if (terminales != null && usuariosData != null) {
      setState(() {
        _esCentro = esCentro;
        _esAdmin = esAdmin;

        if (_esAdmin) {
          _terminales = terminales;
        } else if (_esCentro) {
          _terminales = terminales.where((terminal) {
            return terminal.rpeResponsable == currentUserRP;
          }).toList();
        } else {
          _terminales = [];
        }

        _filteredTerminales = _terminales;
        _usuarios = usuariosData;
        _isLoading = false;
      });

      _terminalesDanadas.clear();
      for (var terminal in _terminales) {
        bool sigueDanada =
            terminalesDanadas.any((t) => t.serie == terminal.serie);
        String? fechaReparacion =
            prefs.getString('terminal_reparada_${terminal.serie}');

        // 🔹 La terminal sigue apareciendo en la lista de terminales dañadas
        if (sigueDanada) {
          _terminalesDanadas.add(terminal);
        }

        // 🔹 Si tiene fecha de reparación, solo desmarcamos la casilla (sin eliminarla de la lista)
        if (fechaReparacion != null) {
          _terminalesDanadas.remove(terminal);
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 🔍 **Filtrar la lista según el texto de búsqueda (coincidencias exactas)**
  void _filterSearchResults(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();

      if (_searchQuery.isEmpty) {
        // ✅ Si el campo de búsqueda está vacío, restaurar todos los registros
        _filteredTerminales = List.from(_terminales);
      } else {
        // ✅ Buscar solo coincidencias exactas
        _filteredTerminales = _terminales.where((terminal) {
          return terminal.marca.trim().toLowerCase() == _searchQuery ||
              terminal.modelo.trim().toLowerCase() == _searchQuery ||
              terminal.serie.trim().toLowerCase() == _searchQuery ||
              terminal.inventario.trim().toLowerCase() == _searchQuery ||
              terminal.nombreResponsable.trim().toLowerCase() == _searchQuery ||
              _getNombreUsuario(terminal.usuarioId).trim().toLowerCase() ==
                  _searchQuery ||
              _getRpUsuario(terminal.usuarioId).trim().toLowerCase() ==
                  _searchQuery ||
              _getAreaResponsablePorRP(terminal.rpeResponsable)
                      .trim()
                      .toLowerCase() ==
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

  // 🔹 Obtener el área del Responsable
  String _getAreaResponsablePorRP(String rpResponsable) {
    var responsable = _usuarios.firstWhere(
        (user) =>
            user['rp'].toString().trim().toLowerCase() ==
            rpResponsable.trim().toLowerCase(),
        orElse: () => {'nom_area': "No disponible"});

    String area = responsable['nom_area']?.trim() ?? "No disponible";

    return area;
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

  void _navigateToViewPhotos(
      int terminalId, Map<String, List<String>> fotosPorFecha) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewPhotosPage(
            terminalId: terminalId, fotosPorFecha: fotosPorFecha),
      ),
    );
  }

  void _marcarTerminalDanada(Terminal terminal, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (value) {
      // 🔹 Si el usuario vuelve a marcar la casilla, eliminamos la fecha de reparación guardada
      await prefs.remove('terminal_reparada_${terminal.serie}');
    }

    setState(() {
      if (value) {
        _terminalesDanadas.add(terminal);
      } else {
        _terminalesDanadas.remove(terminal);
      }
    });

    if (value) {
      bool success = await _ApiTerminalService.marcarTerminalDanada(terminal.id,
          terminal.marca, terminal.modelo, terminal.serie, terminal.inventario);

      if (success) {
        // ✅ Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Terminal dañada guardada exitosamente"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al marcar terminal como dañada"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 📌 Encabezado con título, búsqueda y filtros
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
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

                      // 🔍 Barra de búsqueda
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

                      // 🔽 Filtro de orden
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
                const SizedBox(height: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DataTable2(
                      columnSpacing: 24,
                      horizontalMargin: 24,
                      minWidth: 3000,
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
                        DataColumn(label: Text("Área")),
                        DataColumn(label: Text("Fotos")),
                        DataColumn(label: Text("Fotos Nuevas")),
                        DataColumn(label: Text("Dañada")),
                        DataColumn(label: Text("Opciones")),
                      ],
                      rows: _filteredTerminales.asMap().entries.map((entry) {
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(Text(_getAreaResponsablePorRP(
                              terminal.rpeResponsable))),
                          DataCell(
                            TextButton(
                              onPressed: () {
                                if (terminal.fotos.isNotEmpty) {
                                  _navigateToViewPhotos(
                                      terminal.id, terminal.fotos);
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
                                ? const Text("-")
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
                            Checkbox(
                              value: _terminalesDanadas.contains(terminal),
                              onChanged: _terminalesDanadas.contains(terminal)
                                  ? null // 🔒 Ya está marcada, deshabilita el cambio
                                  : (bool? value) {
                                      if (value == true) {
                                        _marcarTerminalDanada(terminal, true);
                                      }
                                    },
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
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
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
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
