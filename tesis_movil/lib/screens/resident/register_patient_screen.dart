import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../../models/patient_model.dart'; 
import '../../services/patient_service.dart';
import 'resident_home_screen.dart';

class RegisterPatientScreen extends StatefulWidget {
  // Definimos el parámetro para recibir la cédula desde la búsqueda
  final String? cedulaPrevia;

  const RegisterPatientScreen({super.key, this.cedulaPrevia});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final PatientService _patientService = PatientService();
  bool _isLoading = false;

  // --- CONTROLADORES DEL PACIENTE ---
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _lugarNacimientoController = TextEditingController();
  final _direccionActualController = TextEditingController();
  final _estadoCivilController = TextEditingController();
  final _religionController = TextEditingController();

  // --- CONTROLADORES DEL CONTACTO DE EMERGENCIA ---
  final _contactoNombreController = TextEditingController();
  final _contactoApellidoController = TextEditingController();
  final _contactoCedulaController = TextEditingController();
  final _contactoParentescoController = TextEditingController();
  final _contactoTelefonoController = TextEditingController(); // NUEVO: Controlador para teléfono del contacto

  @override
  void initState() {
    super.initState();
    // Si recibimos la cédula, la escribimos automáticamente
    if (widget.cedulaPrevia != null) {
      _cedulaController.text = widget.cedulaPrevia!;
    }
  }

  @override
  void dispose() {
    // Limpieza de controladores
    _cedulaController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _fechaNacimientoController.dispose();
    _lugarNacimientoController.dispose();
    _direccionActualController.dispose();
    _estadoCivilController.dispose();
    _religionController.dispose();
    
    _contactoNombreController.dispose();
    _contactoApellidoController.dispose();
    _contactoCedulaController.dispose();
    _contactoParentescoController.dispose();
    _contactoTelefonoController.dispose(); // NUEVO: Dispose
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      _fechaNacimientoController.text = DateFormat('yyyy-MM-dd').format(picked); 
    }
  }

  int _calcularEdad(String fecha) {
    try {
      final nac = DateTime.parse(fecha);
      final hoy = DateTime.now();
      int edad = hoy.year - nac.year;
      if (hoy.month < nac.month || (hoy.month == nac.month && hoy.day < nac.day)) {
        edad--;
      }
      return edad;
    } catch (e) {
      return 0;
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Creamos el objeto Paciente usando el modelo nuevo
    final patientData = Paciente(
      cedula: _cedulaController.text.trim(),
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      fechaNacimiento: _fechaNacimientoController.text,
      lugarNacimiento: _lugarNacimientoController.text.trim(),
      direccionActual: _direccionActualController.text.trim(),
      estadoCivil: _estadoCivilController.text.isEmpty ? null : _estadoCivilController.text,
      religion: _religionController.text.isEmpty ? null : _religionController.text,
    );

    // Creamos el objeto ContactoEmergencia
    final contactData = ContactoEmergencia(
      nombre: _contactoNombreController.text.trim(),
      apellido: _contactoApellidoController.text.trim(),
      cedulaContacto: _contactoCedulaController.text.isEmpty ? null : _contactoCedulaController.text,
      parentesco: _contactoParentescoController.text.trim(),
      telefono: _contactoTelefonoController.text.trim(), // NUEVO: Enviamos el teléfono al modelo
    );

    final payload = PatientRegistrationPayload(
      paciente: patientData,
      contactoEmergencia: contactData,
    );

    final result = await _patientService.registerPatient(payload);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']!),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        // Redirigir al Home del Residente con los datos
        final newPatientMap = {
          'cedula': _cedulaController.text,
          'nombre': _nombreController.text,
          'apellido': _apellidoController.text,
          'nombre_apellido': "${_nombreController.text} ${_apellidoController.text}",
          'edad': _calcularEdad(_fechaNacimientoController.text),
          'fecha_nacimiento': _fechaNacimientoController.text
        };

        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (context) => ResidentHomeScreen(pacienteData: newPatientMap)
          )
        );
      }
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Paciente'),
        backgroundColor: Colors.blue[800], 
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.cedulaPrevia != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(10),
                  color: Colors.orange[100],
                  child: Text(
                    "La cédula ${widget.cedulaPrevia} no estaba registrada. Por favor complete los datos.", 
                    style: TextStyle(color: Colors.orange[900])
                  ),
                ),

              // --- SECCIÓN 1: DATOS PERSONALES ---
              _buildSectionTitle('1. Datos Personales'),
              const SizedBox(height: 15),

              _buildTextFormField(
                controller: _cedulaController,
                labelText: 'Cédula de Identidad',
                keyboardType: TextInputType.number,
                isRequired: true,
                validator: (value) => value!.length < 4 || value.length > 15 ? 'Cédula inválida' : null,
              ),
              const SizedBox(height: 15),

              Row(children: [
                Expanded(child: _buildTextFormField(controller: _nombreController, labelText: 'Nombre(s)', isRequired: true)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextFormField(controller: _apellidoController, labelText: 'Apellido(s)', isRequired: true)),
              ]),
              const SizedBox(height: 15),

              _buildTextFormField(
                controller: _telefonoController,
                labelText: 'Teléfono Paciente',
                keyboardType: TextInputType.phone,
                isRequired: true,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _fechaNacimientoController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Fecha de Nacimiento *',
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                validator: (value) => value!.isEmpty ? 'Seleccione fecha' : null,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 15),
              
              _buildTextFormField(controller: _lugarNacimientoController, labelText: 'Lugar de Nacimiento', isRequired: true),
              const SizedBox(height: 15),
              _buildTextFormField(controller: _direccionActualController, labelText: 'Dirección Actual', isRequired: true, maxLines: 2),
              const SizedBox(height: 15),

              Row(children: [
                Expanded(child: _buildTextFormField(controller: _estadoCivilController, labelText: 'Estado Civil')),
                const SizedBox(width: 10),
                Expanded(child: _buildTextFormField(controller: _religionController, labelText: 'Religión')),
              ]),
              const SizedBox(height: 40),

              // --- SECCIÓN 2: CONTACTO DE EMERGENCIA ---
              _buildSectionTitle('2. Contacto de Emergencia'),
              const SizedBox(height: 15),

              Row(children: [
                Expanded(child: _buildTextFormField(controller: _contactoNombreController, labelText: 'Nombre Contacto', isRequired: true)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextFormField(controller: _contactoApellidoController, labelText: 'Apellido Contacto', isRequired: true)),
              ]),
              const SizedBox(height: 15),

              _buildTextFormField(controller: _contactoParentescoController, labelText: 'Parentesco', isRequired: true),
              const SizedBox(height: 15),

              // NUEVO CAMPO: TELÉFONO DEL CONTACTO
              _buildTextFormField(
                controller: _contactoTelefonoController, 
                labelText: 'Teléfono Contacto', 
                keyboardType: TextInputType.phone,
                isRequired: true
              ),
              const SizedBox(height: 15),

              _buildTextFormField(
                controller: _contactoCedulaController,
                labelText: 'Cédula Contacto (Opcional)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitForm,
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.save_as, size: 28),
                label: Text(_isLoading ? 'Registrando...' : 'Registrar y Continuar', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.blue[800]));
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) return 'Obligatorio.';
        return validator?.call(value);
      },
    );
  }
}