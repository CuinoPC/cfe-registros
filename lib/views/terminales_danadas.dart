import 'package:cfe_registros/models/terminal_danada.dart';
import 'package:cfe_registros/services/api_terminales.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 📌 Importamos para formatear fechas
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    List<TerminalDanada> terminales = await _apiService.getTerminalesDanadas();
    setState(() {
      _terminalesDanadas = terminales;
      _isLoading = false;
    });
  }

  /// 📌 Método para abrir el DatePicker y actualizar la fecha en `dd/MM/yyyy`
  Future<void> _selectDate(
      BuildContext context, TerminalDanada terminal, String field) async {
    DateTime initialDate = DateTime.now();

    if (terminal.toMap()[field] != null &&
        terminal.toMap()[field]!.isNotEmpty) {
      try {
        initialDate = DateTime.parse(terminal.toMap()[field]!);
      } catch (e) {
        print("Error al parsear fecha: $e");
      }
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd')
          .format(picked); // ✅ Guardamos en la BD como YYYY-MM-DD

      setState(() {
        switch (field) {
          case 'fechaReporte':
            terminal.fechaReporte = formattedDate;
            break;
          case 'fechaGuia':
            terminal.fechaGuia = formattedDate;
            break;
          case 'fechaDiagnostico':
            terminal.fechaDiagnostico = formattedDate;
            break;
          case 'fechaAutorizacion':
            terminal.fechaAutorizacion = formattedDate;
            break;
          case 'fechaReparacion':
            terminal.fechaReparacion = formattedDate;
            break;
        }
      });

      print("Fecha seleccionada ($field): $formattedDate");

      // ✅ Enviar actualización al backend
      await _apiService.updateTerminalDanada(terminal);

      // ✅ Guardar la reparación en SharedPreferences para que TerminalList lo desmarque
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'terminal_reparada_${terminal.serie}', formattedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _terminalesDanadas.isEmpty
              ? const Center(child: Text("No hay terminales dañadas."))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 1200,
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.teal.shade100),
                    border: TableBorder.all(color: Colors.grey),
                    columns: const [
                      DataColumn(
                          label: Text("#")), // 📌 Nueva columna para numeración
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
                    rows: List.generate(_terminalesDanadas.length, (index) {
                      final terminal = _terminalesDanadas[index];
                      return DataRow(cells: [
                        DataCell(
                            Text("${index + 1}")), // 📌 Numeración de filas
                        DataCell(Text(terminal.marca)),
                        DataCell(Text(terminal.modelo)),
                        DataCell(Text(terminal.serie)),

                        /// 📌 Casillas editables de fechas con DatePicker e ícono de calendario
                        _buildEditableDateCell(terminal, "fechaReporte"),
                        _buildEditableDateCell(terminal, "fechaGuia"),
                        _buildEditableDateCell(terminal, "fechaDiagnostico"),
                        _buildEditableDateCell(terminal, "fechaAutorizacion"),
                        _buildEditableDateCell(terminal, "fechaReparacion"),

                        /// 📌 Casilla editable para "Días de Reparación"
                        _buildEditableNumberCell(terminal, "diasReparacion"),

                        /// 📌 Casilla editable para "Costo"
                        _buildEditableNumberCell(terminal, "costo"),
                      ]);
                    }),
                  ),
                ),
    );
  }

  /// 📌 Widget para las celdas editables de Fecha (con DatePicker + Ícono de Calendario)
  DataCell _buildEditableDateCell(TerminalDanada terminal, String field) {
    String? fecha = terminal.toMap()[field];

    // 📌 Convertimos de `YYYY-MM-DDTHH:MM:SSZ` a `DD/MM/YYYY`
    String formattedFecha = fecha != null && fecha.isNotEmpty
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha))
        : "Seleccionar";

    return DataCell(
      InkWell(
        onTap: () => _selectDate(context, terminal, field),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.teal),
            const SizedBox(width: 5),
            Text(
              formattedFecha,
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📌 Widget para las celdas editables de Números (Días y Costo)
  DataCell _buildEditableNumberCell(TerminalDanada terminal, String field) {
    return DataCell(
      TextFormField(
        initialValue: terminal.toMap()[field]?.toString() ?? "",
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {
            if (field == "diasReparacion") {
              terminal.diasReparacion = int.tryParse(value) ?? 0;
            } else if (field == "costo") {
              terminal.costo = double.tryParse(value) ?? 0.0;
            }
          });
        },
        onFieldSubmitted: (value) {
          _apiService.updateTerminalDanada(terminal);
        },
      ),
    );
  }
}
