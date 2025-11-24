import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class DiagnosticoService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> createDiagnostico(Map<String, dynamic> data) async {
    final token = await _authService.getToken();
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.diagnosticoUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
        body: jsonEncode(data), // Enviamos el mapa completo con los nuevos campos
      );

      final body = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'message': body['message']};
      } else if (response.statusCode == 403) {
        // Capturamos el error de validación clínica (Falta motivo, examen, etc.)
        return {'success': false, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}