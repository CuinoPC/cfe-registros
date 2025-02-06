import 'package:cfe_registros/views/custom_appbar.dart';
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
                    minWidth: 800,
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.teal.shade100),
                    border: TableBorder.all(color: Colors.grey),
                    columns: [
                      DataColumn(label: Text("Nombre")),
                      DataColumn(label: Text("RP")),
                      DataColumn(label: Text("Área")),
                      DataColumn(label: Text("Contrasenia")),
                      DataColumn(label: Text("Admin")),
                    ],
                    rows: _users.map((user) {
                      return DataRow(cells: [
                        DataCell(Text(user['nombre_completo'])),
                        DataCell(Text(user['rp'].toString())),
                        DataCell(Text(user['area'])),
                        DataCell(
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _showPasswords[user['rp']]!
                                      ? (user['contrasenia'] ?? "No asignada")
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
                        DataCell(Text(user['es_admin']
                            ? "Sí"
                            : "No")), // Muestra "Sí" o "No"
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
        child: Icon(Icons.add),
        tooltip: "Añadir Usuario",
      ),
    );
  }
}
