import 'package:cfe_registros/models/terminal.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
      await prefs.setString('nombre_usuario', data['nombre_completo']);
      await prefs.setInt('rp', int.tryParse(data['rp'].toString()) ?? 0);
      return data;
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
      users = users.map((user) {
        return {...user, "es_admin": user["es_admin"] == true};
      }).toList();
      return users;
    } else {
      return null;
    }
  }

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

  Future<List<Terminal>?> getTerminales() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/terminales'),
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      var decodedJson = jsonDecode(response.body);

      // ✅ Asegurar que 'decodedJson' es una lista antes de mapear
      if (decodedJson is List) {
        return decodedJson.map((json) => Terminal.fromJson(json)).toList();
      } else {
        print("Error: La API no devolvió una lista de terminales.");
        return null;
      }
    } else {
      return null;
    }
  }

  Future<bool> createTerminal(String marca, String modelo, String serie,
      String inventario, int rpe, String nombre, int usuarioId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/terminales'),
      headers: {"Content-Type": "application/json", "Authorization": token},
      body: jsonEncode({
        "marca": marca,
        "modelo": modelo,
        "serie": serie,
        "inventario": inventario,
        "rpe_responsable": rpe,
        "nombre_responsable": nombre,
        "usuario_id": usuarioId
      }),
    );

    return response.statusCode == 201;
  }

  Future<bool> updateTerminal(int id, String marca, String modelo, String serie,
      String inventario, int rpe, String nombre, int usuarioId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/terminales/$id'),
      headers: {"Content-Type": "application/json", "Authorization": token},
      body: jsonEncode({
        "marca": marca,
        "modelo": modelo,
        "serie": serie,
        "inventario": inventario,
        "rpe_responsable": rpe,
        "nombre_responsable": nombre,
        "usuario_id": usuarioId
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteTerminal(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/terminales/$id'),
      headers: {"Content-Type": "application/json", "Authorization": token},
    );

    return response.statusCode == 200;
  }

  Future<bool> uploadTerminalPhotos(int terminalId, List<XFile> photos) async {
    try {
      var uri = Uri.parse("$baseUrl/terminales/upload");
      var request = http.MultipartRequest('POST', uri);
      request.fields['terminalId'] = terminalId.toString();

      for (var photo in photos) {
        if (kIsWeb) {
          // ✅ Flutter Web: Usa `bytes` en lugar de `File`
          var bytes = await photo.readAsBytes();
          var multipartFile = http.MultipartFile.fromBytes(
            'photos',
            bytes,
            filename: photo.name,
          );
          request.files.add(multipartFile);
        } else {
          // ✅ Dispositivos móviles: Usa `File`
          request.files.add(await http.MultipartFile.fromPath(
            'photos',
            photo.path,
          ));
        }
      }

      var response = await request.send();
      var responseBody =
          await response.stream.bytesToString(); // ✅ Obtener respuesta

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Fotos subidas correctamente: $responseBody");
        return true;
      } else {
        print("Error en la subida de fotos: $responseBody");
        return false;
      }
    } catch (e) {
      print("Error en la subida de fotos: $e");
      return false;
    }
  }
}
