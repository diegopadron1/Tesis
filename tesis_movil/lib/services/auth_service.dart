import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/rol.dart';
import '../models/usuario.dart';

class AuthService {
  final storage = const FlutterSecureStorage();

  // 1. Iniciar Sesión (Login)
  Future<Map<String, dynamic>> signIn({required String cedula, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.signinUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'cedula': cedula,
          'password': password,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Guardar datos de sesión de forma segura
        await storage.write(key: 'jwt_token', value: responseBody['accessToken']);
        await storage.write(key: 'user_rol', value: responseBody['rol']);
        await storage.write(key: 'cedula', value: responseBody['cedula']);
        
        // --- NUEVO: GUARDAR NOMBRE Y APELLIDO ---
        // Asegúrate de que tu backend envíe estos campos en el JSON de respuesta
        if (responseBody['nombre'] != null) {
          await storage.write(key: 'nombre', value: responseBody['nombre']);
        }
        if (responseBody['apellido'] != null) {
          await storage.write(key: 'apellido', value: responseBody['apellido']);
        }
        // ----------------------------------------
        
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 2. Cerrar Sesión
  Future<void> signOut() async {
    await storage.deleteAll(); // Borra todo (token, rol, cedula)
  }

  // 3. Obtener el Token
  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  // 4. Obtener el Rol
  Future<String?> getRol() async {
    return await storage.read(key: 'user_rol');
  }

  // 5. Obtener Cédula (Necesario para Enfermería y otros módulos)
  Future<String?> getCedulaUsuario() async {
    return await storage.read(key: 'cedula');
  }

  // 6. Método para obtener el nombre completo del usuario logueado
  Future<String?> getNombreCompleto() async {
    String? nombre = await storage.read(key: 'nombre');
    String? apellido = await storage.read(key: 'apellido');
    
    if (nombre != null && apellido != null) {
      return "$nombre $apellido";
    } else if (nombre != null) {
      return nombre;
    }
    return null; // Retorna null si no hay datos guardados
  }

  // 7. Verificar si está logueado
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // --- MÉTODOS DE ADMINISTRADOR ---

  // 8. Obtener Roles desde el API
  Future<List<Rol>> getRoles() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getRolesUrl),
        headers: <String, String>{
          'x-access-token': token,
        },
      );

      if (response.statusCode == 200) {
        List jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((data) => Rol.fromJson(data)).toList();
      } else {
        return []; 
      }
    } catch (e) {
      return [];
    }
  }

  // 9. Crear Usuario (Solo Admin)
  Future<Map<String, dynamic>> createUserByAdmin({
    required String cedula,
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required int idRol,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No autorizado.'};

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createUserUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-access-token': token, 
        },
        body: jsonEncode(<String, dynamic>{
          'cedula': cedula,
          'nombre': nombre,
          'apellido': apellido,
          'email': email,
          'password': password,
          'id_rol': idRol,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': responseBody['message'], 'usuario': responseBody['usuario']};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 10. Listar todos los usuarios (Solo Admin)
  Future<List<Usuario>> getAllUsers() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.createUserUrl), 
        headers: <String, String>{
          'x-access-token': token,
        },
      );

      if (response.statusCode == 200) {
        List jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((data) => Usuario.fromJson(data)).toList();
      } else {
        return []; 
      }
    } catch (e) {
      return [];
    }
  }

  // 11. Actualizar usuario (Solo Admin)
  Future<Map<String, dynamic>> updateUserDetails({
    required String cedula,
    required Map<String, dynamic> updateData,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No autorizado.'};

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.createUserUrl}/$cedula'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-access-token': token,
        },
        body: jsonEncode(updateData),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseBody['message']};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}

