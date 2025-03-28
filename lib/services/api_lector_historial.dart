import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cfe_registros/models/lector_historial.dart';

class HistorialLectorService {
  final String baseUrl = "http://localhost:5000/api";

  Future<List<HistorialLector>?> getHistorialLectores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/lectores/historial'),
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      var decodedJson = jsonDecode(response.body);
      if (decodedJson is List) {
        return decodedJson
            .map((json) => HistorialLector.fromJson(json))
            .toList();
      }
    }
    return null;
  }
}
