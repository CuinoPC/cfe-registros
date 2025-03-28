import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SupervisionLectorService {
  final String baseUrl = "http://localhost:5000/api";

  Future<bool> saveSupervisionData(Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl//lectores/supervision'),
      headers: {"Content-Type": "application/json", "Authorization": token},
      body: jsonEncode(data),
    );

    return response.statusCode == 201;
  }

  Future<bool> updateSupervisionData(
      int lectorId, String field, dynamic value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.put(
      Uri.parse("$baseUrl/lectores/supervision/update"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": token,
      },
      body: jsonEncode({
        "lector_id": lectorId,
        "field": field,
        "value": value,
      }),
    );

    return response.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> getHistorialSupervision(
      int lectorId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/lectores/supervision/historial/$lectorId'),
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSupervisionesPorArea(
      String area) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/lectores/supervision/area/$area'),
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }
}
