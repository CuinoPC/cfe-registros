import 'dart:io';
import 'package:cfe_registros/services/api_terminales.dart';
import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UploadPhotosPage extends StatefulWidget {
  final int terminalId;

  UploadPhotosPage({required this.terminalId});

  @override
  _UploadPhotosPageState createState() => _UploadPhotosPageState();
}

class _UploadPhotosPageState extends State<UploadPhotosPage> {
  final ApiTerminalService _ApiTerminalService = ApiTerminalService();
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
        const SnackBar(content: Text("Máximo 7 imágenes permitidas")),
      );
    }
  }

  Future<void> _uploadPhotos() async {
    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona al menos una imagen")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    bool success = await _ApiTerminalService.uploadTerminalPhotos(
        widget.terminalId, _selectedPhotos);

    setState(() {
      _isUploading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fotos subidas correctamente")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No puedes subir más de 7 fotos en una semana")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImages,
              child: const Text("Seleccionar Fotos"),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
            const SizedBox(height: 10),
            _isUploading
                ? const CircularProgressIndicator() // ✅ Muestra progreso al subir
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
