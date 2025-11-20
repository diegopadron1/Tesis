import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class MotivoConsultaService {
  final AuthService _authService = AuthService();

  // Función para crear el motivo de consulta
  Future<Map<String, dynamic>> createMotivoConsulta(
      String cedulaPaciente, String motivo) async {
    
    // 1. Obtener Token
    final token = await _authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesión expirada. Inicie sesión.'};
    }

    final url = Uri.parse(ApiConfig.motivoConsultaUrl);

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-access-token': token,
        },
        body: jsonEncode({
          'cedula_paciente': cedulaPaciente,
          'motivo_consulta': motivo,
        }),
      );

      final responseBody = jsonDecode(response.body);

      // 2. Validar códigos de estado del Backend
      if (response.statusCode == 201) {
        // Éxito
        return {
          'success': true, 
          'message': responseBody['message'],
          'data': responseBody['data'] // Por si necesitas usar el objeto creado
        };
      } else {
        // Errores (400, 401, 403, 500)
        final message = responseBody['message'] ?? 'Error desconocido.';
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      debugPrint('Excepción al crear motivo consulta: $e');
      return {
        'success': false, 
        'message': 'No se pudo conectar con el servidor.'
      };
    }
  }
}