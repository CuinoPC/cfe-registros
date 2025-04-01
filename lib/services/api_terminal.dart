import 'dart:convert';
import 'package:cfe_registros/models/terminal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class TerminalService {
  final String baseUrl = "http://localhost:5000/api";

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
      if (decodedJson is List) {
        return decodedJson.map((json) => Terminal.fromJson(json)).toList();
      }
    }
    return null;
  }

  Future<bool> createTerminal(
      String marca,
      String modelo,
      String serie,
      String inventario,
      String rpe,
      String nombre,
      int usuarioId,
      String area) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? nombreUsuario = prefs.getString('nombre_usuario');
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
        "usuario_id": usuarioId,
        "area": area,
        "realizado_por": nombreUsuario ?? "Desconocido"
      }),
    );

    return response.statusCode == 201;
  }

  Future<bool> updateTerminal(
      int id,
      String marca,
      String modelo,
      String serie,
      String inventario,
      String rpe,
      String nombre,
      int usuarioId,
      String area) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? nombreUsuario = prefs.getString('nombre_usuario');
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
        "usuario_id": usuarioId,
        "area": area,
        "realizado_por": nombreUsuario ?? "Desconocido"
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
          var bytes = await photo.readAsBytes();
          var multipartFile = http.MultipartFile.fromBytes(
            'photos',
            bytes,
            filename: photo.name,
          );
          request.files.add(multipartFile);
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'photos',
            photo.path,
          ));
        }
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

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

  Future<List<Terminal>> getTerminalesPorArea(String area) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/terminales/area/$area'),
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      var decodedJson = jsonDecode(response.body);
      if (decodedJson == null || decodedJson.isEmpty) return [];

      return decodedJson
          .map<Terminal>((json) => Terminal.fromJson(json))
          .toList();
    } else {
      return [];
    }
  }

  Future<List<String>> getMarcasTerminales() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/terminales/marcas'),
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .map<String>((m) => m['marca']?.toString() ?? '')
            .toList();
      }
    }

    return [];
  }
}
