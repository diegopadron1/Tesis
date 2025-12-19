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

  // ==========================================
  // 1. ANTECEDENTE PERSONAL
  // ==========================================
  
  // Crear
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

  // Actualizar (CORREGIDO)
  Future<Map<String, dynamic>> updatePersonal(int id, String tipo, String detalle) async {
    final token = await _authService.getToken();
    // CORRECCIÓN: Usamos ApiConfig en lugar de _baseUrl
    final url = Uri.parse('${ApiConfig.antecedentesPersonalUrl}/$id'); 
    
    return _genericUpdate(url, {'tipo': tipo, 'detalle': detalle}, token);
  }

  // ==========================================
  // 2. ANTECEDENTE FAMILIAR
  // ==========================================

  // Crear
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

  // Actualizar (CORREGIDO)
  Future<Map<String, dynamic>> updateFamiliar(int id, String tipo, String vivo, String edad, String patologias) async {
    final token = await _authService.getToken();
    // CORRECCIÓN: Usamos ApiConfig
    final url = Uri.parse('${ApiConfig.antecedentesFamiliarUrl}/$id');
    
    return _genericUpdate(url, {
      'tipo_familiar': tipo,
      'vivo_muerto': vivo,
      'edad': edad,
      'patologias': patologias
    }, token);
  }

  // ==========================================
  // 3. HÁBITOS
  // ==========================================

  // Crear
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

  // Actualizar (CORREGIDO)
  Future<Map<String, dynamic>> updateHabitos(int id, String cafe, String tabaco, String alcohol, String drogas, String ocupacion, String sueno, String vivienda) async {
    final token = await _authService.getToken();
    // CORRECCIÓN: Usamos ApiConfig
    final url = Uri.parse('${ApiConfig.antecedentesHabitosUrl}/$id');
    
    return _genericUpdate(url, {
       'cafe': cafe, 'tabaco': tabaco, 'alcohol': alcohol, 'drogas_ilicitas': drogas,
       'ocupacion': ocupacion, 'sueño': sueno, 'vivienda': vivienda
    }, token);
  }

  // ==========================================
  // HELPERS
  // ==========================================

  // Helper para hacer PUT genérico
  Future<Map<String, dynamic>> _genericUpdate(Uri url, Map body, String? token) async {
     try {
       final response = await http.put(
         url, 
         headers: {
           'Content-Type': 'application/json', 
           'x-access-token': token ?? ''
         },
         body: jsonEncode(body)
       );
       
       final data = jsonDecode(response.body);
       
       if (response.statusCode == 200) {
         return {
           'success': true, 
           'message': data['message'], 
           'data': data['data'] // Importante devolver data
         };
       } else {
         return {
           'success': false, 
           'message': data['message'] ?? 'Error al actualizar'
         };
       }
     } catch(e) {
       return {'success': false, 'message': e.toString()};
     }
  }

  // Helper para procesar respuesta de POST (CORREGIDO)
  Map<String, dynamic> _processResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return {
        'success': true, 
        'message': body['message'],
        'data': body['data'] // <--- ¡ESTO FALTABA Y ES CRUCIAL PARA EL ID!
      };
    } else {
      return {'success': false, 'message': body['message'] ?? 'Error desconocido'};
    }
  }
  
// Obtener todos los antecedentes de hoy
  Future<Map<String, dynamic>> getDatosHoy(String cedula) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/antecedentes/hoy/$cedula'); 

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
        return {'success': true, 'data': body['data']}; 
        // data tendrá: { personal: ..., familiar: ..., habitos: ... }
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error al cargar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

}