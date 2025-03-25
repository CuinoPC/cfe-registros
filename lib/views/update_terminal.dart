import 'package:cfe_registros/services/api_terminal.dart';
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
  final TerminalService _ApiTerminalService = TerminalService();
  final ApiUserService _ApiUserService = ApiUserService();
  final TextEditingController marcaController = TextEditingController();
  final TextEditingController modeloController = TextEditingController();
  final TextEditingController serieController = TextEditingController();
  final TextEditingController inventarioController = TextEditingController();

  List<Map<String, dynamic>> _usuarios = [];
  List<Terminal> _terminales = [];
  List<Map<String, dynamic>> _responsables = [];
  List<Map<String, dynamic>> _usuariosTerminal = [];
  List<Map<String, dynamic>> _areas = [];

  int? _selectedResponsableId;
  int? _selectedAreaId;
  String _selectedResponsableRP = "";
  String _selectedResponsableNombre = "";
  String _selectedArea = "";
  String _selectedAreaNombre = "";

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
    _selectedArea = widget.terminal.area;

    _loadUsuariosYTerminales();
    _loadAreas();
    _loadAdminStatus();
  }

  Future<void> _loadAreas() async {
    List<Map<String, dynamic>>? areas = await _ApiUserService.getAreas();
    if (areas != null) {
      setState(() {
        _areas = areas;
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

  Future<void> _loadUsuariosYTerminales() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool esAdmin = prefs.getBool('esAdmin') ?? false;
    bool esCentro = prefs.getBool('esCentro') ?? false;
    String currentUserRP = prefs.getString('rp') ?? "No disponible";

    print(
        "⚡ SharedPreferences -> esAdmin: $esAdmin, esCentro: $esCentro, RP Usuario: $currentUserRP");

    List<Map<String, dynamic>>? usuarios = await _ApiUserService.getUsers();
    List<Terminal>? terminales = await _ApiTerminalService.getTerminales();

    if (usuarios != null && terminales != null) {
      setState(() {
        _usuarios = usuarios;
        _terminales = terminales;

        // ✅ Obtener el área del usuario logueado (si es jefe de centro)
        String currentUserArea = "No disponible";
        var currentUser = usuarios.firstWhere(
            (user) => user['rp'] == currentUserRP,
            orElse: () => {'nom_area': "No disponible"});
        currentUserArea = currentUser['nom_area'] ?? "No disponible";

        // 🔹 Filtrar responsables (solo los que son `es_centro`)
        _responsables =
            usuarios.where((user) => user['es_centro'] == true).toList();

        // 🔹 Si es admin, inicialmente ver todos los usuarios terminales
        if (esAdmin) {
          _usuariosTerminal = usuarios
              .where((user) =>
                  user['es_centro'] == false && user['es_admin'] == false)
              .toList();
        } else if (esCentro) {
          // 🔹 Si es jefe de centro, ver solo usuarios terminales de su área
          _usuariosTerminal = usuarios
              .where((user) =>
                  user['es_admin'] == false &&
                  user['nom_area'] == currentUserArea)
              .toList();
        } else {
          _usuariosTerminal = [];
        }

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

  void _filtrarUsuariosPorResponsable() {
    if (_selectedResponsableId != null) {
      var responsable = _responsables.firstWhere(
        (user) => user['id'] == _selectedResponsableId,
        orElse: () => {},
      );

      String areaResponsable = responsable['nom_area'] ?? "No disponible";

      setState(() {
        _usuariosTerminal = _usuarios
            .where((user) =>
                user['nom_area'] == areaResponsable &&
                user['es_admin'] == false)
            .toList();

        // ✅ Incluir al responsable también en la lista si no es admin
        if (responsable['es_admin'] != true &&
            !_usuariosTerminal.any((u) => u['id'] == responsable['id'])) {
          _usuariosTerminal.add(responsable);
        }
      });
    }
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

    // ✅ 1. ACTUALIZAR LA TERMINAL PRINCIPAL
    bool success = await _ApiTerminalService.updateTerminal(
      widget.terminal.id,
      marca,
      modelo,
      serie,
      inventario,
      _selectedResponsableRP,
      _selectedResponsableNombre,
      _selectedUsuarioId!,
      _selectedArea,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Terminal y responsables actualizados correctamente"),
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
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: "Área",
                          prefixIcon:
                              const Icon(Icons.work, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                            _selectedAreaNombre = _areas.firstWhere(
                                  (a) => a['id'] == value,
                                  orElse: () => {'nom_area': 'No disponible'},
                                )['nom_area'] ??
                                'No disponible';

                            _selectedArea = _selectedAreaNombre;

                            // 🔹 Jefe de centro del área
                            final jefe = _responsables.firstWhere(
                              (r) => r['nom_area'] == _selectedArea,
                              orElse: () => {},
                            );

                            _selectedResponsableId = jefe['id'];
                            _selectedResponsableRP = jefe['rp'] ?? "";
                            _selectedResponsableNombre =
                                jefe['nombre_completo'] ?? "";

                            // 🔹 Usuarios terminales de esa área
                            _usuariosTerminal = _usuarios
                                .where((user) =>
                                    user['nom_area'] == _selectedArea &&
                                    user['es_admin'] == false)
                                .toList();

// 🔹 Agregar también al jefe de centro (si no es admin y no está duplicado)
                            final jefeCentro = _responsables.firstWhere(
                              (r) => r['nom_area'] == _selectedArea,
                              orElse: () => {},
                            );

                            if (jefeCentro.isNotEmpty &&
                                !_usuariosTerminal
                                    .any((u) => u['id'] == jefeCentro['id'])) {
                              _usuariosTerminal.add(jefeCentro);
                            }
                          });
                        },
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
                              value: _responsables.any((user) =>
                                      user['id'] == _selectedResponsableId)
                                  ? _selectedResponsableId
                                  : null, // ✅ Evita error si el ID no está en la lista
                              items: _responsables
                                  .where((usuario) =>
                                      usuario['nom_area'] == _selectedArea)
                                  .map((usuario) {
                                return DropdownMenuItem<int>(
                                  value: usuario['id'],
                                  child: Text(
                                    "${usuario['nombre_completo']} - ${usuario['nom_area']}",
                                  ),
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
                                  _selectedArea = usuario['nom_area'] ??
                                      "No disponible"; // ✅ área actualizada
                                });

                                _filtrarUsuariosPorResponsable();
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
                        value: _usuariosTerminal
                                .any((user) => user['id'] == _selectedUsuarioId)
                            ? _selectedUsuarioId
                            : null, // ✅ Evita error si el ID no está en la lista
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
