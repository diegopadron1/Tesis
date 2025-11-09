import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/patient_registration.dart';
import 'auth_service.dart'; // Importamos el servicio de autenticación
import 'package:flutter/foundation.dart';

class PatientService {
  final AuthService _authService = AuthService();

  // Función para registrar un nuevo paciente
  Future<Map<String, dynamic>> registerPatient(
      PatientRegistrationPayload payload) async {
    // 1. Obtener el token JWT
    final token = await _authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesión expirada. Por favor inicie sesión.'};
    }

    final url = Uri.parse(ApiConfig.registerPatientUrl);

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          // 2. Enviar el token en el encabezado 'x-access-token'
          'x-access-token': token, 
        },
        // 3. Serializar el payload con la estructura anidada correcta
        body: jsonEncode(payload.toJson()),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) { // 201 Created (según tu controlador)
        return {'success': true, 'message': responseBody['message']};
      } else if (response.statusCode == 409) { // 409 Conflict (Paciente ya existe)
        return {'success': false, 'message': responseBody['message']};
      } else {
        // Manejar otros errores (400 por validación, 500 interno, etc.)
        final message = responseBody['message'] ?? 'Error desconocido al registrar.';
        final errorList = responseBody['errors'] != null ? (responseBody['errors'] as List).join('\n') : '';
        
        return {
          'success': false,
          'message': '$message\n$errorList',
        };
      }
    } catch (e) {
      debugPrint('Excepción de red al registrar paciente: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }
}