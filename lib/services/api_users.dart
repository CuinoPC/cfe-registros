import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiUserService {
  final String baseUrl = "https://cfe-registros-backend.onrender.com/api";

  // 🔹 Inicio de sesión
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
      await prefs.setString('nombre_usuario', data['nombre_completo']);
      await prefs.setInt('rp', int.tryParse(data['rp'].toString()) ?? 0);
      return data;
    } else {
      return null;
    }
  }

  // 🔹 Obtener usuarios
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
      users = users.map((user) {
        return {...user, "es_admin": user["es_admin"] == true};
      }).toList();
      return users;
    } else {
      return null;
    }
  }

  // 🔹 Crear usuario
  Future<bool> createUser(String nombre, int rp, int areaId, String contrasenia,
      bool esAdmin) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {"Content-Type": "application/json", "Authorization": token},
      body: jsonEncode({
        "nombre_completo": nombre,
        "rp": rp,
        "area_id": areaId,
        "contrasenia": contrasenia,
        "es_admin": esAdmin
      }),
    );

    return response.statusCode == 201;
  }

  // 🔹 Actualizar usuario
  Future<bool> updateUser(int rp, String nombre, int areaId, String contrasenia,
      bool esAdmin) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/users/$rp'),
      headers: {"Content-Type": "application/json", "Authorization": token},
      body: jsonEncode({
        "nombre_completo": nombre,
        "area_id": areaId,
        "contrasenia": contrasenia,
        "es_admin": esAdmin
      }),
    );

    return response.statusCode == 200;
  }

  // 🔹 Eliminar usuario
  Future<bool> deleteUser(int rp) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/users/$rp'),
      headers: {"Content-Type": "application/json", "Authorization": token},
    );

    return response.statusCode == 200;
  }

  // 🔹 Obtener áreas
  Future<List<Map<String, dynamic>>?> getAreas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/areas'),
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      return null;
    }
  }
}
