// lib/screens/user_edit_form_modal.dart

import 'package:flutter/material.dart';
import '../models/rol.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

class UserEditFormModal extends StatefulWidget {
  final Usuario usuario;

  const UserEditFormModal({super.key, required this.usuario});

  @override
  State<UserEditFormModal> createState() => _UserEditFormModalState();
}

class _UserEditFormModalState extends State<UserEditFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  // ... (Controladores inicializados con valores del widget.usuario) ...
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  List<Rol> _roles = [];
  Rol? _selectedRol;
  late bool _activo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = widget.usuario;
    _nombreController = TextEditingController(text: user.nombre);
    _apellidoController = TextEditingController(text: user.apellido);
    _emailController = TextEditingController(text: user.email);
    _passwordController = TextEditingController(); 
    _activo = user.activo;
    _fetchRoles();
  }
  
  // Función para obtener los roles (necesaria para el dropdown)
  Future<void> _fetchRoles() async {
    _roles = await _authService.getRoles();
    if (!mounted) return;

    // Reinicializar _selectedRol como nulo
    Rol? foundRol;

    // 1. Intentar encontrar el rol actual.
    // Usamos firstWhere oElse: para evitar el error de nulo en la función.
    try {
        foundRol = _roles.firstWhere(
            (rol) => rol.id == widget.usuario.idRol,
            // Si no se encuentra, devolvemos un rol que no puede existir (opcional)
            // Aquí realmente no necesitamos orElse si usamos try/catch, 
            // pero es más simple usar una función que lanza un error.
            // Una alternativa simple y directa:
        );
    } catch (e) {
        // Si no lo encuentra (o la lista está vacía), foundRol seguirá siendo null.
        // No hacemos nada, el valor por defecto será el primer rol o null.
    }

    setState(() {
        // 2. Si lo encontramos, lo seleccionamos. 
        if (foundRol != null) {
            _selectedRol = foundRol;
        } 
        // 3. Si no se encontró y la lista tiene elementos, seleccionamos el primero (por seguridad).
        else if (_roles.isNotEmpty) {
            _selectedRol = _roles.first;
        }
    });
  }

  // Función para enviar la edición
  Future<void> _submitEdit() async {
    if (_formKey.currentState!.validate() && _selectedRol != null) {
      setState(() { _isLoading = true; });

      Map<String, dynamic> updateData = {
        'nombre': _nombreController.text,
        'apellido': _apellidoController.text,
        'email': _emailController.text,
        'id_rol': _selectedRol!.id,
        'activo': _activo,
      };
      if (_passwordController.text.isNotEmpty) {
        updateData['password'] = _passwordController.text;
      }

      final result = await _authService.updateUserDetails(
        cedula: widget.usuario.cedula,
        updateData: updateData,
      );

      if (!mounted) return;
      setState(() { _isLoading = false; });

      if (result['success']) {
        // Cierra el modal y devuelve 'true' para indicar que la lista debe recargarse
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('✅ Usuario actualizado.'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('❌ Error: ${result['message']}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Código del Modal con los TextFormField, Dropdown y SwitchListTile)
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text('Editar Usuario: ${widget.usuario.cedula}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            if (_roles.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    _buildTextField(_nombreController, 'Nombre', Icons.person),
                    _buildTextField(_apellidoController, 'Apellido', Icons.person),
                    _buildTextField(_emailController, 'Correo Electrónico', Icons.email, isEmail: true),
                    _buildTextField(_passwordController, 'Nueva Contraseña (Opcional)', Icons.lock, isPassword: true),
                    _buildRoleDropdown(),
                    _buildActiveSwitch(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('GUARDAR CAMBIOS', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // ------------------------------------------------------------------
  // WIDGETS AUXILIARES (DEBEN SER COPIADOS DESDE TU PANTALLA DE CREACIÓN)
  // ------------------------------------------------------------------
  
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isEmail = false}) {
    // Pegar código de TextFormField aquí
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
          if (label.contains('Contraseña') && value!.isEmpty) return null; 
          if (value == null || value.isEmpty && !label.contains('Contraseña')) {
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
    // Pegar código de DropdownButtonFormField aquí
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<Rol>(
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
      ),
    );
  }

  Widget _buildActiveSwitch() {
    // Pegar código de SwitchListTile aquí
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: SwitchListTile(
        title: Text(_activo ? 'Usuario Activo' : 'Usuario Inactivo'),
        secondary: Icon(_activo ? Icons.toggle_on : Icons.toggle_off),
        value: _activo,
        onChanged: (bool newValue) {
          setState(() {
            _activo = newValue;
          });
        },
      ),
    );
  }
}