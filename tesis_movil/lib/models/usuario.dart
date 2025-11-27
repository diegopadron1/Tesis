// lib/models/usuario.dart

class Usuario {
  final String cedula;
  final String nombre;
  final String apellido;
  final String email;
  final int? idRol;       // Cambio a opcional (?) para evitar errores si viene null
  final String? nombreRol; // Cambio a opcional
  final bool activo;

  Usuario({
    required this.cedula,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.idRol,
    this.nombreRol,
    this.activo = true, // Valor por defecto si no viene
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      cedula: json['cedula'] ?? '', // Si viene null, pone cadena vacía
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      email: json['email'] ?? '',
      idRol: json['id_rol'],
      // Verificación de seguridad para obtener el nombre del rol
      nombreRol: (json['rol'] != null) ? json['rol']['nombre_rol'] : null,
      activo: json['activo'] ?? true,
    );
  }
}