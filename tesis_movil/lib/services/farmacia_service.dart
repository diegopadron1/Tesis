import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import '../models/medicamento.dart';

class FarmaciaService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>?> _getHeaders() async {
    final token = await _authService.getToken();
    if (token == null) return null;
    return { 'Content-Type': 'application/json', 'x-access-token': token };
  }

  // --- BUSCAR MEDICAMENTOS ---
  Future<List<Medicamento>> searchMedicamentos(String query) async {
    final headers = await _getHeaders();
    if (headers == null) return [];
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/farmacia/medicamentos/search?nombre=$query"),
        headers: headers
      );
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => Medicamento.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // GET INVENTARIO
  Future<List<Medicamento>> getInventario() async {
    final headers = await _getHeaders();
    if (headers == null) return [];
    try {
      final response = await http.get(Uri.parse(ApiConfig.farmaciaInventarioUrl), headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => Medicamento.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createMedicamento(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión'};
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.farmaciaCrearUrl),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body);
      return {'success': response.statusCode == 201, 'message': body['message'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> addStock(int id, int cantidad, String motivo) async {
    return _callStockApi(id, cantidad, 'ENTRADA', motivo);
  }

  Future<Map<String, dynamic>> removeStock(int id, int cantidad, String motivo) async {
    return _callStockApi(id, cantidad, 'SALIDA', motivo);
  }

  Future<Map<String, dynamic>> _callStockApi(int id, int cantidad, String tipo, String motivo) async {
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión'};
    final idUsuario = await _authService.getCedulaUsuario();
    try {
      final url = "${ApiConfig.farmaciaInventarioUrl.replaceAll('/inventario', '')}/medicamentos/$id/stock";
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'cantidad': cantidad,
          'tipo_movimiento': tipo,
          'motivo': motivo,
          'id_usuario': idUsuario
        }),
      );
      final body = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'message': body['message'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> eliminarMedicamento(int id) async {
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión'};
    try {
      final url = "${ApiConfig.farmaciaInventarioUrl.replaceAll('/inventario', '')}/medicamentos/$id";
      final response = await http.delete(Uri.parse(url), headers: headers);
      final body = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'message': body['message'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': "Error: $e"};
    }
  }

  // =======================================================
  //  GESTIÓN DE SOLICITUDES (Home Screen)
  // =======================================================

  // 1. Obtener lista de solicitudes (Trae PENDIENTE y LISTO del backend)
  Future<List<dynamic>> getSolicitudesPendientes() async {
    final headers = await _getHeaders();
    if (headers == null) return [];

    try {
      // Esta URL debe traer registros con estatus PENDIENTE o LISTO
      final url = Uri.parse("${ApiConfig.baseUrl}/farmacia/solicitudes");
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Error server: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("Excepción obteniendo solicitudes: $e");
      return [];
    }
  }

  // 2. Marcar solicitud como LISTA (Refactorizado para usar el método general)
  Future<void> marcarListo(int idSolicitud) async {
    final resultado = await actualizarEstado(idSolicitud, 'LISTO');
    if (!resultado['success']) {
      throw Exception(resultado['message']);
    }
  }

  // 3. MÉTODO PARA ACTUALIZAR ESTADO (LISTO o ENTREGADO)
  // Este método permite que la tarjeta se mantenga en vista cambiando de estado
  Future<Map<String, dynamic>> actualizarEstado(int idSolicitud, String nuevoEstado) async {
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión'};

    try {
      // Ruta unificada para cambiar el estatus de la solicitud
      final url = Uri.parse("${ApiConfig.baseUrl}/farmacia/solicitudes/$idSolicitud/estado");
      
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({'estatus': nuevoEstado}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'] ?? 'Estado actualizado'};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error al actualizar estado'};
      }
    } catch (e) {
      debugPrint("Error en actualizarEstado: $e");
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}