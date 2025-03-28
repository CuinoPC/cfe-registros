import 'package:cfe_registros/models/lector.dart';
import 'package:cfe_registros/models/lector_danado.dart';
import 'package:cfe_registros/services/api_lector.dart';
import 'package:cfe_registros/services/api_lector_danado.dart';
import 'package:cfe_registros/services/api_users.dart';
import 'package:cfe_registros/views/add_lector.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:cfe_registros/views/lector_historial.dart';
import 'package:cfe_registros/views/update_lector.dart';
import 'package:cfe_registros/views/add_supervision_lector.dart';
import 'package:cfe_registros/views/view_supervision_lector.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LectorList extends StatefulWidget {
  @override
  _LectorListState createState() => _LectorListState();
}

class _LectorListState extends State<LectorList> {
  final LectorService _lectorService = LectorService();
  final LectorDanadoService _lectorDanadoService = LectorDanadoService();
  final ApiUserService _apiUserService = ApiUserService();

  List<Lector> _lectores = [];
  List<Lector> _filteredLectores = [];
  List<Map<String, dynamic>> _usuarios = [];

  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedFilter = "Fecha";
  bool _esCentro = false;
  bool _esAdmin = false;
  Set<Lector> _lectoresDanados = {};

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

    List<Lector>? lectores = await _lectorService.getLectores();
    List<Map<String, dynamic>>? usuariosData = await _apiUserService.getUsers();
    List<LectorDanado> lectoresDanados =
        await _lectorDanadoService.getLectoresDanados();

    if (lectores != null && usuariosData != null) {
      setState(() {
        _esCentro = esCentro;
        _esAdmin = esAdmin;

        if (_esAdmin) {
          _lectores = lectores;
        } else if (_esCentro) {
          _lectores =
              lectores.where((l) => l.rpeResponsable == currentUserRP).toList();
        } else {
          _lectores = [];
        }

        _filteredLectores = _lectores;
        _usuarios = usuariosData;
        _isLoading = false;
      });

      _lectoresDanados.clear();
      for (var lector in _lectores) {
        bool sigueDanado = lectoresDanados.any((l) => l.folio == lector.folio);
        String? fechaReparacion =
            prefs.getString('lector_reparado_${lector.folio}');

        if (sigueDanado) {
          _lectoresDanados.add(lector);
        }

        if (fechaReparacion != null) {
          _lectoresDanados.remove(lector);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _filterSearchResults(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredLectores = List.from(_lectores);
      } else {
        _filteredLectores = _lectores.where((lector) {
          return lector.marca.toLowerCase() == _searchQuery ||
              lector.modelo.toLowerCase() == _searchQuery ||
              lector.folio.toLowerCase() == _searchQuery ||
              lector.tipoConector.toLowerCase() == _searchQuery ||
              _getNombreUsuario(lector.usuarioId).toLowerCase() ==
                  _searchQuery ||
              _getRpUsuario(lector.usuarioId).toLowerCase() == _searchQuery ||
              lector.area.toLowerCase() == _searchQuery;
        }).toList();
      }
    });
  }

  void _sortBySelectedFilter() {
    setState(() {
      switch (_selectedFilter) {
        case "Marca":
          _filteredLectores.sort((a, b) => a.marca.compareTo(b.marca));
          break;
        case "Modelo":
          _filteredLectores.sort((a, b) => a.modelo.compareTo(b.modelo));
          break;
        case "Folio":
          _filteredLectores.sort((a, b) => a.folio.compareTo(b.folio));
          break;
        case "Usuario (RP)":
          _filteredLectores.sort((a, b) => _getNombreUsuario(a.usuarioId)
              .compareTo(_getNombreUsuario(b.usuarioId)));
          break;
        case "Fecha":
        default:
          _filteredLectores.sort((a, b) => b.id.compareTo(a.id));
          break;
      }
    });
  }

  String _getNombreUsuario(int usuarioId) {
    var usuario = _usuarios.firstWhere((u) => u['id'] == usuarioId,
        orElse: () => {'nombre_completo': "No disponible"});
    return usuario['nombre_completo'];
  }

  String _getRpUsuario(int usuarioId) {
    var usuario = _usuarios.firstWhere((u) => u['id'] == usuarioId,
        orElse: () => {'rp': "No disponible"});
    return usuario['rp'];
  }

