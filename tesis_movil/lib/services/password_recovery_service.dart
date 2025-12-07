import 'dart:convert';
import 'package:http/http.dart' as http;

class PasswordRecoveryService {
  // Ajusta esta URL si usas dispositivo físico (usa tu IP local en vez de 10.0.2.2)
  final String baseUrl = "http://10.0.2.2:3000/api/auth";

  // 1. Enviar solicitud de código al correo
  Future<Map<String, dynamic>> sendRecoveryCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // 2. Enviar el código y la nueva contraseña
  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al cambiar contraseña'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }
}