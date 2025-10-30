// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/rol.dart';
import '../models/usuario.dart'; // Importar el nuevo modelo Usuario

class AuthService {
  final storage = const FlutterSecureStorage();

  // 1. Iniciar Sesión (Login)
  Future<Map<String, dynamic>> signIn({required String cedula, required String password}) async {
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
      // Guardar el token de acceso de forma segura
      await storage.write(key: 'jwt_token', value: responseBody['accessToken']);
      await storage.write(key: 'user_rol', value: responseBody['rol']); // Guardar el rol
      
      return {'success': true, 'data': responseBody};
    } else {
      return {'success': false, 'message': responseBody['message'] ?? 'Error desconocido'};
    }
  }

  // 2. Cerrar Sesión
  Future<void> signOut() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_rol');
  }

  // 3. Obtener el Token
  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  // 4. Obtener el Rol
  Future<String?> getRol() async {
    return await storage.read(key: 'user_rol');
  }

  // 5. Obtener Roles desde el API
  Future<List<Rol>> getRoles() async {
    final token = await getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse(ApiConfig.getRolesUrl),
      headers: <String, String>{
        'x-access-token': token,
      },
    );

    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((data) => Rol(
        id: data['id_rol'],
        nombre: data['nombre_rol'],
      )).toList();
    } else {
      // Manejo de error si el token es inválido o falla la conexión
      return []; 
    }
  }

  // 6. Crear Usuario (Solo Admin)
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

    final response = await http.post(
      Uri.parse(ApiConfig.createUserUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'x-access-token': token, // Enviar el token del Admin
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
      return {'success': false, 'message': responseBody['message'] ?? 'Error desconocido al crear usuario'};
    }
  }

  // 7. Listar todos los usuarios (Solo Admin)
  Future<List<Usuario>> getAllUsers() async {
    final token = await getToken();
    if (token == null) return [];

    // Usamos la misma URL que definimos para crear, pero con método GET: /api/admin/users
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
      // Manejar el error (ej. token expirado)
      return []; 
    }
  }

  // 8. Actualizar usuario (Solo Admin)
  Future<Map<String, dynamic>> updateUserDetails({
    required String cedula,
    required Map<String, dynamic> updateData,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No autorizado.'};

    final response = await http.put(
      // URL de edición: /api/admin/users/:cedula
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
      return {'success': false, 'message': responseBody['message'] ?? 'Error desconocido al actualizar.'};
    }
  }
}

