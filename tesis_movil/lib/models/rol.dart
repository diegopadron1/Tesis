// lib/models/rol.dart

class Rol {
  final int id;
  final String nombre;

  Rol({required this.id, required this.nombre});

  // AGREGADO: Necesario para que AuthService pueda leer la lista de roles
  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(
      id: json['id_rol'],
      nombre: json['nombre_rol'],
    );
  }
}