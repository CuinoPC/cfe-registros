import 'package:cfe_registros/models/historial.dart';
import 'package:cfe_registros/models/terminal.dart';
import 'package:cfe_registros/models/terminal_danada.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ApiTerminalService {
  final String baseUrl = "http://localhost:5000/api";

  // 🔹 Obtener terminales
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
      } else {
        print("Error: La API no devolvió una lista de terminales.");
        return null;
      }
    } else {
      return null;
    }
  }

  // 🔹 Crear una terminal
  Future<bool> createTerminal(String marca, String modelo, String serie,
      String inventario, String rpe, String nombre, int usuarioId) async {
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

  // 🔹 Actualizar una terminal
  Future<bool> updateTerminal(int id, String marca, String modelo, String serie,
      String inventario, String rpe, String nombre, int usuarioId) async {
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

  // 🔹 Eliminar una terminal
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

  // 🔹 Subir fotos de una terminal
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

  // 🔹 Obtener historial de terminales
  Future<List<HistorialRegistro>?> getHistorial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      print("Error: No hay token de autenticación.");
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/historial'),
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      try {
        var decodedJson = jsonDecode(response.body);

        if (decodedJson is List) {
          return decodedJson
              .map((json) => HistorialRegistro.fromJson(json))
              .toList();
        } else {
          print("Error: La API no devolvió una lista válida.");
          return null;
        }
      } catch (e) {
        print("Error al procesar JSON: $e");
        return null;
      }
    } else {
      print("Error al obtener historial: Código ${response.statusCode}");
      return null;
    }
  }

  Future<bool> marcarTerminalDanada(int terminalId, String marca, String modelo,
      String serie, String inventario) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // 🔹 Obtener token de autenticación

    if (token == null) {
      return false;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/terminales/danadas'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": token // 🔹 Ahora sí enviamos el token correcto
      },
      body: jsonEncode({
        "terminalId": terminalId,
        "marca": marca,
        "modelo": modelo,
        "serie": serie,
        "inventario": inventario,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }

// 🔹 Obtener terminales dañadas
  Future<List<TerminalDanada>> getTerminalesDanadas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token'); // 🔹 Obtener el token almacenado

    if (token == null) {
      return [];
    }

    final response = await http.get(
      Uri.parse("$baseUrl/terminales/danadas"),
      headers: {
        "Authorization": token, // 🔹 Enviar token en la cabecera
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TerminalDanada.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  Future<void> updateTerminalDanada(TerminalDanada terminal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // 📌 Obtener el token de autenticación

    if (token == null) {
      throw Exception("No hay token de autenticación");
    }

    final url = Uri.parse('$baseUrl/terminales/danadas/${terminal.id}');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token, // 📌 Aquí agregamos el token correctamente
      },
      body: jsonEncode({
        'fechaReporte': terminal.fechaReporte,
        'fechaGuia': terminal.fechaGuia,
        'fechaDiagnostico': terminal.fechaDiagnostico,
        'fechaAutorizacion': terminal.fechaAutorizacion,
        'fechaReparacion': terminal.fechaReparacion,
        'diasReparacion': terminal.diasReparacion,
        'costo': terminal.costo,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Error al actualizar la terminal dañada: ${response.body}');
    }
  }
}
