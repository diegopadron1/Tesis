import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../../../models/patient_registration.dart';
import '../../../services/patient_service.dart';


// Es probable que necesites agregar 'intl' a tu pubspec.yaml
// dependencies:
//   intl: ^0.18.1

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final PatientService _patientService = PatientService();
  bool _isLoading = false;

  // --- Controladores de Datos del Paciente ---
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _lugarNacimientoController = TextEditingController();
  final _direccionActualController = TextEditingController();
  final _estadoCivilController = TextEditingController();
  final _religionController = TextEditingController();

  // --- Controladores de Contacto de Emergencia ---
  final _contactoNombreController = TextEditingController();
  final _contactoApellidoController = TextEditingController();
  final _contactoCedulaController = TextEditingController();
  final _contactoParentescoController = TextEditingController();


  @override
  void dispose() {
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
    super.dispose();
  }

  // Selector de Fecha de Nacimiento
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      // Formato YYYY-MM-DD
      _fechaNacimientoController.text = DateFormat('yyyy-MM-dd').format(picked); 
    }
  }

  // ----------------------------------------------------------------------
  // Envío del Formulario
  // ----------------------------------------------------------------------
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 1. Crear objetos PatientData y ContactoEmergencia
    final patientData = PatientData(
      cedula: _cedulaController.text,
      nombre: _nombreController.text,
      apellido: _apellidoController.text,
      telefono: _telefonoController.text,
      fechaNacimiento: _fechaNacimientoController.text,
      lugarNacimiento: _lugarNacimientoController.text,
      direccionActual: _direccionActualController.text,
      estadoCivil: _estadoCivilController.text.isEmpty ? null : _estadoCivilController.text, // Opcional
      religion: _religionController.text.isEmpty ? null : _religionController.text, // Opcional
    );

    final contactData = ContactoEmergencia(
      nombre: _contactoNombreController.text,
      apellido: _contactoApellidoController.text,
      cedulaContacto: _contactoCedulaController.text.isEmpty ? null : _contactoCedulaController.text, // Opcional
      parentesco: _contactoParentescoController.text,
    );

    // 2. Crear el Payload completo
    final payload = PatientRegistrationPayload(
      paciente: patientData,
      contactoEmergencia: contactData,
    );

    // 3. Enviar a la API
    final result = await _patientService.registerPatient(payload);

    // Mostrar el resultado de la operación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']!),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      
      // Limpiar el formulario si fue exitoso
      if (result['success']) {
        _clearForm();
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _cedulaController.clear();
    _nombreController.clear();
    _apellidoController.clear();
    _telefonoController.clear();
    _fechaNacimientoController.clear();
    _lugarNacimientoController.clear();
    _direccionActualController.clear();
    _estadoCivilController.clear();
    _religionController.clear();
    _contactoNombreController.clear();
    _contactoApellidoController.clear();
    _contactoCedulaController.clear();
    _contactoParentescoController.clear();
  }

  // ----------------------------------------------------------------------
  // Construcción de la Interfaz de Usuario (UI)
  // ----------------------------------------------------------------------

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
              // --- SECCIÓN 1: DATOS DEL PACIENTE ---
              _buildSectionTitle('1. Datos Personales del Paciente'),
              const SizedBox(height: 15),

              _buildTextFormField(
                controller: _cedulaController,
                labelText: 'Cédula de Identidad',
                keyboardType: TextInputType.number,
                isRequired: true,
                validator: (value) => value!.length < 5 || value.length > 15 ? 'Cédula debe tener 5-15 dígitos.' : null,
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(child: _buildTextFormField(controller: _nombreController, labelText: 'Nombre(s)', isRequired: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextFormField(controller: _apellidoController, labelText: 'Apellido(s)', isRequired: true)),
                ],
              ),
              const SizedBox(height: 15),

              _buildTextFormField(
                controller: _telefonoController,
                labelText: 'Teléfono',
                keyboardType: TextInputType.phone,
                isRequired: true,
                validator: (value) => value!.length < 10 || value.length > 15 ? 'Teléfono debe tener 10-15 dígitos.' : null,
              ),
              const SizedBox(height: 15),

              // Campo Fecha de Nacimiento (con selector)
              TextFormField(
                controller: _fechaNacimientoController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Fecha de Nacimiento (YYYY-MM-DD) *',
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                validator: (value) => value!.isEmpty ? 'Seleccione la fecha de nacimiento' : null,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 15),
              
              _buildTextFormField(controller: _lugarNacimientoController, labelText: 'Lugar de Nacimiento', isRequired: true),
              const SizedBox(height: 15),
              
              _buildTextFormField(controller: _direccionActualController, labelText: 'Dirección Actual', isRequired: true, maxLines: 2),
              const SizedBox(height: 15),

              // Campos Opcionales
              Row(
                children: [
                  Expanded(child: _buildTextFormField(controller: _estadoCivilController, labelText: 'Estado Civil (Opcional)')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextFormField(controller: _religionController, labelText: 'Religión (Opcional)')),
                ],
              ),
              const SizedBox(height: 40),


              // --- SECCIÓN 2: CONTACTO DE EMERGENCIA ---
              _buildSectionTitle('2. Contacto de Emergencia'),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(child: _buildTextFormField(controller: _contactoNombreController, labelText: 'Nombre Contacto', isRequired: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextFormField(controller: _contactoApellidoController, labelText: 'Apellido Contacto', isRequired: true)),
                ],
              ),
              const SizedBox(height: 15),

              _buildTextFormField(controller: _contactoParentescoController, labelText: 'Parentesco', isRequired: true),
              const SizedBox(height: 15),

              _buildTextFormField(
                controller: _contactoCedulaController,
                labelText: 'Cédula Contacto (Opcional)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),

              // Botón de Envío
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitForm,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                      )
                    : const Icon(Icons.person_add, size: 28),
                label: Text(_isLoading ? 'Registrando...' : 'Registrar y Continuar Triaje', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para el título de las secciones
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0, top: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.w700, 
          color: Colors.blue[800],
        ),
      ),
    );
  }

  // Helper para generar TextFormFields con estilo
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
        ),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Este campo es obligatorio.';
        }
        return validator?.call(value);
      },
    );
  }
}