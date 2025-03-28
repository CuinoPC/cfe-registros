import 'package:cfe_registros/services/api_lector.dart';
import 'package:cfe_registros/services/api_users.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddLector extends StatefulWidget {
  const AddLector({super.key});

  @override
  State<AddLector> createState() => _AddLectorState();
}

class _AddLectorState extends State<AddLector> {
  final LectorService _apiLector = LectorService();
  final ApiUserService _apiUser = ApiUserService();

  final TextEditingController marcaController = TextEditingController();
  final TextEditingController modeloController = TextEditingController();
  final TextEditingController folioController = TextEditingController();
  final TextEditingController conectorController = TextEditingController();

  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _responsables = [];
  List<Map<String, dynamic>> _usuariosTerminal = [];
  List<Map<String, dynamic>> _areas = [];

  int? _selectedUsuarioId;
  int? _selectedAreaId;
  int? _selectedResponsableId;
  String _selectedAreaNombre = "";
  String _selectedResponsableRP = "";
  String _selectedResponsableNombre = "";
  String _areaResponsable = "";
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
    _loadAreas();
    _loadAdminStatus();
  }

  Future<void> _loadAdminStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _esAdmin = prefs.getBool('esAdmin') ?? false;
    });
  }

  Future<void> _loadAreas() async {
    final areas = await _apiUser.getAreas();
    if (areas != null) {
      setState(() {
        _areas = areas;
      });
    }
  }

  Future<void> _loadUsuarios() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool esAdmin = prefs.getBool('esAdmin') ?? false;
    bool esCentro = prefs.getBool('esCentro') ?? false;
    String currentUserRP = prefs.getString('rp') ?? "No disponible";

    print(
        "⚡ SharedPreferences -> esAdmin: $esAdmin, esCentro: $esCentro, RP Usuario: $currentUserRP");

    List<Map<String, dynamic>>? usuarios = await _apiUser.getUsers();

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
          // ✅ Si NO es admin, dejar lista vacía (se llena al seleccionar área)
          _usuariosTerminal = [];
        }
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
                user['es_admin'] == false &&
                user['nom_area'] == areaResponsable)
            .toList();

        // ✅ Incluir también al responsable si no es admin
        if (responsable['es_admin'] != true &&
            !_usuariosTerminal.any((u) => u['id'] == responsable['id'])) {
          _usuariosTerminal.add(responsable);
        }
      });
    }
  }

  Future<void> _addLector() async {
    String marca = marcaController.text;
    String modelo = modeloController.text;
    String folio = folioController.text;
    String tipoConector = conectorController.text;

    if (marca.isEmpty ||
        modelo.isEmpty ||
        folio.isEmpty ||
        tipoConector.isEmpty ||
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

    bool success = await _apiLector.createLector(
      marca,
      modelo,
      folio,
      tipoConector,
      _selectedResponsableRP,
      _selectedResponsableNombre,
      _selectedUsuarioId!,
      _selectedAreaNombre,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lector registrado exitosamente"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al registrar lector"),
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
                        'Añadir Lector',
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
                          prefixIcon: const Icon(Icons.precision_manufacturing,
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
                          prefixIcon:
                              const Icon(Icons.devices, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: folioController,
                        decoration: InputDecoration(
                          labelText: "Folio",
                          prefixIcon: const Icon(Icons.confirmation_number,
                              color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: conectorController,
                        decoration: InputDecoration(
                          labelText: "Tipo de Conector",
                          prefixIcon: const Icon(Icons.usb, color: Colors.teal),
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
                                "No disponible";

                            _areaResponsable = _selectedAreaNombre;

                            final responsablesDeArea = _responsables
                                .where((u) => u['area_id'] == value)
                                .toList();

                            _selectedResponsableId =
                                responsablesDeArea.isNotEmpty
                                    ? responsablesDeArea.first['id']
                                    : null;
                            _selectedResponsableRP =
                                responsablesDeArea.isNotEmpty
                                    ? responsablesDeArea.first['rp']
                                    : '';
                            _selectedResponsableNombre = responsablesDeArea
                                    .isNotEmpty
                                ? responsablesDeArea.first['nombre_completo']
                                : '';

                            _usuariosTerminal = _usuarios
                                .where((u) =>
                                    u['area_id'] == value &&
                                    u['es_admin'] == false &&
                                    u['es_centro'] == false)
                                .toList();
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
                              value: _selectedResponsableId,
                              items: _responsables
                                  .where((usuario) =>
                                      usuario['nom_area'] == _areaResponsable)
                                  .map((usuario) {
                                return DropdownMenuItem<int>(
                                  value: usuario['id'],
                                  child: Text(
                                      "${usuario['nombre_completo']} - ${usuario['nom_area']}"),
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
                                  _areaResponsable = usuario['nom_area'] ?? "";
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
                        onPressed: _addLector,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Guardar Lector",
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
