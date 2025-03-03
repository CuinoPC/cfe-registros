import 'package:cfe_registros/services/api_terminales.dart';
import 'package:cfe_registros/services/api_users.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/terminal.dart';

class UpdateTerminal extends StatefulWidget {
  final Terminal terminal;

  UpdateTerminal({required this.terminal});

  @override
  _UpdateTerminalState createState() => _UpdateTerminalState();
}

class _UpdateTerminalState extends State<UpdateTerminal> {
  final ApiTerminalService _ApiTerminalService = ApiTerminalService();
  final ApiUserService _ApiUserService = ApiUserService();
  final TextEditingController marcaController = TextEditingController();
  final TextEditingController modeloController = TextEditingController();
  final TextEditingController serieController = TextEditingController();
  final TextEditingController inventarioController = TextEditingController();

  List<Map<String, dynamic>> _usuarios = [];
  List<Terminal> _terminales = [];
  List<Map<String, dynamic>> _responsables = []; // Solo jefes de centro
  List<Map<String, dynamic>> _usuariosTerminal = []; // Solo usuarios terminales

  int? _selectedResponsableId;
  String _selectedResponsableRP = "";
  String _selectedResponsableNombre = "";
  String _selectedArea = "";

  int? _selectedUsuarioId; // Usuario que usará la terminal

  bool _esAdmin = false; // ✅ Estado de admin

  @override
  void initState() {
    super.initState();
    marcaController.text = widget.terminal.marca;
    modeloController.text = widget.terminal.modelo;
    serieController.text = widget.terminal.serie;
    inventarioController.text = widget.terminal.inventario;
    _selectedResponsableId = null;
    _selectedUsuarioId = widget.terminal.usuarioId;

    _loadUsuariosYTerminales();
    _loadAdminStatus(); // ✅ Cargar si el usuario es admin
  }

  Future<void> _loadAdminStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _esAdmin =
          prefs.getBool('esAdmin') ?? false; // ✅ Recupera estado de admin
    });
  }

  Future<void> _loadUsuariosYTerminales() async {
    List<Map<String, dynamic>>? usuarios = await _ApiUserService.getUsers();
    List<Terminal>? terminales = await _ApiTerminalService.getTerminales();

    if (usuarios != null && terminales != null) {
      setState(() {
        _usuarios = usuarios;
        _terminales = terminales;
        _selectedArea = _getAreaUsuario(widget.terminal.usuarioId);

        // 🔹 Filtrar usuarios responsables (solo los que son "es_centro")
        _responsables =
            usuarios.where((user) => user['es_centro'] == true).toList();

        // 🔹 Filtrar usuarios terminal (los que NO son "es_centro")
        _usuariosTerminal =
            usuarios.where((user) => user['es_centro'] == false).toList();

        // ✅ Buscar responsable correcto
        var responsable = _responsables.firstWhere(
            (user) => user['rp'] == widget.terminal.rpeResponsable,
            orElse: () => {});

        _selectedResponsableId = responsable['id'];
        _selectedResponsableRP = responsable['rp'] ?? "";
        _selectedResponsableNombre = responsable['nombre_completo'] ?? "";
      });
    }
  }

  String _getAreaUsuario(int usuarioId) {
    var usuario = _usuarios.firstWhere((user) => user['id'] == usuarioId,
        orElse: () => {'nom_area': "No disponible"});
    return usuario['nom_area'].toString();
  }

  Future<void> _updateTerminal() async {
    String marca = marcaController.text;
    String modelo = modeloController.text;
    String serie = serieController.text;
    String inventario = inventarioController.text;

    if (marca.isEmpty ||
        serie.isEmpty ||
        inventario.isEmpty ||
        _selectedResponsableId == null ||
        _selectedUsuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Todos los campos son obligatorios"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // ✅ 1. ACTUALIZAR SOLO LA TERMINAL PRINCIPAL (sin afectar las demás)
    bool success = await _ApiTerminalService.updateTerminal(
      widget.terminal.id,
      marca,
      modelo,
      serie,
      inventario,
      _selectedResponsableRP,
      _selectedResponsableNombre,
      _selectedUsuarioId!, // ✅ SOLO esta terminal cambia de usuario terminal
    );

    // ✅ 2. SI SE CAMBIÓ EL RESPONSABLE, ACTUALIZAR LAS TERMINALES RELACIONADAS
    if (success && (_selectedResponsableRP != widget.terminal.rpeResponsable)) {
      List<Terminal> terminalesRelacionadas = _terminales.where((terminal) {
        return _getAreaUsuario(terminal.usuarioId) == _selectedArea;
      }).toList();

      for (var terminal in terminalesRelacionadas) {
        await _ApiTerminalService.updateTerminal(
          terminal.id,
          terminal.marca,
          terminal.modelo,
          terminal.serie,
          terminal.inventario,
          _selectedResponsableRP, // ✅ Cambiar solo el responsable en las demás
          _selectedResponsableNombre,
          terminal.usuarioId, // ❌ NO cambiar el usuario terminal en las demás
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Terminal actualizada correctamente"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
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
                        'Actualizar Terminal',
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
                          prefixIcon:
                              const Icon(Icons.inventory, color: Colors.teal),
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
                        value:
                            _selectedUsuarioId, // ✅ Verifica que esté inicializado correctamente
                        items: _usuariosTerminal.map((usuario) {
                          return DropdownMenuItem<int>(
                            value: usuario['id'],
                            child: Text(
                                "${usuario['nombre_completo']} (RP: ${usuario['rp']})"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUsuarioId = value!;
                            print(
                                "Nuevo Usuario Terminal ID: $_selectedUsuarioId"); // ✅ Depuración
                          });
                        },
                      ),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _updateTerminal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Actualizar Terminal",
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
