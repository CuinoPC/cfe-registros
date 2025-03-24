import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:cfe_registros/services/api_terminales.dart';
import 'package:data_table_2/data_table_2.dart';

class PiezasTPSPage extends StatefulWidget {
  @override
  _PiezasTPSPageState createState() => _PiezasTPSPageState();
}

class _PiezasTPSPageState extends State<PiezasTPSPage> {
  final ApiTerminalService _apiService = ApiTerminalService();
  List<Map<String, dynamic>> piezas = [];
  List<TextEditingController> costoControllers = [];

  @override
  void initState() {
    super.initState();
    _cargarPiezas();
  }

  Future<void> _cargarPiezas() async {
    final data = await _apiService.getPiezasTPS();
    setState(() {
      piezas = data;
      costoControllers = List.generate(
        piezas.length,
        (index) =>
            TextEditingController(text: piezas[index]['costo'].toString()),
      );
    });
  }

  Future<void> _actualizarPieza(int index) async {
    final id = piezas[index]['id'];
    final nombre = piezas[index]['nombre_pieza']; // No se modifica
    final costo = double.tryParse(costoControllers[index].text) ?? 0.0;

    final success = await _apiService.updatePiezaTPS(id, nombre, costo);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pieza actualizada correctamente")),
      );
      _cargarPiezas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar la pieza")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: piezas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: DataTable2(
                columnSpacing: 20,
                minWidth: 600,
                headingRowColor: MaterialStateColor.resolveWith(
                    (states) => Colors.teal.shade100),
                border: TableBorder.all(color: Colors.grey),
                columns: const [
                  DataColumn(label: Text("#")),
                  DataColumn(label: Text("Nombre Pieza")),
                  DataColumn(label: Text("Costo")),
                  DataColumn(label: Text("Acciones")),
                ],
                rows: List.generate(piezas.length, (index) {
                  return DataRow(cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(piezas[index]['nombre_pieza'])),
                    DataCell(TextField(
                      controller: costoControllers[index],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    )),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.save, color: Colors.teal),
                        onPressed: () => _actualizarPieza(index),
                      ),
                    ),
                  ]);
                }),
              ),
            ),
    );
  }
}
