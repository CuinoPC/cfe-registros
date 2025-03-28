import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SupervisionHoneywellService {
  final String baseUrl = "http://localhost:5000/api";

  // ✅ Guardar supervisión Honeywell
  Future<bool> saveHoneywellSupervision(Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/supervision-honeywell'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": token,
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 201;
  }

  // ✅ Actualizar campo específico Honeywell
  Future<bool> updateHoneywellField(
      int terminalId, String field, dynamic value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/supervision-honeywell/update'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": token,
      },
      body: jsonEncode({
        "terminal_id": terminalId,
        "field": field,
        "value": value,
      }),
    );

    return response.statusCode == 200;
  }

  // ✅ Obtener historial Honeywell por terminal
  Future<List<Map<String, dynamic>>> getHoneywellHistorial(
      int terminalId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/supervision-honeywell/historial/$terminalId'),
      headers: {
        "Authorization": token,
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }

  // ✅ Obtener supervisiones Honeywell por área
  Future<List<Map<String, dynamic>>> getHoneywellSupervisionesByArea(
      String area) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/supervision-honeywell/area/$area'),
      headers: {
        "Authorization": token,
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }
}
