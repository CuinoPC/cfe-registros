import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
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
  Map<int, double> _costosPorAno = {}; // 🔹 Costos agrupados por año

  /// 🔍 **Filtrar la lista según el número de serie o inventario y calcular costos por año**
  void _buscarTerminales(String query) async {
    setState(() {
      _isLoading = true;
      _searchQuery = query.trim();
    });

    List<TerminalDanada> terminales = await _apiService.getTerminalesDanadas();

    // 🔹 Filtrar terminales que coincidan exactamente con el número de serie o inventario
    List<TerminalDanada> filtradas = terminales.where((t) {
      return t.serie.trim().toLowerCase() == _searchQuery.toLowerCase() ||
          t.inventario.trim().toLowerCase() == _searchQuery.toLowerCase();
    }).toList();

    // 🔹 Agrupar costos por año
    Map<int, double> costosPorAno = {};
    double costoTotal = 0.0;

    for (var terminal in filtradas) {
      if (terminal.fechaReparacion != null && terminal.costo != null) {
        DateTime fecha = DateTime.parse(terminal.fechaReparacion!);
        int anio = fecha.year;

        costosPorAno.update(anio, (value) => value + terminal.costo!,
            ifAbsent: () => terminal.costo!);

        costoTotal += terminal.costo!;
      }
    }

    // 🔹 Ordenar por fecha de reparación (más recientes primero)
    filtradas.sort((a, b) {
      DateTime? fechaA =
          a.fechaReparacion != null ? DateTime.parse(a.fechaReparacion!) : null;
      DateTime? fechaB =
          b.fechaReparacion != null ? DateTime.parse(b.fechaReparacion!) : null;

      if (fechaA == null && fechaB == null) return 0;
      if (fechaA == null) return 1; // ✅ Los que no tienen fecha van al final
      if (fechaB == null) return -1;
      return fechaB
          .compareTo(fechaA); // ✅ Orden descendente (más recientes primero)
    });

    setState(() {
      _terminalesFiltradas = filtradas;
      _totalCost = costoTotal;
      _costosPorAno = costosPorAno; // Guardar costos agrupados por año
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
                labelText: "Buscar por número de serie o inventario",
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
                        "Ingrese un número de serie o inventario para buscar terminales dañadas.",
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
                        "No se encontraron terminales con ese número de serie o inventario.",
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
                      DataColumn(label: Text("Inventario")),
                      DataColumn(label: Text("Fecha Reparación")),
                      DataColumn(label: Text("Costo")),
                    ],
                    rows: _terminalesFiltradas.map((terminal) {
                      return DataRow(cells: [
                        DataCell(Text(terminal.serie)),
                        DataCell(Text(terminal.marca)),
                        DataCell(Text(terminal.modelo)),
                        DataCell(Text(terminal.inventario)),
                        DataCell(Text(terminal.fechaReparacion != null
                            ? DateFormat("dd/MM/yyyy").format(
                                DateTime.parse(terminal.fechaReparacion!))
                            : "N/A")),
                        DataCell(Text(
                            "\$${terminal.costo?.toStringAsFixed(2) ?? '0.00'}")),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 🔹 Mostrar costos agrupados por año
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._costosPorAno.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          "Costo en ${entry.key}: \$${entry.value.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal),
                        ),
                      )),

                  const SizedBox(height: 10),

                  // 🔹 Mostrar costo total de todos los años
                  Text(
                    "Costo Total (Todos los años): \$${_totalCost.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
