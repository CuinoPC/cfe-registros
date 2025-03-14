import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../views/login_page.dart';
import '../views/user_list.dart';
import '../views/terminal_list.dart';
import '../views/terminales_danadas.dart'; // ✅ Importar la nueva pantalla
import 'home_screen.dart'; // ✅ Importa AdminDashboard

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
                child: Image.network(
                  'https://i.postimg.cc/MGpN8QmY/logo-CFE-DISTRIBUCI-N-1.png',
                  fit: BoxFit.contain,
                  color: Colors.green.shade300,
                  colorBlendMode: BlendMode.multiply,
                ),
              ),
              const SizedBox(width: 20),
              _buildNavItem(context, "Inicio"),
              _buildDropdownMenu(context), // ✅ Menú desplegable mejorado
              _buildNavItem(context, "Lectores Ópticos"),
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
        PopupMenuItem(
          value: "Terminales Dañadas",
          child: ListTile(
            leading: Icon(Icons.warning, color: Colors.redAccent),
            title: const Text("Terminales Dañadas"),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade500,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Text(
              "TPS",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
