import 'dart:convert';
import 'dart:typed_data';
import 'package:cfe_registros/models/lector_danado.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class LectorDanadoService {
  final String baseUrl = "http://localhost:5000/api";

  Future<bool> marcarLectorDanado(int lectorId, String marca, String modelo,
      String area, String folio, String tipoConector) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/lectores/danados'),
      headers: {"Content-Type": "application/json", "Authorization": token},
      body: jsonEncode({
        "lectorId": lectorId,
        "marca": marca,
        "modelo": modelo,
        "area": area,
        "folio": folio,
        "tipo_conector": tipoConector,
      }),
    );

    return response.statusCode == 201;
  }

  Future<List<LectorDanado>> getLectoresDanados() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse("$baseUrl/lectores/danados"),
      headers: {"Authorization": token},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LectorDanado.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  Future<void> updateLectorDanado(LectorDanado lector) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) throw Exception("No hay token de autenticación");

    final url = Uri.parse('$baseUrl/lectores/danados/${lector.id}');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode({
        'fechaReporte': lector.fechaReporte,
        'fechaGuia': lector.fechaGuia,
        'fechaDiagnostico': lector.fechaDiagnostico,
        'fechaAutorizacion': lector.fechaAutorizacion,
        'fechaReparacion': lector.fechaReparacion,
        'diasReparacion': lector.diasReparacion,
        'costo': lector.costo,
        'piezasReparadas': lector.piezasReparadas,
        'observaciones': lector.observaciones,
        'ticket': lector.ticket,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar: ${response.body}');
    }
  }

  Future<bool> subirArchivoPDF(
      int id, Uint8List archivoBytes, String nombreArchivo) async {
    try {
      final uri = Uri.parse('$baseUrl/lectores/danados/$id/pdf');
      final request = http.MultipartRequest('POST', uri);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      request.headers['Authorization'] = token;

      request.files.add(http.MultipartFile.fromBytes(
        'archivo',
        archivoBytes,
        filename: nombreArchivo,
        contentType: MediaType('application', 'pdf'),
      ));

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print("Error al subir archivo PDF: $e");
      return false;
    }
  }
}
