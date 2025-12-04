import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_board_screen.dart';
// CAMBIO 1: Importamos la pantalla de búsqueda, NO la de ResidentHomeScreen directamente aquí
import 'resident/patient_search_screen.dart'; 
// import 'resident/resident_home_screen.dart'; // <--- YA NO NECESITAS ESTO AQUÍ
import 'pharmacy/farmacia_inventory_screen.dart';
import 'nurse/nurse_home_screen.dart';
import 'historia_clinica_screen.dart';

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
    final rol = await _authService.getRol();
    if (mounted) {
      setState(() {
        _rol = rol;
        _isLoading = false;
      });
    }
  }
  
  void _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); 
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Principal'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_circle, size: 50, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text('Bienvenido,', style: TextStyle(color: Colors.white70)),
                  Text(_rol ?? 'Usuario', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            // ... (Opciones de Admin y Farmacia igual que antes) ...
            if (_rol == 'Administrador')
              ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text('Gestión de Personal'),
                onTap: () {
                  Navigator.pop(context); 
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBoardScreen()));
                },
              ),
              
             if (_rol == 'Farmacia')
              ListTile(
                leading: const Icon(Icons.local_pharmacy),
                title: const Text('Gestión de Inventario'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmaciaInventoryScreen()));
                },
              ),

             if (_rol != null && _rol!.toLowerCase().contains('enfermer'))
               ListTile(
                leading: const Icon(Icons.health_and_safety),
                title: const Text('Módulo de Enfermería'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseHomeScreen()));
                },
              ),

            // CAMBIO 2: LÓGICA CORREGIDA PARA RESIDENTES
            if (_rol == 'Residente' || _rol == 'Especialista') ...[
               if (_rol == 'Residente')
                ListTile(
                  leading: const Icon(Icons.person_search), // Icono más acorde (Buscar paciente)
                  title: const Text('Gestión de Pacientes'), // Nombre más claro
                  subtitle: const Text('Registrar, Diagnosticar, Exámenes'),
                  onTap: () {
                   Navigator.pop(context);
                   // AQUÍ ESTABA EL ERROR: Ahora vamos al BUSCADOR, no al HOME directo
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientSearchScreen()));
                 },
               ),

               const Divider(), 
               
               ListTile(
                leading: const Icon(Icons.history_edu, color: Colors.indigo),
                title: const Text('Historia Clínica (Solo Lectura)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoriaClinicaScreen()));
                },
              ),
            ],
            
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.local_hospital, size: 100, color: Colors.deepPurple.shade200),
             const SizedBox(height: 20),
             Text('¡Hola, ${_rol ?? 'Usuario'}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}