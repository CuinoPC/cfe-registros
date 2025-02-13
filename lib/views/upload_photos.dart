import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';

class UploadPhotosPage extends StatefulWidget {
  final int terminalId;

  UploadPhotosPage({required this.terminalId});

  @override
  _UploadPhotosPageState createState() => _UploadPhotosPageState();
}

class _UploadPhotosPageState extends State<UploadPhotosPage> {
  final ApiService _apiService = ApiService();
  List<XFile> _selectedPhotos = [];
  bool _isUploading = false; // ✅ Estado para mostrar progreso

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.length <= 7) {
      setState(() {
        _selectedPhotos = pickedFiles;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Máximo 7 imágenes permitidas")),
      );
    }
  }

  Future<void> _uploadPhotos() async {
    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Selecciona al menos una imagen")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    bool success = await _apiService.uploadTerminalPhotos(
        widget.terminalId, _selectedPhotos);

    setState(() {
      _isUploading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fotos subidas correctamente")),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al subir las fotos")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Subir Fotos")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImages,
              child: Text("Seleccionar Fotos"),
            ),
            SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _selectedPhotos.length,
                itemBuilder: (context, index) {
                  return kIsWeb
                      ? Image.network(_selectedPhotos[index].path,
                          fit: BoxFit.cover)
                      : Image.file(File(_selectedPhotos[index].path),
                          fit: BoxFit.cover);
                },
              ),
            ),
            SizedBox(height: 10),
            _isUploading
                ? CircularProgressIndicator() // ✅ Muestra progreso al subir
                : ElevatedButton(
                    onPressed: _uploadPhotos,
                    child: Text("Subir Fotos"),
                  ),
          ],
        ),
      ),
    );
  }
}
