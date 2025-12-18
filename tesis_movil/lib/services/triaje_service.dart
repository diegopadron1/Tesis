import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class TriajeService {
  final AuthService _authService = AuthService();
  
  // URL base apuntando a /api/triaje
  // Asegúrate de que esta IP sea correcta para tu emulador/dispositivo
  final String _baseUrl = "http://10.0.2.2:3000/api/triaje"; 

  // 1. Crear Triaje
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
        // Retornamos 'data' para obtener el ID en el frontend
        return {'success': true, 'message': data['message'], 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al guardar triaje'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 2. Obtener lista de pacientes activos en urgencias
  Future<List<dynamic>> getTriajesActivos() async {
    final token = await _authService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/activos"),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error obteniendo triajes activos: $e");
      return [];
    }
  }

  // 3. Cambiar estado (ej: Dar de Alta)
  Future<bool> cambiarEstado(int idTriaje, String nuevoEstado) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/$idTriaje/estado"),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
        body: jsonEncode({'estado': nuevoEstado}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error cambiando estado: $e");
      return false;
    }
  }

  // 4. Atender paciente
  Future<bool> atenderPaciente(int idTriaje, String nombreResidente) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final url = Uri.parse('$_baseUrl/$idTriaje/atender');
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
        body: jsonEncode({
          'nombre_residente': nombreResidente 
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Error al atender: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error de conexión: $e");
      return false;
    }
  }

  // 5. Método para actualizar un triaje existente (ESTO FALTABA DENTRO DE LA CLASE)
  Future<Map<String, dynamic>> updateTriaje(int idTriaje, Map<String, dynamic> datos) async {
    final token = await _authService.getToken();
    final url = Uri.parse('$_baseUrl/$idTriaje'); 
    
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
        body: jsonEncode(datos),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'message': 'Triaje actualizado', 
          'data': responseBody['data'] // Retornamos la data actualizada
        };
      } else {
        return {
          'success': false, 
          'message': responseBody['message'] ?? 'Error al actualizar triaje'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

} // <--- IMPORTANTE: Esta llave cierra la clase TriajeService