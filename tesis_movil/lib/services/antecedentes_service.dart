import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class AntecedentesService {
  final AuthService _authService = AuthService();

  // Helper privado para headers y token
  Future<Map<String, String>?> _getHeaders() async {
    final token = await _authService.getToken();
    if (token == null) return null;
    return {
      'Content-Type': 'application/json',
      'x-access-token': token,
    };
  }

  // 1. Crear Antecedente Personal
  Future<Map<String, dynamic>> createPersonal(
      String cedula, String tipo, String detalle) async {
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión.'};

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.antecedentesPersonalUrl),
        headers: headers,
        body: jsonEncode({
          'cedula_paciente': cedula,
          'tipo': tipo,
          'detalle': detalle,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 2. Crear Antecedente Familiar
  Future<Map<String, dynamic>> createFamiliar(String cedula, String tipo,
      String vivoMuerto, String? edad, String? patologias) async {
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión.'};

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.antecedentesFamiliarUrl),
        headers: headers,
        body: jsonEncode({
          'cedula_paciente': cedula,
          'tipo_familiar': tipo,
          'vivo_muerto': vivoMuerto,
          'edad': edad != null && edad.isNotEmpty ? int.tryParse(edad) : null,
          'patologias': patologias,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 3. Crear Hábitos
  Future<Map<String, dynamic>> createHabitos(
      String cedula,
      String cafe,
      String tabaco,
      String alcohol,
      String drogas,
      String ocupacion,
      String sueno,
      String vivienda) async {
    final headers = await _getHeaders();
    if (headers == null) return {'success': false, 'message': 'Sin sesión.'};

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.antecedentesHabitosUrl),
        headers: headers,
        body: jsonEncode({
          'cedula_paciente': cedula,
          'cafe': cafe,
          'tabaco': tabaco,
          'alcohol': alcohol,
          'drogas_ilicitas': drogas,
          'ocupacion': ocupacion,
          'sueño': sueno,
          'vivienda': vivienda,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return {'success': true, 'message': body['message']};
    } else {
      return {'success': false, 'message': body['message'] ?? 'Error desconocido'};
    }
  }
}