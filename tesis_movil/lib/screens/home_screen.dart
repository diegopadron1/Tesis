// lib/screens/home_screen.dart (Modificado)
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_board_screen.dart';
import 'resident/resident_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  String? _rol;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRol();
  }

  Future<void> _loadUserRol() async {
    _rol = await _authService.getRol();
    setState(() {
      _isLoading = false;
    });
  }
  
  void _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/'); // Navegar al login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _isLoading 
          ? null 
          : Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Text(
                      'Bienvenido, ${_rol ?? 'Usuario'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  // Opción solo para el Administrador
                  if (_rol == 'Administrador')
                    ListTile(
                      leading: const Icon(Icons.group_add, color: Colors.white),
                      title: const Text('Gestión de Personal', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context); // Cierra el drawer
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminBoardScreen()));
                      },
                    ),
                  
                  // Opciones de Pacientes/Triaje (futuras)
                  if (_rol == 'Residente')
                    ListTile(
                      leading: const Icon(Icons.medical_services, color: Colors.white),
                      title: const Text('Registro de Pacientes', style: TextStyle(color: Colors.white)),
                      onTap: () {
                       Navigator.pop(context);
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const ResidentHomeScreen()));
                     },
                   ),
                  
                  // ... otras opciones según el rol
                ],
              ),
            ),
      body: Center(
        child: _isLoading 
            ? const CircularProgressIndicator()
            : Text(
                '¡Login Exitoso! Rol: ${_rol ?? 'No definido'}.', 
                style: const TextStyle(fontSize: 18)
              ),
      ),
    );
  }
}