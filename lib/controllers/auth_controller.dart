import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<bool> login(int rp, String contrasenia) async {
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.login(rp, contrasenia);

    _isLoading = false;
    notifyListeners();

    return response != null; // No es necesario volver a guardar los datos aquí
  }
}
