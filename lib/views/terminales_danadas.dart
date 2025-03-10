import 'package:cfe_registros/models/terminal_danada.dart';
import 'package:cfe_registros/services/api_terminales.dart';
import 'package:flutter/material.dart';
import '../models/terminal.dart';

class TerminalesDanadasPage extends StatefulWidget {
  final List<Terminal> terminalesDanadas;

  TerminalesDanadasPage({required this.terminalesDanadas});

  @override
  _TerminalesDanadasPageState createState() => _TerminalesDanadasPageState();
}

class _TerminalesDanadasPageState extends State<TerminalesDanadasPage> {
  List<TerminalDanada> _terminalesDanadas = [];
  final ApiTerminalService _apiService = ApiTerminalService();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    List<TerminalDanada> terminales = await _apiService.getTerminalesDanadas();
    setState(() {
      _terminalesDanadas = terminales;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Terminales Dañadas")),
      body: _terminalesDanadas.isEmpty
          ? Center(child: Text("No hay terminales dañadas."))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("Marca")),
                  DataColumn(label: Text("Modelo")),
                  DataColumn(label: Text("Serie")),
                  DataColumn(label: Text("Fecha Reporte")),
                  DataColumn(label: Text("Fecha Guía")),
                  DataColumn(label: Text("Fecha Diagnóstico")),
                  DataColumn(label: Text("Fecha Autorización")),
                  DataColumn(label: Text("Fecha Reparación")),
                  DataColumn(label: Text("Días de Reparación")),
                  DataColumn(label: Text("Costo")),
                ],
                rows: _terminalesDanadas.map((terminal) {
                  return DataRow(cells: [
                    DataCell(Text(terminal.marca)),
                    DataCell(Text(terminal.modelo)),
                    DataCell(Text(terminal.serie)),
                    DataCell(Text(terminal.fechaReporte ?? "-")),
                    DataCell(Text(terminal.fechaGuia ?? "-")),
                    DataCell(Text(terminal.fechaDiagnostico ?? "-")),
                    DataCell(Text(terminal.fechaAutorizacion ?? "-")),
                    DataCell(Text(terminal.fechaReparacion ?? "-")),
                    DataCell(Text(terminal.diasReparacion)),
                    DataCell(Text(terminal.costo)),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}
