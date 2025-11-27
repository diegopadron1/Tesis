import 'dart:convert';
import 'package:http/http.dart' as http;
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

  // GET
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

  // CREATE (Adaptado para recibir Map)
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

  // ADD STOCK (Redirige al endpoint unificado con tipo ENTRADA)
  Future<Map<String, dynamic>> addStock(int id, int cantidad, String motivo) async {
    return _callStockApi(id, cantidad, 'ENTRADA', motivo);
  }

  // REMOVE STOCK (Redirige al endpoint unificado con tipo SALIDA)
  Future<Map<String, dynamic>> removeStock(int id, int cantidad, String motivo) async {
    return _callStockApi(id, cantidad, 'SALIDA', motivo);
  }

  // Función privada que hace la llamada real
  Future<Map<String, dynamic>> _callStockApi(int id, int cantidad, String tipo, String motivo) async {
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión'};
    final idUsuario = await _authService.getCedulaUsuario();

    try {
      // Construimos la URL: .../medicamentos/1/stock
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

  // DELETE
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
}