import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class DiagnosticoService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> createDiagnostico(
      String cedulaPaciente, String diagnosticoDefinitivo) async {
    
    // 1. Obtener Token
    final token = await _authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesión expirada. Inicie sesión.'};
    }

    final url = Uri.parse(ApiConfig.diagnosticoUrl);

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-access-token': token,
        },
        body: jsonEncode({
          'cedula_paciente': cedulaPaciente,
          'diagnostico_definitivo': diagnosticoDefinitivo,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true, 
          'message': responseBody['message'],
          'data': responseBody['data']
        };
      } else {
        final message = responseBody['message'] ?? 'Error desconocido.';
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      debugPrint('Error en DiagnosticoService: $e');
      return {
        'success': false, 
        'message': 'Error de conexión con el servidor.'
      };
    }
  }
}