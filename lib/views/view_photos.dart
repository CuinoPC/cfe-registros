import 'package:flutter/material.dart';

class ViewPhotosPage extends StatelessWidget {
  final List<String> fotos;

  ViewPhotosPage({required this.fotos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fotos de la Terminal")),
      body: fotos.isEmpty
          ? Center(child: Text("No hay fotos disponibles"))
          : GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: fotos.length,
              itemBuilder: (context, index) {
                return Image.network(
                  "http://localhost:5000${fotos[index]}", // ✅ Asegurar que la URL es correcta
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.broken_image,
                        size: 50, color: Colors.red);
                  },
                );
              },
            ),
    );
  }
}
