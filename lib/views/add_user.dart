import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddUser extends StatefulWidget {
  @override
  _AddUserState createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  final ApiService _apiService = ApiService();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController rpController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController contraseniaController = TextEditingController();
  bool esAdmin = false;
  bool _showPassword = false;

  Future<void> _addUser() async {
    String nombre = nombreController.text;
    int rp = int.tryParse(rpController.text) ?? 0;
    String area = areaController.text;
    String contrasenia = contraseniaController.text;

    if (nombre.isEmpty || rp == 0 || area.isEmpty || contrasenia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Todos los campos son obligatorios"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    bool success =
        await _apiService.createUser(nombre, rp, area, contrasenia, esAdmin);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Usuario agregado exitosamente"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al agregar usuario"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade300,
              Colors.teal.shade700,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 400,
              padding: EdgeInsets.all(16.0),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Añadir Usuario',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: nombreController,
                        decoration: InputDecoration(
                          labelText: "Nombre Completo",
                          prefixIcon: Icon(Icons.person, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: rpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "RP",
                          prefixIcon: Icon(Icons.badge, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: areaController,
                        decoration: InputDecoration(
                          labelText: "Área",
                          prefixIcon: Icon(Icons.work, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: contraseniaController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: "Contrasenia",
                          prefixIcon: Icon(Icons.lock, color: Colors.teal),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.teal,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            "Es Administrador",
                            style: TextStyle(fontSize: 16),
                          ),
                          Spacer(),
                          Switch(
                            value: esAdmin,
                            onChanged: (bool value) {
                              setState(() {
                                esAdmin = value;
                              });
                            },
                            activeColor: Colors.teal,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Guardar Usuario",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
