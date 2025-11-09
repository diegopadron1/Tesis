

// Modelo para el Contacto de Emergencia
class ContactoEmergencia {
  final String nombre;
  final String apellido;
  final String? cedulaContacto; // Opcional según la validación
  final String parentesco;

  ContactoEmergencia({
    required this.nombre,
    required this.apellido,
    this.cedulaContacto,
    required this.parentesco,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'cedula_contacto': cedulaContacto,
      'parentesco': parentesco,
    };
  }
}

// Modelo para los Datos del Paciente (paciente)
class PatientData {
  final String cedula;
  final String nombre;
  final String apellido;
  final String telefono;
  final String fechaNacimiento; // Formato YYYY-MM-DD
  final String lugarNacimiento;
  final String direccionActual;
  final String? estadoCivil; // Opcional en el controlador
  final String? religion; // Opcional en el controlador

  PatientData({
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
      'Estado_civil': estadoCivil,
      'Religion': religion,
    };
  }
}

// Modelo principal para el Payload completo
class PatientRegistrationPayload {
  final PatientData paciente;
  final ContactoEmergencia contactoEmergencia;

  PatientRegistrationPayload({
    required this.paciente,
    required this.contactoEmergencia,
  });

  Map<String, dynamic> toJson() {
    return {
      'paciente': paciente.toJson(),
      'contactoEmergencia': contactoEmergencia.toJson(),
    };
  }
}