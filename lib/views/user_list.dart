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
  List<Map<String, dynamic>> _filteredUsers = [];
  String _searchQuery = "";

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
        _filteredUsers = users;
        _isLoading = false;
        _showPasswords = {
          for (var user in users) user['rp'].toString(): false
        }; // ✅ Claves en String
      });
    }
  }

  void _filterSearchResults(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();

      if (_searchQuery.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          return user['nombre_completo'].trim().toLowerCase() == _searchQuery ||
              user['rp'].toString().trim().toLowerCase() == _searchQuery ||
              user['nom_area'].trim().toLowerCase() == _searchQuery;
        }).toList();
      }
    });
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 📌 Encabezado con título y barra de búsqueda
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Lista de Usuarios",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: _filterSearchResults,
                        decoration: InputDecoration(
                          labelText: "Buscar por nombre, RP o área...",
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
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 📋 Tabla de usuarios
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DataTable2(
                      columnSpacing: 18,
                      horizontalMargin: 18,
                      minWidth: 1500,
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
                      rows: _filteredUsers.asMap().entries.map((entry) {
                        int index = entry.key + 1;
                        Map<String, dynamic> user = entry.value;
                        String rp = user['rp'].toString();

                        return DataRow(cells: [
                          DataCell(Text(index.toString())),
                          DataCell(Text(user['nombre_completo'])),
                          DataCell(Text(rp)),
                          DataCell(Text(user['nom_area'])),
                          DataCell(Text(user['proceso'])),
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
                                            UpdateUser(user: user),
                                      ),
                                    ).then((updated) {
                                      if (updated == true) _fetchUsers();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    _deleteUser(rp);
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
