import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

// --- CAMBIO CRÍTICO: Importamos el NUEVO modelo ---
import '../models/patient_model.dart'; 

class PatientService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> registerPatient(
      PatientRegistrationPayload payload) async {
    
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
          'x-access-token': token, 
        },
        body: jsonEncode(payload.toJson()),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) { 
        return {'success': true, 'message': responseBody['message']};
      } else if (response.statusCode == 409) { 
        return {'success': false, 'message': responseBody['message']};
      } else {
        final message = responseBody['message'] ?? 'Error desconocido al registrar.';
        final errorList = responseBody['errors'] != null ? "\n${(responseBody['errors'] as List).join('\n')}" : '';
        
        return {
          'success': false,
          'message': '$message$errorList',
        };
      }
    } catch (e) {
      debugPrint('Excepción de red al registrar paciente: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }
}