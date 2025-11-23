// lib/screens/home_screen.dart (Modificado)
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_board_screen.dart';
import 'resident/resident_home_screen.dart';
import 'pharmacy/farmacia_inventory_screen.dart'; // 1. IMPORTAR LA PANTALLA DE FARMACIA

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
    // Asegúrate de que en main.dart o routes tengas definida la ruta '/' o usa pushReplacement a LoginScreen()
    Navigator.of(context).pushReplacementNamed('/'); 
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.account_circle, size: 50, color: Colors.white),
                        const SizedBox(height: 10),
                        Text(
                          'Bienvenido,',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          _rol ?? 'Usuario',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // OPCIÓN 1: ADMINISTRADOR
                  if (_rol == 'Administrador')
                    ListTile(
                      leading: const Icon(Icons.group_add, color: Colors.white),
                      title: const Text('Gestión de Personal', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context); 
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminBoardScreen()));
                      },
                    ),
                  
                  // OPCIÓN 2: RESIDENTE
                  if (_rol == 'Residente')
                    ListTile(
                      leading: const Icon(Icons.medical_services, color: Colors.white),
                      title: const Text('Módulo de Residentes', style: TextStyle(color: Colors.white)),
                      onTap: () {
                       Navigator.pop(context);
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const ResidentHomeScreen()));
                     },
                   ),

                  // OPCIÓN 3: FARMACIA (NUEVO)
                  if (_rol == 'Farmacia')
                    ListTile(
                      leading: const Icon(Icons.local_pharmacy, color: Colors.white),
                      title: const Text('Gestión de Inventario', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const FarmaciaInventoryScreen()));
                      },
                    ),
                  
                  const Divider(color: Colors.grey),
                  
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                    title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
      body: Center(
        child: _isLoading 
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _rol == 'Farmacia' ? Icons.local_pharmacy : Icons.local_hospital,
                    size: 100,
                    color: Colors.deepPurple.shade200,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '¡Hola, ${_rol ?? 'Usuario'}!', 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Usa el menú lateral (arriba a la izquierda)\npara acceder a tus módulos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }
}