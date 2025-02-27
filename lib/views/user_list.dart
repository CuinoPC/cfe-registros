import 'package:cfe_registros/services/api_users.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:cfe_registros/views/update_user.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'add_user.dart';

class UserList extends StatefulWidget {
  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final ApiUserService _ApiUserService = ApiUserService();
  List<Map<String, dynamic>> _users = [];
  Map<String, bool> _showPasswords = {}; // ✅ Ahora usa String como clave
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final users = await _ApiUserService.getUsers();
    if (users != null) {
      setState(() {
        _users = users;
        _isLoading = false;
        _showPasswords = {
          for (var user in users) user['rp'].toString(): false
        }; // ✅ Claves en String
      });
    }
  }

  Future<void> _deleteUser(String rp) async {
    bool success = await _ApiUserService.deleteUser(rp);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario eliminado exitosamente")),
      );
      _fetchUsers(); // Refrescar la lista de usuarios
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar usuario")),
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
                    columns: const [
                      DataColumn(label: Text("#")),
                      DataColumn(label: Text("Nombre")),
                      DataColumn(label: Text("RP")),
                      DataColumn(label: Text("Área")),
                      DataColumn(label: Text("Proceso")),
                      DataColumn(label: Text("Contraseña")),
                      DataColumn(label: Text("Admin")),
                      DataColumn(label: Text("Jefe de centro")),
                      DataColumn(label: Text("Opciones")),
                    ],
                    rows: _users.asMap().entries.map((entry) {
                      int index = entry.key + 1; // ✅ Generar número de fila
                      Map<String, dynamic> user = entry.value;
                      String rp =
                          user['rp'].toString(); // ✅ Convertir RP a String

                      return DataRow(cells: [
                        DataCell(Text(index.toString())),
                        DataCell(Text(user['nombre_completo'])),
                        DataCell(Text(rp)), // ✅ Ahora RP es String
                        DataCell(Text(user['nom_area'])), // Muestra el área
                        DataCell(Text(user['proceso'])), // Muestra el proceso
                        DataCell(
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _showPasswords[rp]!
                                      ? user['contrasenia']
                                      : "******",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: Icon(_showPasswords[rp]!
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _showPasswords[rp] = !_showPasswords[rp]!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(user['es_admin'] ? "Sí" : "No")),
                        DataCell(Text(user['es_centro'] ? "Sí" : "No")),
                        // 🔹 Nueva Celda con Botones de Opciones
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
                                          UpdateUser(user: user),
                                    ),
                                  ).then((updated) {
                                    if (updated == true)
                                      _fetchUsers(); // ✅ Refrescar tabla
                                  });
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteUser(rp); // ✅ Ahora pasa String
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
