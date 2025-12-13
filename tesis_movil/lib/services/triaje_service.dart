import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class TriajeService {
  final AuthService _authService = AuthService();
  // Ajusta la URL base si es necesario.
  // Ejemplo local: "http://10.0.2.2:3000/api/triaje"
  final String _baseUrl = "http://10.0.2.2:3000/api/triaje"; 

  Future<Map<String, dynamic>> createTriaje({
    required String cedulaPaciente,
    required String color,
    required String ubicacion,
    String? signosVitales,
    String? motivoIngreso,
  }) async {
    
    final token = await _authService.getToken();
    if (token == null) return {'success': false, 'message': 'Sesión no válida'};

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
        body: jsonEncode({
          'cedula_paciente': cedulaPaciente,
          'color': color,
          'ubicacion': ubicacion,
          'signos_vitales': signosVitales,
          'motivo_ingreso': motivoIngreso,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al guardar triaje'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}