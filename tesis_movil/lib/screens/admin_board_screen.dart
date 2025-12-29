// lib/screens/admin_board_screen.dart (Contenido COMPLETO)

import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'admin_user_create_form.dart'; 
import 'user_edit_form_modal.dart'; // <--- El modal de edición
import 'reportes_screen.dart'; // <--- IMPORTACIÓN DEL NUEVO MÓDULO

class AdminBoardScreen extends StatefulWidget {
  const AdminBoardScreen({super.key});

  @override
  State<AdminBoardScreen> createState() => _AdminBoardScreenState();
}

class _AdminBoardScreenState extends State<AdminBoardScreen> {
  final AuthService _authService = AuthService();
  List<Usuario> _usuarios = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Carga inicial al entrar
    _fetchUsers(); 
  }

  // Función para listar todos los usuarios
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    _usuarios = await _authService.getAllUsers();
    setState(() {
      _isLoading = false;
    });
  }

  // Función que muestra el modal de edición
  void _showEditForm(Usuario usuario) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      builder: (ctx) => UserEditFormModal(usuario: usuario),
    );

    // Si el modal se cierra y devuelve 'true', recarga la lista
    if (result == true) {
      _fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Personal'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Usuarios Registrados'),
              Tab(icon: Icon(Icons.person_add), text: 'Crear Usuario'),
            ],
          ),
          actions: [
            // --- NUEVO BOTÓN PARA CONSULTAR REPORTES ---
            IconButton(
              icon: const Icon(Icons.bar_chart, size: 28),
              tooltip: 'Consultar Reportes',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportesScreen()),
                );
              },
            ),
            // --------------------------------------------
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchUsers,
            )
          ],
        ),
        body: TabBarView(
          children: [
            // PESTAÑA 1: LISTADO DE USUARIOS (Con Pull to Refresh)
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchUsers,
                    child: ListView.builder(
                      itemCount: _usuarios.length,
                      itemBuilder: (ctx, index) {
                        final user = _usuarios[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user.activo ? Colors.green[700] : Colors.red[700],
                              child: Text(user.nombre[0].toUpperCase()),
                            ),
                            title: Text('${user.nombre} ${user.apellido} (${user.cedula})'),
                            subtitle: Text('Rol: ${user.nombreRol}\nEmail: ${user.email}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.deepPurple),
                              onPressed: () => _showEditForm(user), // Abrir el modal de edición
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                  ),

            // PESTAÑA 2: FORMULARIO DE CREACIÓN (Llama al widget de creación)
            AdminUserCreateForm(onUserCreated: _fetchUsers),
          ],
        ),
      ),
    );
  }
}