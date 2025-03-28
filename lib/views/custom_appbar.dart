import 'package:cfe_registros/views/lector_list.dart';
import 'package:cfe_registros/views/lectores_danados.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../views/login_page.dart';
import '../views/user_list.dart';
import '../views/terminal_list.dart';
import '../views/terminales_danadas.dart';
import '../views/reporte_supervision.dart'; // ✅ Importar la nueva pantalla
import 'home_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(80);
}

class _CustomAppBarState extends State<CustomAppBar> {
  String _nombreUsuario = "";
  String _rp = "";
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreUsuario = prefs.getString('nombre_usuario') ?? "Desconocido";
      _rp = prefs.getString('rp') ?? "Desconocido";
      _esAdmin = prefs.getBool('esAdmin') ?? false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.green.shade300,
      toolbarHeight: 80,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 70,
                child: Image.asset(
                  'assets/logoCFE.png',
                  fit: BoxFit.contain,
                  color: Colors.green.shade300,
                  colorBlendMode: BlendMode.multiply,
                ),
              ),
              const SizedBox(width: 20),
              _buildNavItem(context, "Inicio"),
              _buildDropdownMenu(context), // ✅ Menú desplegable mejorado
              _buildLectoresDropdownMenu(context),
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _nombreUsuario,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  Text(
                    "RP: $_rp",
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              const Icon(Icons.account_circle, color: Colors.black87, size: 35),
              const SizedBox(width: 20),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black87),
                onSelected: (value) {
                  if (value == "logout") {
                    _logout(context);
                  } else if (value == "admin" && _esAdmin) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserList()),
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    if (_esAdmin)
                      const PopupMenuItem<String>(
                        value: "admin",
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings,
                                color: Colors.teal),
                            SizedBox(width: 10),
                            Text("Administrar Usuarios"),
                          ],
                        ),
                      ),
                    const PopupMenuItem<String>(
                      value: "logout",
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 10),
                          Text("Cerrar Sesión"),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔹 Método para la navegación en el menú normal
  Widget _buildNavItem(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: GestureDetector(
        onTap: () {
          if (title == "Inicio") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Navegando a $title")),
            );
          }
        },
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  /// 🔹 Menú desplegable para Lectores Ópticos
  Widget _buildLectoresDropdownMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String? newValue) {
        if (newValue == "Lista de Lectores") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LectorList()),
          );
        } else if (newValue == "Lectores Dañados") {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LectoresDanadosPage(
                      lectoresDanados: [],
                    )),
          );
        }
      },
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: "Lista de Lectores",
          child: ListTile(
            leading: Icon(Icons.qr_code_2, color: Colors.deepPurple.shade400),
            title: const Text("Lista de Lectores"),
          ),
        ),
        const PopupMenuItem(
          value: "Lectores Dañados",
          child: ListTile(
            leading: Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            title: Text("Lectores Dañados"),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade400,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Text(
              "Lectores Ópticos",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 5),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  /// 🔹 Método para el menú desplegable profesional
  Widget _buildDropdownMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String? newValue) {
        if (newValue == "Lista de Terminales") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TerminalList()),
          );
        } else if (newValue == "Terminales Dañadas") {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    TerminalesDanadasPage(terminalesDanadas: [])),
          );
        } else if (newValue == "Reporte de Supervisión") {
          // ✅ Nueva opción agregada
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReporteSupervision()),
          );
        }
      },
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: "Lista de Terminales",
          child: ListTile(
            leading: Icon(Icons.devices_other, color: Colors.green.shade700),
            title: const Text("Lista de Terminales"),
          ),
        ),
        const PopupMenuItem(
          value: "Terminales Dañadas",
          child: ListTile(
            leading: Icon(Icons.warning, color: Colors.redAccent),
            title: Text("Terminales Dañadas"),
          ),
        ),
        const PopupMenuItem(
          // ✅ Nueva opción agregada
          value: "Reporte de Supervisión",
          child: ListTile(
            leading: Icon(Icons.assignment, color: Colors.blueAccent),
            title: Text("Reporte de Supervisión"),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade500,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Text(
              "TPS",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 5),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
