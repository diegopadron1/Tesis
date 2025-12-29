import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart'; 
import 'auth_service.dart'; 

class ReporteService {
  final String _baseUrl = ApiConfig.baseUrl;
  
  // Creamos una instancia de AuthService para acceder a getToken()
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getReportePacientes(String fecha) async {
    try {
      // Ahora llamamos al método desde la instancia '_authService'
      final token = await _authService.getToken(); 
      
      final response = await http.get(
        Uri.parse('$_baseUrl/reportes/pacientes?fecha=$fecha'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body)
        };
      } else {
        // Manejo de errores controlados por el backend
        final error = json.decode(response.body);
        return {
          'success': false, 
          'message': error['message'] ?? 'Error al cargar el reporte'
        };
      }
    } catch (e) {
      // Manejo de errores de red o excepciones inesperadas
      return {
        'success': false, 
        'message': 'Error de conexión con el servidor: $e'
      };
    }
  }
}