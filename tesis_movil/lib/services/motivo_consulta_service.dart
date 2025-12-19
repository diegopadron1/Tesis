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
          'data': responseBody['data'] // Retornamos la data para obtener el ID
        };
      } else {
        // Errores
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

  // --- MÉTODO ACTUALIZAR (AHORA DENTRO DE LA CLASE) ---
  Future<Map<String, dynamic>> updateMotivo(int idMotivo, String nuevoMotivo) async {
    final token = await _authService.getToken();
    
    // CORRECCIÓN: Usamos ApiConfig en lugar de _baseUrl
    // Asumimos que la ruta es: .../api/motivo-consulta/:id
    final url = Uri.parse('${ApiConfig.motivoConsultaUrl}/$idMotivo'); 
    
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
        // CORRECCIÓN: Usamos la misma clave que en el create ('motivo_consulta')
        body: jsonEncode({'motivo_consulta': nuevoMotivo}),
      );
      
      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Motivo actualizado'};
      } else {
        return {
          'success': false, 
          'message': responseBody['message'] ?? 'Error al actualizar motivo'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
// --- OBTENER DATOS DE HOY ---
  // Esta función es la que llama tu pantalla al iniciar
  Future<Map<String, dynamic>> getDatosHoy(String cedula) async {
    final token = await _authService.getToken();
    // Asegúrate que ApiConfig.baseUrl sea correcto (ej: http://10.0.2.2:3000/api)
    final url = Uri.parse('${ApiConfig.baseUrl}/motivo-consulta/hoy/$cedula'); 

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json', 
          'x-access-token': token ?? ''
        },
      );

      final body = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Retornamos la data. El backend debe enviar { motivo: ..., triaje: ... }
        return {'success': true, 'data': body['data']}; 
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error al cargar datos'};
      }
    } catch (e) {
      debugPrint("Error getDatosHoy: $e");
      return {'success': false, 'message': e.toString()};
    }
  }
} // <--- FIN DE LA CLASE