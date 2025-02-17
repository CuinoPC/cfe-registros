import 'package:cfe_registros/services/api_users.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';

class AddUser extends StatefulWidget {
  @override
  _AddUserState createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  final ApiUserService _ApiUserService = ApiUserService();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController rpController = TextEditingController();
  final TextEditingController contraseniaController = TextEditingController();
  bool esAdmin = false;
  bool _showPassword = false;
  int? _selectedAreaId; // ✅ ID del área seleccionada
  List<Map<String, dynamic>> _areas = []; // ✅ Lista de áreas

  @override
  void initState() {
    super.initState();
    _fetchAreas(); // Cargar áreas al iniciar
  }

  Future<void> _fetchAreas() async {
    final areas = await _ApiUserService.getAreas();
    if (areas != null) {
      setState(() {
        _areas = areas;
      });
    }
  }

  Future<void> _addUser() async {
    String nombre = nombreController.text;
    String rpText = rpController.text;
    int rp = int.tryParse(rpText) ?? 0;
    String contrasenia = contraseniaController.text;

    if (nombre.isEmpty ||
        rpText.isEmpty ||
        contrasenia.isEmpty ||
        _selectedAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Todos los campos son obligatorios"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (rpText.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El RP debe tener exactamente 5 dígitos"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    bool success = await _ApiUserService.createUser(
        nombre, rp, _selectedAreaId!, contrasenia, esAdmin);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Usuario agregado exitosamente"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nombreController,
                        decoration: InputDecoration(
                          labelText: "Nombre Completo",
                          prefixIcon:
                              const Icon(Icons.person, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: rpController,
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        decoration: InputDecoration(
                          labelText: "RP",
                          prefixIcon:
                              const Icon(Icons.badge, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          counterText: "",
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedAreaId,
                        items: _areas.map((area) {
                          return DropdownMenuItem<int>(
                            value: area['id'],
                            child: Text(area['nom_area']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAreaId = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Área",
                          prefixIcon:
                              const Icon(Icons.work, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: contraseniaController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: "Contraseña",
                          prefixIcon:
                              const Icon(Icons.lock, color: Colors.teal),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            "Es Administrador",
                            style: TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
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
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
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
