import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ExamenService {
  final AuthService _authService = AuthService();

  // ==========================================
  // EXAMEN FÍSICO
  // ==========================================

  // 1. Crear Examen Físico
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
        return {
          'success': true, 
          'message': body['message'],
          'data': body['data'] // <--- IMPORTANTE: Devolver la data para capturar el ID
        };
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 2. Actualizar Examen Físico (NUEVO)
  Future<Map<String, dynamic>> updateExamenFisico(
      int id, String area, String hallazgos) async {
    
    final token = await _authService.getToken();
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};

    // Construimos la URL: .../api/examen-fisico/35
    final url = Uri.parse('${ApiConfig.examenFisicoUrl}/$id');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
        body: jsonEncode({
          'area': area,
          'hallazgos': hallazgos,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'message': body['message'] ?? 'Actualizado correctamente',
          'data': body['data']
        };
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error al actualizar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }


  // ==========================================
  // EXAMEN FUNCIONAL
  // ==========================================

  // 3. Crear Examen Funcional
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
        return {
          'success': true, 
          'message': body['message'],
          'data': body['data'] // <--- IMPORTANTE: Devolver la data para capturar el ID
        };
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 4. Actualizar Examen Funcional (NUEVO)
  Future<Map<String, dynamic>> updateExamenFuncional(
      int id, String sistema, String hallazgos) async {
    
    final token = await _authService.getToken();
    if (token == null) return {'success': false, 'message': 'Sin sesión.'};

    // Construimos la URL: .../api/examen-funcional/35
    final url = Uri.parse('${ApiConfig.examenFuncionalUrl}/$id');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
        body: jsonEncode({
          'sistema': sistema,
          'hallazgos': hallazgos,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'message': body['message'] ?? 'Actualizado correctamente',
          'data': body['data']
        };
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error al actualizar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

}