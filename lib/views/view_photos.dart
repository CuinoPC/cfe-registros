import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 📌 Importar paquete para formatear la fecha

class ViewPhotosPage extends StatelessWidget {
  final Map<String, List<String>> fotosPorFecha;

  ViewPhotosPage({required this.fotosPorFecha});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Historial de Fotos")),
      body: fotosPorFecha.isEmpty
          ? Center(child: Text("No hay fotos disponibles"))
          : ListView(
              padding: EdgeInsets.all(10),
              children: fotosPorFecha.entries.map((entry) {
                String fechaISO =
                    entry.key; // 📅 Fecha en formato ISO (yyyy-MM-dd)
                DateTime fecha = DateTime.parse(fechaISO);
                String fechaFormateada = DateFormat("dd/MM/yyyy")
                    .format(fecha); // ✅ Convertir a dd/MM/yyyy

                List<String> fotos = entry.value; // 🖼️ Lista de fotos

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📅 $fechaFormateada",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 5),

                    // ✅ Dividir fotos en bloques de 7 y mostrar separadores
                    Column(
                      children: List.generate(
                        (fotos.length / 7).ceil(),
                        (index) {
                          int start = index * 7;
                          int end = (start + 7).clamp(0, fotos.length);
                          List<String> bloqueFotos = fotos.sublist(start, end);

                          return Column(
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: bloqueFotos.length,
                                itemBuilder: (context, i) {
                                  return Image.network(
                                    "http://localhost:5000${bloqueFotos[i]}",
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.broken_image,
                                          size: 50, color: Colors.red);
                                    },
                                  );
                                },
                              ),
                              if (end <
                                  fotos
                                      .length) // ✅ Agregar línea divisoria si hay más fotos
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(
                                    thickness: 2,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 15),
                  ],
                );
              }).toList(),
            ),
    );
  }
}
