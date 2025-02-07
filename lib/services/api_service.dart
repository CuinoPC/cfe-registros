import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "http://localhost:5000/api";

  Future<Map<String, dynamic>?> login(int rp, String contrasenia) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"rp": rp, "contrasenia": contrasenia}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setBool('esAdmin', data['es_admin'] == true);

      // 🔹 Guardar nombre y RP en SharedPreferences
      await prefs.setString('nombre_usuario', data['nombre_completo']);
      await prefs.setInt('rp', int.tryParse(data['rp'].toString()) ?? 0);

      return data; // 🔹 Ahora devuelve toda la información
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      List<Map<String, dynamic>> users =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));

      // Asegurar que es_admin sea interpretado como booleano
      users = users.map((user) {
        return {
          ...user,
          "es_admin": user["es_admin"] == true // Convierte 1 a true y 0 a false
        };
      }).toList();

      return users;
    } else {
      return null;
    }
  }

  Future<bool> createUser(String nombre, int rp, String area,
      String contrasenia, bool esAdmin) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {"Content-Type": "application/json", "Authorization": token},
      body: jsonEncode({
        "nombre_completo": nombre,
        "rp": rp,
        "area": area,
        "contrasenia": contrasenia,
        "es_admin": esAdmin
      }),
    );

    return response.statusCode == 201;
  }

  Future<bool> updateUser(int rp, String nombre, String area,
      String contrasenia, bool esAdmin) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/users/$rp'), // ✅ RP anterior en la URL
      headers: {"Content-Type": "application/json", "Authorization": token},
      body: jsonEncode({
        "rp": rp, // ✅ Nuevo RP en el cuerpo de la solicitud
        "nombre_completo": nombre,
        "area": area,
        "contrasenia": contrasenia,
        "es_admin": esAdmin
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteUser(int rp) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return false; // 🔹 Retorna false si no hay token

    final response = await http.delete(
      Uri.parse('$baseUrl/users/$rp'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": token // ✅ Se añade el token
      },
    );

    return response.statusCode == 200;
  }
}
