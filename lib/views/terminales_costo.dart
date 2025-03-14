import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/terminal_danada.dart';
import '../services/api_terminales.dart';

class CostosTerminalesPage extends StatefulWidget {
  @override
  _CostosTerminalesPageState createState() => _CostosTerminalesPageState();
}

class _CostosTerminalesPageState extends State<CostosTerminalesPage> {
  final ApiTerminalService _apiService = ApiTerminalService();
  List<TerminalDanada> _terminalesFiltradas = [];
  String _searchQuery = "";
  double _totalCost = 0.0;
  bool _isLoading = false;

  /// 🔍 **Filtrar la lista según el número de serie**
  void _buscarTerminales(String query) async {
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    List<TerminalDanada> terminales = await _apiService.getTerminalesDanadas();
    List<TerminalDanada> filtradas =
        terminales.where((t) => t.serie == query).toList();

    double totalCosto =
        filtradas.fold(0.0, (sum, item) => sum + (item.costo ?? 0.0));

    setState(() {
      _terminalesFiltradas = filtradas;
      _totalCost = totalCosto;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: _buscarTerminales,
              decoration: InputDecoration(
                labelText: "Buscar por número de serie",
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.teal.shade50,
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_searchQuery.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 80, color: Colors.grey.shade500),
                      const SizedBox(height: 10),
                      const Text(
                        "Ingrese un número de serie para buscar terminales dañadas.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_terminalesFiltradas.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 80, color: Colors.grey.shade500),
                      const SizedBox(height: 10),
                      const Text(
                        "No se encontraron terminales con ese número de serie.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 800,
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.teal.shade100),
                    border: TableBorder.all(color: Colors.grey),
                    columns: const [
                      DataColumn(label: Text("Serie")),
                      DataColumn(label: Text("Marca")),
                      DataColumn(label: Text("Modelo")),
                      DataColumn(label: Text("Costo")),
                    ],
                    rows: _terminalesFiltradas.map((terminal) {
                      return DataRow(cells: [
                        DataCell(Text(terminal.serie)),
                        DataCell(Text(terminal.marca)),
                        DataCell(Text(terminal.modelo)),
                        DataCell(Text(
                            "\$${terminal.costo?.toStringAsFixed(2) ?? '0.00'}")),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Costo Total: \$${_totalCost.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
