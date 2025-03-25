import 'dart:convert';
import 'dart:typed_data';
import 'package:cfe_registros/models/terminal_danada.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class TerminalDanadaService {
  final String baseUrl = "http://localhost:5000/api";

  Future<bool> marcarTerminalDanada(int terminalId, String marca, String modelo,
      String area, String serie, String inventario) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/terminales/danadas'),
      headers: {"Content-Type": "application/json", "Authorization": token},
      body: jsonEncode({
        "terminalId": terminalId,
        "marca": marca,
        "modelo": modelo,
        "area": area,
        "serie": serie,
        "inventario": inventario,
      }),
    );

    return response.statusCode == 201;
  }

  Future<List<TerminalDanada>> getTerminalesDanadas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse("$baseUrl/terminales/danadas"),
      headers: {"Authorization": token},
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
    String? token = prefs.getString('token');
    if (token == null) throw Exception("No hay token de autenticación");

    final url = Uri.parse('$baseUrl/terminales/danadas/${terminal.id}');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode({
        'fechaReporte': terminal.fechaReporte,
        'fechaGuia': terminal.fechaGuia,
        'fechaDiagnostico': terminal.fechaDiagnostico,
        'fechaAutorizacion': terminal.fechaAutorizacion,
        'fechaReparacion': terminal.fechaReparacion,
        'diasReparacion': terminal.diasReparacion,
        'costo': terminal.costo,
        'piezasReparadas': terminal.piezasReparadas,
        'observaciones': terminal.observaciones,
        'ticket': terminal.ticket,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar: ${response.body}');
    }
  }

  Future<bool> subirArchivoPDF(
      int id, Uint8List archivoBytes, String nombreArchivo) async {
    try {
      final uri = Uri.parse('$baseUrl/terminales/danadas/$id/pdf');
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
