import 'package:cfe_registros/services/api_users.dart';
import 'package:flutter/material.dart';
import '../views/custom_appbar.dart';

class UpdateUser extends StatefulWidget {
  final Map<String, dynamic> user;

  UpdateUser({required this.user});

  @override
  _UpdateUserState createState() => _UpdateUserState();
}

class _UpdateUserState extends State<UpdateUser> {
  final ApiUserService _ApiUserService = ApiUserService();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController contraseniaController = TextEditingController();
  final TextEditingController rpController = TextEditingController();
  bool esAdmin = false;
  bool esCentro = false; // ✅ Agregar esta variable
  bool _showPassword = false;
  int? _selectedAreaId; // ✅ ID del área seleccionada
  List<Map<String, dynamic>> _areas = []; // ✅ Lista de áreas disponibles

  @override
  void initState() {
    super.initState();
    rpController.text = widget.user['rp'].toString();
    nombreController.text = widget.user['nombre_completo'];
    contraseniaController.text = widget.user['contrasenia'];
    esAdmin = widget.user['es_admin'];
    esCentro = widget.user['es_centro']; // ✅ Cargar estado del Jefe de Centro

    _selectedAreaId = widget.user['area_id']; // ✅ Establecer el área al cargar

    _fetchAreas();
  }

  Future<void> _fetchAreas() async {
    final areas = await _ApiUserService.getAreas();
    if (areas != null) {
      setState(() {
        _areas = areas;
        _selectedAreaId =
            widget.user['area_id']; // ✅ Establecer el área actual del usuario
      });
    }
  }

  Future<void> _updateUser() async {
    if (_selectedAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Debe seleccionar un área"),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    bool success = await _ApiUserService.updateUser(
      rpController.text,
      nombreController.text,
      _selectedAreaId!, // ✅ Enviar el área como ID
      contraseniaController.text,
      esAdmin,
      esCentro,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Usuario actualizado exitosamente"),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Error al actualizar usuario"),
            backgroundColor: Colors.redAccent),
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
                        'Actualizar Usuario',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: rpController,
                        decoration: InputDecoration(
                          labelText: "RP",
                          prefixIcon:
                              const Icon(Icons.badge, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        readOnly: true, // ✅ RP no editable
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
                      DropdownButtonFormField<int>(
                        value: _selectedAreaId, // ✅ Cargar área existente
                        items: _areas.map((area) {
                          return DropdownMenuItem<int>(
                            value: area['id'],
                            child: Text(area['nom_area']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAreaId = value;
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            "Es Jefe de Centro",
                            style: TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          Switch(
                            value: esCentro,
                            onChanged: (bool value) {
                              setState(() {
                                esCentro = value;
                              });
                            },
                            activeColor: Colors.teal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _updateUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Actualizar Usuario",
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
