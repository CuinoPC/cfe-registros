import 'package:cfe_registros/services/api_terminales.dart';
import 'package:cfe_registros/services/api_users.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddTerminal extends StatefulWidget {
  @override
  _AddTerminalState createState() => _AddTerminalState();
}

class _AddTerminalState extends State<AddTerminal> {
  final ApiTerminalService _ApiTerminalService = ApiTerminalService();
  final ApiUserService _ApiUserService = ApiUserService();
  final TextEditingController marcaController = TextEditingController();
  final TextEditingController modeloController = TextEditingController();
  final TextEditingController serieController = TextEditingController();
  final TextEditingController inventarioController = TextEditingController();

  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _responsables = [];
  List<Map<String, dynamic>> _usuariosTerminal = [];

  int? _selectedResponsableId;
  String _selectedResponsableRP = "";
  String _selectedResponsableNombre = "";

  int? _selectedUsuarioId;
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
    _loadAdminStatus(); // ✅ Cargar si el usuario es admin
  }

  Future<void> _loadUsuarios() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool esAdmin = prefs.getBool('esAdmin') ?? false;
    bool esCentro = prefs.getBool('esCentro') ?? false;
    String currentUserRP = prefs.getString('rp') ?? "No disponible";

    print(
        "⚡ SharedPreferences -> esAdmin: $esAdmin, esCentro: $esCentro, RP Usuario: $currentUserRP");

    List<Map<String, dynamic>>? usuarios = await _ApiUserService.getUsers();

    if (usuarios != null) {
      setState(() {
        _usuarios = usuarios;

        // 🔹 Filtrar responsables (solo los que son `es_centro`)
        _responsables =
            usuarios.where((user) => user['es_centro'] == true).toList();

        // 🔹 Si es admin, ver todos los usuarios terminales
        if (esAdmin) {
          _usuariosTerminal = usuarios
              .where((user) =>
                  user['es_centro'] == false && user['es_admin'] == false)
              .toList();
        } else {
          // ✅ Si NO es admin, solo mostrar usuarios terminales del área del responsable seleccionado
          _usuariosTerminal = [];
        }
      });
    }
  }

  // 🔹 Filtrar usuarios terminales cuando cambie el responsable
  void _filtrarUsuariosPorResponsable() {
    if (_selectedResponsableId != null) {
      var responsable = _responsables.firstWhere(
          (user) => user['id'] == _selectedResponsableId,
          orElse: () => {});
      String areaResponsable = responsable['nom_area'] ?? "No disponible";

      setState(() {
        _usuariosTerminal = _usuarios
            .where((user) =>
                user['es_centro'] == false &&
                user['es_admin'] == false &&
                user['nom_area'] == areaResponsable)
            .toList();
      });
    }
  }

  Future<void> _loadAdminStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _esAdmin =
          prefs.getBool('esAdmin') ?? false; // ✅ Recupera estado de admin
    });
  }

  Future<void> _addTerminal() async {
    String marca = marcaController.text;
    String modelo = modeloController.text;
    String serie = serieController.text;
    String inventario = inventarioController.text;

    if (marca.isEmpty ||
        modelo.isEmpty ||
        serie.isEmpty ||
        inventario.isEmpty ||
        (!_esAdmin && _selectedResponsableId == null) ||
        _selectedUsuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Todos los campos obligatorios"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    bool success = await _ApiTerminalService.createTerminal(
      marca,
      modelo,
      serie,
      inventario,
      _selectedResponsableRP,
      _selectedResponsableNombre,
      _selectedUsuarioId!,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terminal agregada exitosamente"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
                        'Añadir Terminal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: marcaController,
                        decoration: InputDecoration(
                          labelText: "Marca",
                          prefixIcon: const Icon(Icons.devices_other,
                              color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: modeloController,
                        decoration: InputDecoration(
                          labelText: "Modelo",
                          prefixIcon: const Icon(Icons.devices_other,
                              color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: serieController,
                        decoration: InputDecoration(
                          labelText: "Serie",
                          prefixIcon:
                              const Icon(Icons.numbers, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),

                      // 🔽 Mostrar campo de Responsable SOLO si el usuario es admin
                      if (_esAdmin)
                        Column(
                          children: [
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: "Responsable (Jefe de Centro)",
                                prefixIcon:
                                    const Icon(Icons.badge, color: Colors.teal),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              value: _selectedResponsableId,
                              items: _responsables.map((usuario) {
                                return DropdownMenuItem<int>(
                                  value: usuario['id'],
                                  child: Text(
                                      "${usuario['nombre_completo']} (RP: ${usuario['rp']})"),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedResponsableId = value;
                                  var usuario = _responsables.firstWhere(
                                      (user) => user['id'] == value,
                                      orElse: () => {});
                                  _selectedResponsableRP = usuario['rp'] ?? "";
                                  _selectedResponsableNombre =
                                      usuario['nombre_completo'] ?? "";
                                });

                                _filtrarUsuariosPorResponsable(); // 🔥 Filtrar usuarios terminales cuando cambie el responsable
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // 🔽 Dropdown para seleccionar el Usuario Terminal
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: "Usuario Terminal",
                          prefixIcon: const Icon(Icons.supervisor_account,
                              color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        value: _selectedUsuarioId,
                        items: _usuariosTerminal.map((usuario) {
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
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addTerminal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
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
