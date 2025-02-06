import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../views/login_page.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize =>
      Size.fromHeight(80); // 🔹 Aumenta la altura del AppBar
}

class _CustomAppBarState extends State<CustomAppBar> {
  String _nombreUsuario = "";
  int _rp = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreUsuario = prefs.getString('nombre_usuario') ?? "Desconocido";
      _rp = prefs.getInt('rp') ?? 0;
    });
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Eliminar datos de sesión

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false, // Elimina todas las rutas previas
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.teal,
      toolbarHeight: 80, // 🔹 Ajusta la altura del AppBar
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🔹 Logo de CFE dentro de un SizedBox para asegurar el tamaño
          SizedBox(
            width: 150, // 🔹 Ancho más grande
            height: 70, // 🔹 Altura más grande
            child: Image.network(
              'https://i.postimg.cc/MGpN8QmY/logo-CFE-DISTRIBUCI-N-1.png',
              fit: BoxFit.contain,
              color: Colors.teal, // 🔹 Mezcla el color con el fondo
              colorBlendMode:
                  BlendMode.multiply, // 🔹 Intenta eliminar el fondo blanco
            ),
          ),
          Spacer(), // 🔹 Empuja el usuario y RP a la derecha
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _nombreUsuario,
                style: TextStyle(
                    fontSize: 18, // 🔹 Letra más grande
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                "RP: $_rp",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
          SizedBox(width: 10),
          Icon(Icons.account_circle,
              color: Colors.white, size: 35), // 🔹 Ícono más grande
          SizedBox(width: 20),
          IconButton(
            icon: Icon(Icons.logout,
                color: Colors.white, size: 30), // 🔹 Botón más grande
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
