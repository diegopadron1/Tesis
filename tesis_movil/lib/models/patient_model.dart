class Paciente {
  final String cedula;
  final String nombre;
  final String apellido;
  final String telefono;
  final String fechaNacimiento;
  final String lugarNacimiento;
  final String direccionActual;
  final String? estadoCivil;
  final String? religion;

  Paciente({
    required this.cedula,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.fechaNacimiento,
    required this.lugarNacimiento,
    required this.direccionActual,
    this.estadoCivil,
    this.religion,
  });

  Map<String, dynamic> toJson() {
    return {
      'cedula': cedula,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'fecha_nacimiento': fechaNacimiento,
      'lugar_nacimiento': lugarNacimiento,
      'direccion_actual': direccionActual,
      'estado_civil': estadoCivil, 
      'religion': religion,
    };
  }
}

class ContactoEmergencia {
  final String nombre;
  final String apellido;
  final String? cedulaContacto;
  final String parentesco;
  final String telefono;

  ContactoEmergencia({
    required this.nombre,
    required this.apellido,
    this.cedulaContacto,
    required this.parentesco,
    required this.telefono,
  });

  Map<String, dynamic> toJson() {
    return {
      // El backend espera nombre y apellido separados
      'nombre': nombre,
      'apellido': apellido,
      'cedula_contacto': cedulaContacto,
      'parentesco': parentesco,
      'telefono': telefono,
    };
  }
}

class PatientRegistrationPayload {
  final Paciente paciente;
  final ContactoEmergencia contactoEmergencia;

  PatientRegistrationPayload({
    required this.paciente,
    required this.contactoEmergencia,
  });

  Map<String, dynamic> toJson() {
    return {
      'paciente': paciente.toJson(),
      // El backend espera 'contactoEmergencia' en camelCase
      'contactoEmergencia': contactoEmergencia.toJson(),
    };
  }
}