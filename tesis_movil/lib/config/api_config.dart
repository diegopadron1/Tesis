class ApiConfig {
  // Asegúrate de usar la dirección IP REAL de tu computadora
  // Si usas 'localhost' o '127.0.0.1', el emulador/dispositivo no podrá encontrar el API.
  // Reemplaza X.X.X.X con la IP de tu PC en la red local.
  static const String baseUrl = 'http://192.168.68.104:3000/api'; 
  
  // URL de prueba para el emulador Android si usas 10.0.2.2:
  // static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  static const String signinUrl = '$baseUrl/auth/signin';
  static const String createUserUrl = '$baseUrl/admin/users';
  static const String getRolesUrl = '$baseUrl/roles';
  static const String registerPatientUrl = '$baseUrl/pacientes';
  static const String motivoConsultaUrl = "$baseUrl/motivo-consulta";
  static const String diagnosticoUrl = "$baseUrl/diagnostico"; 
  static const String examenFisicoUrl = "$baseUrl/examen/fisico";
  static const String examenFuncionalUrl = "$baseUrl/examen/funcional";
  static const String antecedentesPersonalUrl = "$baseUrl/antecedentes/personal";
  static const String antecedentesFamiliarUrl = "$baseUrl/antecedentes/familiar";
  static const String antecedentesHabitosUrl = "$baseUrl/antecedentes/habitos";
  static const String farmaciaInventarioUrl = "$baseUrl/farmacia/inventario";
  static const String farmaciaCrearUrl = "$baseUrl/farmacia/medicamentos";
   static const String farmaciaStockUrl = "$baseUrl/farmacia/medicamentos"; 
  static const String farmaciaSalidaUrl = "$baseUrl/farmacia/medicamentos";
  static const String enfermeriaOrdenesUrl = "$baseUrl/enfermeria/ordenes/pendientes";
  static const String enfermeriaSolicitarUrl = "$baseUrl/enfermeria/solicitar";
  static const String historiaBaseUrl = "$baseUrl/historia"; 
  static const String historiaSeccionUrl = "$baseUrl/historia/seccion"; 
  static const String historiaOrdenUrl = "$baseUrl/historia/orden";
} 