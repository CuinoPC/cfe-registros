import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PiezasTPSService {
  final String baseUrl = "http://localhost:5000/api";

  Future<List<Map<String, dynamic>>> getPiezasTPS() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/piezas'),
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }

  Future<bool> updatePiezaTPS(int id, String nombre, double costo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/piezas/$id'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": token,
      },
      body: jsonEncode({
        "nombre_pieza": nombre,
        "costo": costo,
      }),
    );

    return response.statusCode == 200;
  }
}
