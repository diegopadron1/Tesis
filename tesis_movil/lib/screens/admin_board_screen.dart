// lib/screens/admin_board_screen.dart (Contenido COMPLETO con mejoras de color)

import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'admin_user_create_form.dart'; 
import 'user_edit_form_modal.dart';
import 'reportes_screen.dart';

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
    _fetchUsers(); 
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    _usuarios = await _authService.getAllUsers();
    setState(() {
      _isLoading = false;
    });
  }

  void _showEditForm(Usuario usuario) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      builder: (ctx) => UserEditFormModal(usuario: usuario),
    );

    if (result == true) {
      _fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Personal'),
          backgroundColor: isDark ? null : Colors.indigo[800],
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.amberAccent,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'Usuarios Registrados'),
              Tab(icon: Icon(Icons.person_add), text: 'Crear Usuario'),
            ],
          ),
          actions: [
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
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchUsers,
            )
          ],
        ),
        body: TabBarView(
          children: [
            // PESTAÑA 1: LISTADO DE USUARIOS + BUSCADOR
            Column(
              children: [
                // --- BUSCADOR CON COLORES CORREGIDOS ---
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Autocomplete<Usuario>(
                    displayStringForOption: (Usuario u) => u.cedula,
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Usuario>.empty();
                      }
                      return await _authService.searchUsers(textEditingValue.text);
                    },
                    onSelected: (Usuario selection) {
                      _showEditForm(selection); 
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Buscar cédula...",
                          hintStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black45),
                          prefixIcon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.indigo),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => controller.clear(),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          // CAMBIO: Color de fondo adaptativo (ya no es negro siempre)
                          fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(10),
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final Usuario option = options.elementAt(index);
                                return ListTile(
                                  title: Text(
                                    option.cedula, 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    )
                                  ),
                                  subtitle: Text(
                                    "${option.nombre} ${option.apellido}",
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                                  ),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // --- LISTA DE USUARIOS ---
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _fetchUsers,
                          child: ListView.builder(
                            itemCount: _usuarios.length,
                            itemBuilder: (ctx, index) {
                              final user = _usuarios[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: user.activo ? Colors.green[700] : Colors.red[700],
                                    child: Text(
                                      user.nombre[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    '${user.nombre} ${user.apellido} (${user.cedula})',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Rol: ${user.nombreRol}\nEmail: ${user.email}',
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.edit, color: isDark ? Colors.amberAccent : Colors.indigo),
                                    onPressed: () => _showEditForm(user),
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
            // PESTAÑA 2: FORMULARIO DE CREACIÓN
            AdminUserCreateForm(onUserCreated: _fetchUsers),
          ],
        ),
      ),
    );
  }
}