import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class TriajeService {
  final AuthService _authService = AuthService();
  
  // URL base (Asegúrate que tu servidor backend tenga estas rutas)
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
        return {'success': true, 'message': data['message'], 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al guardar triaje'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 2. Obtener lista de pacientes activos (Para Residentes)
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

  // 3. Cambiar estado (Genérico - Usado por Residentes)
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

  // 4. Atender Paciente
  Future<bool> atenderPaciente(int idTriaje, String? nuevaUbicacion) async {
    final token = await _authService.getToken();
    
    final nombreResidente = await _authService.getNombreCompleto(); 
    final url = Uri.parse('$_baseUrl/atender/$idTriaje');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? ''
        },
        body: jsonEncode({
          'nombre_residente': nombreResidente,
          'nueva_ubicacion': nuevaUbicacion, 
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error atendiendo: $e");
      return false;
    }
  }

  // 5. Actualizar triaje existente
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
          'data': responseBody['data'] 
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

  // 6. Obtener lista de pacientes referidos (Para el Especialista)
  Future<List<dynamic>> getPacientesReferidos() async {
    final token = await _authService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/referidos"), 
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
      debugPrint("Error obteniendo referidos: $e");
      return [];
    }
  }

  // 7. [NUEVO] Finalizar Caso Especialista (Alta o Fallecido)
  Future<bool> finalizarCasoEspecialista(int idTriaje, String motivo) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    // Esta URL debe coincidir con la ruta definida en el backend: router.put('/finalizar/:id', ...)
    final url = Uri.parse("$_baseUrl/finalizar/$idTriaje");

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token,
        },
        body: jsonEncode({
          'motivo': motivo, // 'Alta' o 'Fallecido'
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Error del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint("Error de conexión al finalizar especialista: $e");
      return false;
    }
  }
}