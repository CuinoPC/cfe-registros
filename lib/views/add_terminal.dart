import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddTerminal extends StatefulWidget {
  @override
  _AddTerminalState createState() => _AddTerminalState();
}

class _AddTerminalState extends State<AddTerminal> {
  final ApiService _apiService = ApiService();
  final TextEditingController marcaController = TextEditingController();
  final TextEditingController modeloController = TextEditingController();
  final TextEditingController serieController = TextEditingController();
  final TextEditingController inventarioController = TextEditingController();
  final TextEditingController rpeController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();

  List<Map<String, dynamic>> _usuarios = []; // Lista de usuarios
  int? _selectedUsuarioId; // ID del usuario seleccionado

  @override
  void initState() {
    super.initState();
    _loadUsuarios(); // Cargar usuarios al iniciar la pantalla
  }

  Future<void> _loadUsuarios() async {
    List<Map<String, dynamic>>? usuarios = await _apiService.getUsers();
    if (usuarios != null) {
      setState(() {
        _usuarios = usuarios;
      });
    }
  }

  Future<void> _addTerminal() async {
    String marca = marcaController.text;
    String modelo = modeloController.text;
    String serie = serieController.text;
    String inventario = inventarioController.text;
    int? rpe = int.tryParse(rpeController.text);
    String nombre = nombreController.text;

    if (marca.isEmpty ||
        modelo.isEmpty ||
        serie.isEmpty ||
        inventario.isEmpty ||
        rpe == null ||
        nombre.isEmpty ||
        _selectedUsuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Todos los campos son obligatorios"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    bool success = await _apiService.createTerminal(
        marca, modelo, serie, inventario, rpe, nombre, _selectedUsuarioId!);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terminal agregada exitosamente"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al agregar terminal"),
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
                        'Añadir Terminal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: marcaController,
                        decoration: InputDecoration(
                          labelText: "Marca",
                          prefixIcon:
                              Icon(Icons.devices_other, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: modeloController,
                        decoration: InputDecoration(
                          labelText: "Modelo",
                          prefixIcon:
                              Icon(Icons.devices_other, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: serieController,
                        decoration: InputDecoration(
                          labelText: "Serie",
                          prefixIcon: Icon(Icons.numbers, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: inventarioController,
                        decoration: InputDecoration(
                          labelText: "Inventario",
                          prefixIcon: Icon(Icons.inventory, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: rpeController,
                        decoration: InputDecoration(
                          labelText: "RPE Responsable",
                          prefixIcon: Icon(Icons.badge, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: nombreController,
                        decoration: InputDecoration(
                          labelText: "Nombre Responsable",
                          prefixIcon: Icon(Icons.person, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: "Seleccionar Usuario",
                          prefixIcon: Icon(Icons.supervisor_account,
                              color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        value: _selectedUsuarioId,
                        items: _usuarios.map((usuario) {
                          return DropdownMenuItem<int>(
                            value: usuario['id'],
                            child: Text(
                                "${usuario['nombre_completo']} (RP: ${usuario['rp']})"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUsuarioId = value;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addTerminal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Guardar Terminal",
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
