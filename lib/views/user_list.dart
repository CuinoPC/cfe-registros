import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:cfe_registros/views/update_user.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../services/api_service.dart';
import 'add_user.dart';

class UserList extends StatefulWidget {
  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _users = [];
  Map<int, bool> _showPasswords = {}; // Almacenar visibilidad por usuario
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final users = await _apiService.getUsers();
    if (users != null) {
      setState(() {
        _users = users;
        _isLoading = false;
        _showPasswords = {
          for (var user in users) user['rp']: false
        }; // Inicializa los estados de visibilidad
      });
    }
  }

  Future<void> _deleteUser(int rp) async {
    bool success = await _apiService.deleteUser(rp);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Usuario eliminado exitosamente")),
      );
      _fetchUsers(); // Refrescar la lista de usuarios
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar usuario")),
      );
    }
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
                    minWidth: 900, // Asegurar suficiente espacio
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.teal.shade100),
                    border: TableBorder.all(color: Colors.grey),
                    columns: [
                      DataColumn(label: Text("#")),
                      DataColumn(label: Text("Nombre")),
                      DataColumn(label: Text("RP")),
                      DataColumn(label: Text("Área")),
                      DataColumn(label: Text("Proceso")),
                      DataColumn(label: Text("Contraseña")),
                      DataColumn(label: Text("Admin")),
                      DataColumn(label: Text("Opciones")),
                    ],
                    rows: _users.asMap().entries.map((entry) {
                      int index = entry.key + 1; // ✅ Generar número de fila
                      Map<String, dynamic> user = entry.value;
                      return DataRow(cells: [
                        DataCell(Text(index.toString())),
                        DataCell(Text(user['nombre_completo'])),
                        DataCell(Text(user['rp'].toString())),
                        DataCell(Text(user['nom_area'])), // Muestra el área
                        DataCell(Text(user['proceso'])), // Muestra el proceso
                        DataCell(
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _showPasswords[user['rp']]!
                                      ? user['contrasenia']
                                      : "******",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: Icon(_showPasswords[user['rp']]!
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _showPasswords[user['rp']] =
                                        !_showPasswords[user['rp']]!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(user['es_admin'] ? "Sí" : "No")),
                        // 🔹 Nueva Celda con Botones de Opciones
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
                                          UpdateUser(user: user),
                                    ),
                                  ).then((updated) {
                                    if (updated == true)
                                      _fetchUsers(); // ✅ Refrescar tabla
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteUser(user['rp']);
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
            MaterialPageRoute(builder: (context) => AddUser()),
          ).then((_) => _fetchUsers());
        },
        backgroundColor: Colors.teal.shade100,
        child: Icon(Icons.add, color: Colors.teal.shade900),
        tooltip: "Añadir Usuario",
      ),
    );
  }
}
