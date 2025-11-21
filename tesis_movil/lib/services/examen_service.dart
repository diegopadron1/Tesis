import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ExamenService {
  final AuthService _authService = AuthService();

  // --- 1. Crear Examen Físico ---
  Future<Map<String, dynamic>> createExamenFisico(
      String cedula, String area, String hallazgos) async {
    
    final token = await _authService.getToken();
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.examenFisicoUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
        body: jsonEncode({
          'cedula_paciente': cedula,
          'area': area,
          'hallazgos': hallazgos,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // --- 2. Crear Examen Funcional ---
  Future<Map<String, dynamic>> createExamenFuncional(
      String cedula, String sistema, String hallazgos) async {
    
    final token = await _authService.getToken();
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.examenFuncionalUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
        body: jsonEncode({
          'cedula_paciente': cedula,
          'sistema': sistema,
          'hallazgos': hallazgos,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}