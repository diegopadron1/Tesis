// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/rol.dart';
import '../services/auth_service.dart';

class AdminUserCreateForm extends StatefulWidget {
  final VoidCallback onUserCreated;

  const AdminUserCreateForm({
    super.key, 
    required this.onUserCreated
  });

  @override
  State<AdminUserCreateForm> createState() => _AdminUserCreateFormState();
}

class _AdminUserCreateFormState extends State<AdminUserCreateForm> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<Rol> _roles = [];
  Rol? _selectedRol;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    setState(() {
      _isLoading = true;
    });
    _roles = await _authService.getRoles();
    setState(() {
      _isLoading = false;
      // Seleccionar el primer rol por defecto si existe (opcional)
      // if (_roles.isNotEmpty) _selectedRol = _roles.first; 
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedRol != null) {
      setState(() {
        _isLoading = true;
      });

      final result = await _authService.createUserByAdmin(
        cedula: _cedulaController.text,
        nombre: _nombreController.text,
        apellido: _apellidoController.text,
        email: _emailController.text,
        password: _passwordController.text,
        idRol: _selectedRol!.id,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
       final cedulaCreada = result['usuario'] != null ? result['usuario']['cedula'] : 'Desconocido';
        
        // Opción más simple y segura:
        _showSnackbar('✅ Usuario creado. Cédula: $cedulaCreada', Colors.green);
        
        _formKey.currentState!.reset();
      } else {
        _showSnackbar('❌ Error: ${result['message']}', Colors.red);
      }
    } else {
       _showSnackbar('Por favor complete todos los campos y seleccione un Rol.', Colors.orange);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Personal'),
      ),
      body: _isLoading && _roles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildTextField(_cedulaController, 'Cédula', Icons.badge),
                    _buildTextField(_nombreController, 'Nombre', Icons.person_outline),
                    _buildTextField(_apellidoController, 'Apellido', Icons.person_outline),
                    _buildTextField(_emailController, 'Correo Electrónico', Icons.email, isEmail: true),
                    _buildTextField(_passwordController, 'Contraseña', Icons.lock, isPassword: true),
                    
                    const SizedBox(height: 20),
                    _buildRoleDropdown(),
                    const SizedBox(height: 30),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('REGISTRAR PERSONAL', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        obscureText: isPassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingrese el $label.';
          }
          if (isEmail && !value.contains('@')) {
            return 'Ingrese un correo válido.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<Rol>(
      decoration: const InputDecoration(
        labelText: 'Rol del Personal',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.people),
      ),
      value: _selectedRol,
      hint: const Text('Seleccione un Rol'),
      isExpanded: true,
      items: _roles.map((Rol rol) {
        return DropdownMenuItem<Rol>(
          value: rol,
          child: Text(rol.nombre),
        );
      }).toList(),
      onChanged: (Rol? newValue) {
        setState(() {
          _selectedRol = newValue;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Debe seleccionar un Rol.';
        }
        return null;
      },
    );
  }
}