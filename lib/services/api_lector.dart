import 'dart:convert';
import 'package:cfe_registros/models/lector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class LectorService {
  final String baseUrl = "http://localhost:5000/api";

  Future<List<Lector>?> getLectores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/lectores'),
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      var decodedJson = jsonDecode(response.body);
      if (decodedJson is List) {
        return decodedJson.map((json) => Lector.fromJson(json)).toList();
      }
    }
    return null;
  }

  Future<bool> createLector(
    String marca,
    String modelo,
    String folio,
    String tipoConector,
    String rpe,
    String nombre,
    int usuarioId,
    String area,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? nombreUsuario = prefs.getString('nombre_usuario');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/lectores'),
      headers: {"Content-Type": "application/json", "Authorization": token},
      body: jsonEncode({
        "marca": marca,
        "modelo": modelo,
        "folio": folio,
        "tipo_conector": tipoConector,
        "rpe_responsable": rpe,
        "nombre_responsable": nombre,
        "usuario_id": usuarioId,
        "area": area,
        "realizado_por": nombreUsuario ?? "Desconocido"
      }),
    );

    return response.statusCode == 201;
  }

  Future<bool> updateLector(
    int id,
    String marca,
    String modelo,
    String folio,
    String tipoConector,
    String rpe,
    String nombre,
    int usuarioId,
    String area,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? nombreUsuario = prefs.getString('nombre_usuario');
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/lectores/$id'),
      headers: {"Content-Type": "application/json", "Authorization": token},
      body: jsonEncode({
        "marca": marca,
        "modelo": modelo,
        "folio": folio,
        "tipo_conector": tipoConector,
        "rpe_responsable": rpe,
        "nombre_responsable": nombre,
        "usuario_id": usuarioId,
        "area": area,
        "realizado_por": nombreUsuario ?? "Desconocido"
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteLector(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/lectores/$id'),
      headers: {"Content-Type": "application/json", "Authorization": token},
    );

    return response.statusCode == 200;
  }

  Future<bool> uploadLectorPhotos(int lectorId, List<XFile> photos) async {
    try {
      var uri = Uri.parse("$baseUrl/lectores/upload");
      var request = http.MultipartRequest('POST', uri);
      request.fields['lectorId'] = lectorId.toString();

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

  Future<List<Lector>> getLectoresPorArea(String area) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/lectores/area/$area'),
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      var decodedJson = jsonDecode(response.body);
      if (decodedJson == null || decodedJson.isEmpty) return [];

      return decodedJson.map<Lector>((json) => Lector.fromJson(json)).toList();
    } else {
      return [];
    }
  }
}
