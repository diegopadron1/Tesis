import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/medicamento.dart';
import 'auth_service.dart';

class FarmaciaService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>?> _getHeaders() async {
    final token = await _authService.getToken();
    if (token == null) return null;
    return {
      'Content-Type': 'application/json',
      'x-access-token': token,
    };
  }

  Future<List<Medicamento>> getInventario() async {
    final headers = await _getHeaders();
    if (headers == null) throw Exception('Sin sesión');

    try {
      final response = await http.get(Uri.parse(ApiConfig.farmaciaInventarioUrl), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => Medicamento.fromJson(e)).toList();
      } else {
        throw Exception('Error al cargar inventario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Ahora acepta la fecha de vencimiento
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
      return {'success': response.statusCode == 201, 'message': body['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> addStock(int id, int cantidad, String motivo) async {
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión'};

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.farmaciaStockUrl),
        headers: headers,
        body: jsonEncode({
          'id_medicamento': id,
          'cantidad': cantidad,
          'motivo': motivo,
        }),
      );
      final body = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'message': body['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // NUEVA FUNCIÓN: Remove Stock
  Future<Map<String, dynamic>> removeStock(int id, int cantidad, String motivo) async {
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión'};

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.farmaciaSalidaUrl),
        headers: headers,
        body: jsonEncode({
          'id_medicamento': id,
          'cantidad': cantidad,
          'motivo': motivo,
        }),
      );
      final body = jsonDecode(response.body);
      // Validamos si fue exitoso (200) o si falló por stock insuficiente (400)
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error al descontar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}