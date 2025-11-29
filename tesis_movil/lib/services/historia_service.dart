import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class HistoriaService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>?> _getHeaders() async {
    final token = await _authService.getToken();
    if (token == null) return null;
    return {
      'Content-Type': 'application/json',
      'x-access-token': token,
    };
  }

  // 1. Obtener Historia Clínica Completa
  Future<Map<String, dynamic>> getHistoriaClinica(String cedula) async {
    final headers = await _getHeaders();
    if (headers == null) throw Exception('Sin sesión');

    try {
      final url = "${ApiConfig.historiaBaseUrl}/$cedula";
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return {}; // Paciente no encontrado (retorna mapa vacío)
      } else {
        throw Exception('Error al cargar historia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // 2. Guardar una Sección Específica (Upsert)
  // seccion: 'motivo', 'diagnostico', 'fisico', etc.
  Future<Map<String, dynamic>> guardarSeccion(String cedula, String seccion, Map<String, dynamic> datos) async {
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión'};

    try {
      final url = "${ApiConfig.historiaSeccionUrl}/$cedula";
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'seccion': seccion,
          'datos': datos
        }),
      );

      final body = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': body['message'] ?? 'Error al guardar'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 3. Editar Orden Médica (Solo si es pendiente)
  Future<Map<String, dynamic>> editarOrden(int idOrden, Map<String, dynamic> datos) async {
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión'};

    try {
      final url = "${ApiConfig.historiaOrdenUrl}/$idOrden";
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(datos),
      );

      final body = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': body['message'] ?? 'Error al editar orden'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}