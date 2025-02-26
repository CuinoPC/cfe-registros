import 'package:cfe_registros/services/api_terminales.dart';
import 'package:cfe_registros/services/api_users.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController rpeController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();

  List<Map<String, dynamic>> _usuarios = [];
  List<Terminal> _terminales = [];
  int? _selectedUsuarioId;
  String _selectedArea = ""; // ✅ Nueva variable para el área del usuario

  @override
  void initState() {
    super.initState();
    marcaController.text = widget.terminal.marca;
    modeloController.text = widget.terminal.modelo;
    serieController.text = widget.terminal.serie;
    inventarioController.text = widget.terminal.inventario;
    rpeController.text = widget.terminal.rpeResponsable.toString();
    nombreController.text = widget.terminal.nombreResponsable;
    _selectedUsuarioId = widget.terminal.usuarioId;

    _loadUsuariosYTerminales();
  }

  // 🔹 Obtener lista de usuarios y terminales
  Future<void> _loadUsuariosYTerminales() async {
    List<Map<String, dynamic>>? usuarios = await _ApiUserService.getUsers();
    List<Terminal>? terminales = await _ApiTerminalService.getTerminales();

    if (usuarios != null && terminales != null) {
      setState(() {
        _usuarios = usuarios;
        _terminales = terminales;
        _selectedArea = _getAreaUsuario(widget.terminal.usuarioId);
      });
    }
  }

  // 🔹 Obtener el área del usuario
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
    String rpe = rpeController.text;
    String nombre = nombreController.text;

    if (marca.isEmpty ||
        serie.isEmpty ||
        inventario.isEmpty ||
        rpe.isEmpty ||
        nombre.isEmpty ||
        _selectedUsuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Todos los campos son obligatorios"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // ✅ 1. Actualizar la terminal seleccionada
    bool success = await _ApiTerminalService.updateTerminal(
      widget.terminal.id,
      marca,
      modelo,
      serie,
      inventario,
      rpe,
      nombre,
      _selectedUsuarioId!,
    );

    if (success) {
      // ✅ 2. Filtrar terminales con el mismo área
      List<Terminal> terminalesRelacionadas = _terminales.where((terminal) {
        return _getAreaUsuario(terminal.usuarioId) == _selectedArea;
      }).toList();

      // ✅ 3. Actualizar todas las terminales con el nuevo RPE y Nombre
      for (var terminal in terminalesRelacionadas) {
        await _ApiTerminalService.updateTerminal(
          terminal.id,
          terminal.marca,
          terminal.modelo,
          terminal.serie,
          terminal.inventario,
          rpe, // Nuevo RPE
          nombre, // Nuevo Nombre Responsable
          terminal.usuarioId,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terminal y terminales relacionadas actualizadas"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al actualizar terminal"),
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
                      TextFormField(
                        controller: rpeController,
                        decoration: InputDecoration(
                          labelText: "RPE Responsable",
                          prefixIcon:
                              const Icon(Icons.badge, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nombreController,
                        decoration: InputDecoration(
                          labelText: "Nombre Responsable",
                          prefixIcon:
                              const Icon(Icons.person, color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: "Seleccionar Usuario",
                          prefixIcon: const Icon(Icons.supervisor_account,
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
