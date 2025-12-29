// lib/screens/admin_board_screen.dart (Contenido COMPLETO)

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
                // --- BUSCADOR CON MINI MENÚ (AUTOCOMPLETE) ---
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
                      _showEditForm(selection); // Abre edición al seleccionar
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: "Buscar cédula...",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => controller.clear(),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          filled: true,
                          fillColor: const Color.fromARGB(255, 14, 0, 0),
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
                                  title: Text(option.cedula, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text("${option.nombre} ${option.apellido}"),
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