import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:cfe_registros/views/upload_photos.dart';
import 'package:cfe_registros/views/view_photos.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../services/api_service.dart';
import '../models/terminal.dart';
import 'add_terminal.dart';
import 'update_terminal.dart';

class TerminalList extends StatefulWidget {
  @override
  _TerminalListState createState() => _TerminalListState();
}

class _TerminalListState extends State<TerminalList> {
  final ApiService _apiService = ApiService();
  List<Terminal> _terminales = [];
  List<Map<String, dynamic>> _usuarios = []; // Lista de usuarios
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    List<Terminal>? terminales = await _apiService.getTerminales();
    List<Map<String, dynamic>>? usuariosData = await _apiService.getUsers();

    if (terminales != null && usuariosData != null) {
      setState(() {
        _terminales = terminales;
        _usuarios = usuariosData;
        _isLoading = false;
      });
    }
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
    bool success = await _apiService.deleteTerminal(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terminal eliminada correctamente")),
      );
      _fetchData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar la terminal")),
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

      await _fetchData(); // ✅ Recargar la lista

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToViewPhotos(List<String> fotos) {
    if (fotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No hay fotos disponibles")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewPhotosPage(fotos: fotos),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 900,
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.teal.shade100),
                    border: TableBorder.all(color: Colors.grey),
                    columns: [
                      DataColumn(label: Text("#")),
                      DataColumn(label: Text("Marca")),
                      DataColumn(label: Text("Serie")),
                      DataColumn(label: Text("Inventario")),
                      DataColumn(label: Text("Responsable (RPE)")),
                      DataColumn(label: Text("Nombre Responsable")),
                      DataColumn(label: Text("Usuario (RP)")),
                      DataColumn(label: Text("Área del Usuario")),
                      DataColumn(label: Text("Fotos")),
                      DataColumn(label: Text("Opciones")),
                    ],
                    rows: _terminales.asMap().entries.map((entry) {
                      int index = entry.key + 1;
                      Terminal terminal = entry.value;
                      return DataRow(cells: [
                        DataCell(Text(index.toString())),
                        DataCell(Text(terminal.marca)),
                        DataCell(Text(terminal.serie)),
                        DataCell(Text(terminal.inventario)),
                        DataCell(Text(terminal.rpeResponsable.toString())),
                        DataCell(Text(terminal.nombreResponsable)),
                        DataCell(
                          Text(
                            "${_getNombreUsuario(terminal.usuarioId)} (RP: ${_getRpUsuario(terminal.usuarioId)})",
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
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
                                icon: Icon(Icons.delete, color: Colors.red),
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