  Future<void> _deleteLector(int id) async {
    bool success = await _lectorService.deleteLector(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lector eliminado correctamente")),
      );
      _fetchData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar el lector")),
      );
    }
  }

  void _navigateToUploadPhotos(int lectorId) async {
    bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadLectorPhotosPage(lectorId: lectorId),
      ),
    );

    if (updated == true) {
      setState(() => _isLoading = true);
      await _fetchData();
      setState(() => _isLoading = false);
    }
  }

  void _navigateToViewPhotos(
      int lectorId, Map<String, List<String>> fotosPorFecha) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewLectorPhotosPage(
          lectorId: lectorId,
          fotosPorFecha: fotosPorFecha,
        ),
      ),
    );
  }

  void _marcarLectorDanado(Lector lector, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (value) {
      await prefs.remove('lector_reparado_${lector.folio}');
    }

    setState(() {
      if (value) {
        _lectoresDanados.add(lector);
      } else {
        _lectoresDanados.remove(lector);
      }
    });

    if (value) {
      bool success = await _lectorDanadoService.marcarLectorDanado(
          lector.id,
          lector.marca,
          lector.modelo,
          lector.area,
          lector.folio,
          lector.tipoConector);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? "Lector dañado guardado exitosamente"
              : "Error al marcar lector como dañado"),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
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
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Lista de Lectores",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            HistorialLectorPage()),
                                  );
                                },
                                icon: const Icon(Icons.history,
                                    color: Colors.white),
                                label: const Text("Historial"),
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
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => AddLector()),
                                  ).then((_) => _fetchData());
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("Añadir Lector"),
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
                        DataColumn2(label: Text("#"), fixedWidth: 50),
                        DataColumn(label: Text("Marca")),
                        DataColumn(label: Text("Modelo")),
                        DataColumn(label: Text("Folio")),
                        DataColumn(label: Text("Tipo de Conector")),
                        DataColumn(label: Text("Responsable (RPE)")),
                        DataColumn(label: Text("Nombre Responsable")),
                        DataColumn(label: Text("Usuario (RP)")),
                        DataColumn(label: Text("Área")),
                        DataColumn2(
                            label: Text("Supervisión"), fixedWidth: 165),
                        DataColumn2(
                            label: Text("Supervisión Nueva"), fixedWidth: 225),
                        DataColumn2(label: Text("Dañado"), fixedWidth: 80),
                        DataColumn2(label: Text("Opciones"), fixedWidth: 100),
                      ],
                      rows: _filteredLectores.asMap().entries.map((entry) {
                        int index = entry.key + 1;
                        Lector lector = entry.value;
                        return DataRow(cells: [
                          DataCell(Text(index.toString())),
                          DataCell(SelectableText(lector.marca)),
                          DataCell(SelectableText(lector.modelo)),
                          DataCell(SelectableText(lector.folio)),
                          DataCell(SelectableText(lector.tipoConector)),
                          DataCell(SelectableText(lector.rpeResponsable)),
                          DataCell(SelectableText(lector.nombreResponsable)),
                          DataCell(
                            SelectableText(
                              "${_getNombreUsuario(lector.usuarioId)} (RP: ${_getRpUsuario(lector.usuarioId)})",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(SelectableText(lector.area)),
                          DataCell(
                            TextButton(
                              onPressed: () {
                                if (lector.fotos.isNotEmpty) {
                                  _navigateToViewPhotos(
                                      lector.id, lector.fotos);
                                } else {
                                  _navigateToUploadPhotos(lector.id);
                                }
                              },
                              child: Text(
                                lector.fotos.isNotEmpty
                                    ? "Ver Supervisión"
                                    : "Subir Supervisión",
                                style: TextStyle(
                                  color: lector.fotos.isNotEmpty
                                      ? Colors.green
                                      : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            lector.fotos.isEmpty
                                ? const Text("-")
                                : TextButton(
                                    onPressed: () {
                                      _navigateToUploadPhotos(lector.id);
                                    },
                                    child: const Text(
                                      "Cargar Supervisión Nueva",
                                      style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                          ),
                          DataCell(
                            Center(
                              child: Checkbox(
                                value: _lectoresDanados.contains(lector),
                                onChanged: _lectoresDanados.contains(lector)
                                    ? null
                                    : (bool? value) {
                                        if (value == true) {
                                          _marcarLectorDanado(lector, true);
                                        }
                                      },
                              ),
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
                                            UpdateLector(lector: lector),
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
                                    _deleteLector(lector.id);
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
    );
  }
}
