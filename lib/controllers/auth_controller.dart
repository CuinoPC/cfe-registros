import 'package:cfe_registros/services/api_users.dart';
import 'package:flutter/material.dart';

class AuthController extends ChangeNotifier {
  final ApiUserService _apiService = ApiUserService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<bool> login(String rp, String contrasenia) async {
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.login(rp, contrasenia);

    _isLoading = false;
    notifyListeners();

    return response != null; // No es necesario volver a guardar los datos aquí
  }
}
