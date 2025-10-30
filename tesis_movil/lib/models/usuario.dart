// lib/models/usuario.dart

class Usuario {
  final String cedula;
  final String nombre;
  final String apellido;
  final String email;
  final int idRol;
  final String nombreRol;
  bool activo;

  Usuario({
    required this.cedula,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.idRol,
    required this.nombreRol,
    required this.activo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      cedula: json['cedula'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      email: json['email'],
      idRol: json['id_rol'],
      nombreRol: json['rol']['nombre_rol'], // Obtenido de la relación
      activo: json['activo'],
    );
  }
}