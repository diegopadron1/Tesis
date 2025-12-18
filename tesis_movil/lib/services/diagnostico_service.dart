import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class DiagnosticoService {
  final AuthService _authService = AuthService();

  // CREAR
  Future<Map<String, dynamic>> createDiagnostico(Map<String, dynamic> data) async {
    final token = await _authService.getToken();
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.diagnosticoUrl),
        headers: {'Content-Type': 'application/json', 'x-access-token': token},
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
            'success': true, 
            'message': body['message'],
            'data': body // Devolvemos todo el body para sacar diagnostico y orden
        };
      } else if (response.statusCode == 403) {
        return {'success': false, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ACTUALIZAR (NUEVO)
  Future<Map<String, dynamic>> updateDiagnostico(int idDiagnostico, Map<String, dynamic> data) async {
    final token = await _authService.getToken();
    // Asumiendo ruta: PUT .../api/diagnostico/45
    final url = Uri.parse('${ApiConfig.diagnosticoUrl}/$idDiagnostico'); 

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json', 'x-access-token': token ?? ''},
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'], 'data': body['data']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error al actualizar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}