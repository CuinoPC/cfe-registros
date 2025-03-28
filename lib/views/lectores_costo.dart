import 'package:cfe_registros/services/api_lector_danado.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../models/lector_danado.dart';

class CostosLectoresPage extends StatefulWidget {
  @override
  _CostosLectoresPageState createState() => _CostosLectoresPageState();
}

class _CostosLectoresPageState extends State<CostosLectoresPage> {
  final LectorDanadoService _apiService = LectorDanadoService();
  List<LectorDanado> _lectoresFiltrados = [];
  String _searchQuery = "";
  double _totalCost = 0.0;
  bool _isLoading = false;
  Map<int, double> _costosPorAno = {};
  bool _filtroPorAno = false;

  void _buscarLectores(String query) async {
    setState(() {
      _isLoading = true;
      _searchQuery = query.trim();
    });

    List<LectorDanado> lectores = await _apiService.getLectoresDanados();

    List<LectorDanado> filtrados = [];
    Map<int, double> costosPorAno = {};
    double costoTotal = 0.0;
    bool filtroAno = false;

    if (RegExp(r'^\d{4}$').hasMatch(_searchQuery)) {
      int anoFiltrado = int.parse(_searchQuery);
      filtrados = lectores.where((l) {
        if (l.fechaReparacion == null || l.costo == null) return false;
        DateTime fecha = DateTime.parse(l.fechaReparacion!);
        return fecha.year == anoFiltrado;
      }).toList();
      filtroAno = true;
    } else {
      filtrados = lectores.where((l) {
        return l.folio.trim().toLowerCase() == _searchQuery.toLowerCase() ||
            l.area.trim().toLowerCase() == _searchQuery.toLowerCase() ||
            l.ticket.trim().toLowerCase() == _searchQuery.toLowerCase();
      }).toList();
    }

    for (var lector in filtrados) {
      if (lector.fechaReparacion != null && lector.costo != null) {
        DateTime fecha = DateTime.parse(lector.fechaReparacion!);
        int anio = fecha.year;

        costosPorAno.update(anio, (value) => value + lector.costo!,
            ifAbsent: () => lector.costo!);

        costoTotal += lector.costo!;
      }
    }

    filtrados.sort((a, b) {
      DateTime? fechaA =
          a.fechaReparacion != null ? DateTime.parse(a.fechaReparacion!) : null;
      DateTime? fechaB =
          b.fechaReparacion != null ? DateTime.parse(b.fechaReparacion!) : null;

      if (fechaA == null && fechaB == null) return 0;
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;
      return fechaB.compareTo(fechaA);
    });

    setState(() {
      _lectoresFiltrados = filtrados;
      _totalCost = costoTotal;
      _costosPorAno = costosPorAno;
      _filtroPorAno = filtroAno;
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
              onChanged: _buscarLectores,
              decoration: InputDecoration(
                labelText: "Buscar por folio, área, ticket o año",
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
                        "Ingrese un folio, área, ticket o año para buscar lectores dañados.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_lectoresFiltrados.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 80, color: Colors.grey.shade500),
                      const SizedBox(height: 10),
                      const Text(
                        "No se encontraron lectores con ese criterio.",
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
                      DataColumn(label: Text("Área")),
                      DataColumn(label: Text("Ticket")),
                      DataColumn(label: Text("Marca")),
                      DataColumn(label: Text("Modelo")),
                      DataColumn(label: Text("Tipo de Conector")),
                      DataColumn(label: Text("Folio")),
                      DataColumn(label: Text("Fecha Reparación")),
                      DataColumn(label: Text("Costo")),
                    ],
                    rows: _lectoresFiltrados.map((lector) {
                      return DataRow(cells: [
                        DataCell(SelectableText(lector.area)),
                        DataCell(SelectableText(lector.ticket)),
                        DataCell(SelectableText(lector.marca)),
                        DataCell(SelectableText(lector.modelo)),
                        DataCell(SelectableText(lector.tipoConector)),
                        DataCell(SelectableText(lector.folio)),
                        DataCell(SelectableText(
                          lector.fechaReparacion != null
                              ? DateFormat("dd/MM/yyyy").format(
                                  DateTime.parse(lector.fechaReparacion!))
                              : "N/A",
                        )),
                        DataCell(SelectableText(
                          "\$${lector.costo?.toStringAsFixed(2) ?? '0.00'}",
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_costosPorAno.isNotEmpty)
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
                  if (!_filtroPorAno)
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
