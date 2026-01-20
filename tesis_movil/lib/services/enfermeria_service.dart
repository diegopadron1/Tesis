import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Para debugPrint
import '../config/api_config.dart';
import 'auth_service.dart';
import '../models/medicamento.dart';

class EnfermeriaService {
  final AuthService _authService = AuthService();

  // Helper para obtener cabeceras con el token
  Future<Map<String, String>?> _getHeaders() async {
    final token = await _authService.getToken();
    if (token == null) return null;
    return {
      'Content-Type': 'application/json',
      'x-access-token': token,
    };
  }

  // 1. Obtener Órdenes Médicas Pendientes
  Future<List<dynamic>> getOrdenesPendientes() async {
    final headers = await _getHeaders();
    if (headers == null) throw Exception('Sin sesión');

    try {
      final response = await http.get(Uri.parse(ApiConfig.enfermeriaOrdenesUrl), headers: headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cargar órdenes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // 2. Obtener Lista de Medicamentos (Buscador)
  Future<List<Medicamento>> getListaMedicamentos({String? query}) async {
    final headers = await _getHeaders();
    if (headers == null) throw Exception('Sin sesión');

    try {
      // Usamos la URL base de inventario
      Uri url = Uri.parse(ApiConfig.farmaciaInventarioUrl);
      
      // Si hay texto de búsqueda, lo añadimos como query param ?q=texto
      if (query != null && query.isNotEmpty) {
        url = url.replace(queryParameters: {'q': query});
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => Medicamento.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error en getListaMedicamentos: $e");
      return [];
    }
  }

  // 3. Solicitar Medicamento (CORREGIDO - URL ACTUALIZADA)
  Future<Map<String, dynamic>> solicitarMedicamento(
      String cedulaPaciente, int idMedicamento, int cantidad) async {
    
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión'};

    final cedulaEnfermera = await _authService.getCedulaUsuario(); 

    try {
      // IMPORTANTE: Nos aseguramos de apuntar a la ruta correcta del backend
      // Si ApiConfig.enfermeriaSolicitarUrl no apunta a '/solicitar-medicamento', usa esta construcción:
      final url = Uri.parse('${ApiConfig.baseUrl}/enfermeria/solicitar-medicamento');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'cedula_paciente': cedulaPaciente,
          'id_medicamento': idMedicamento,
          'cantidad': cantidad,
          'id_usuario': cedulaEnfermera 
        }),
      );

      final body = jsonDecode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      } else {
        // Devolvemos el error específico del backend (ej: "Stock insuficiente")
        return {'success': false, 'message': body['message'] ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 4. Actualizar Estatus de Orden
  Future<Map<String, dynamic>> actualizarOrden(
      int idOrden, String estatus, String observaciones) async {
    
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión'};

    try {
      // Construcción robusta de la URL para actualizar orden
      // Asume que ApiConfig.enfermeriaOrdenesUrl es algo como ".../enfermeria/ordenes/pendientes"
      // Quitamos el '/pendientes' para quedar en ".../enfermeria/ordenes"
      final baseUrlOrdenes = ApiConfig.enfermeriaOrdenesUrl.replaceAll('/pendientes', '');
      final url = Uri.parse("$baseUrlOrdenes/$idOrden");
      
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'estatus': estatus,
          'observaciones': observaciones,
          'id_usuario': await _authService.getCedulaUsuario() 
        }),
      );

      final body = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error al actualizar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 5. Obtener medicamento autorizado (CORREGIDO - URL ACTUALIZADA)
  Future<Map<String, dynamic>?> getMedicamentoAutorizado(String cedula) async {
    final headers = await _getHeaders();
    if (headers == null) return null;

    try {
      // IMPORTANTE: Apuntamos a la ruta correcta que definimos en las routes
      final url = Uri.parse("${ApiConfig.baseUrl}/enfermeria/medicamento-autorizado/$cedula");
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null; // Si es 404 o 403, simplemente retornamos null
    } catch (e) {
      debugPrint("Error en getMedicamentoAutorizado: $e");
      return null;
    }
  }
}