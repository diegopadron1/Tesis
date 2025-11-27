import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import '../models/medicamento.dart';

class EnfermeriaService {
  final AuthService _authService = AuthService();

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
        throw Exception('Error al cargar órdenes');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // 2. Obtener Lista de Medicamentos
  Future<List<Medicamento>> getListaMedicamentos() async {
    final headers = await _getHeaders();
    if (headers == null) throw Exception('Sin sesión');

    try {
      final response = await http.get(Uri.parse(ApiConfig.farmaciaInventarioUrl), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => Medicamento.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // 3. Solicitar Medicamento
  Future<Map<String, dynamic>> solicitarMedicamento(
      String cedulaPaciente, int idMedicamento, int cantidad) async {
    
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión'};

    final cedulaEnfermera = await _authService.getCedulaUsuario(); 

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.enfermeriaSolicitarUrl),
        headers: headers,
        body: jsonEncode({
          'cedula_paciente': cedulaPaciente,
          'id_medicamento': idMedicamento,
          'cantidad': cantidad,
          'id_usuario': cedulaEnfermera 
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 4. NUEVO: Actualizar Estatus de Orden
  Future<Map<String, dynamic>> actualizarOrden(
      int idOrden, String estatus, String observaciones) async {
    
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión'};

    try {
      // Endpoint: /api/enfermeria/ordenes/:id
      // Construimos la URL reemplazando el ID
      // Nota: Asumimos que la URL base en ApiConfig termina en /api
      // La ruta definida es /enfermeria/ordenes/:id_orden
      // Ajuste manual de URL:
      final url = "${ApiConfig.enfermeriaOrdenesUrl.replaceAll('/pendientes', '')}/$idOrden";
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'estatus': estatus,
          'observaciones': observaciones
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}