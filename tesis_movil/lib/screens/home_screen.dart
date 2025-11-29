import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_board_screen.dart';
import 'resident/resident_home_screen.dart';
import 'pharmacy/farmacia_inventory_screen.dart';
import 'nurse/nurse_home_screen.dart';
// 1. IMPORTANTE: Agregamos la importación que faltaba
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
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
                  Text('Bienvenido,', style: const TextStyle(color: Colors.white70)),
                  Text(_rol ?? 'Usuario', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
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
                subtitle: const Text('Gestionar órdenes y solicitudes'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseHomeScreen()));
                },
              ),

            // 2. CAMBIO AQUÍ: LÓGICA PARA RESIDENTES Y ESPECIALISTAS
            if (_rol == 'Residente' || _rol == 'Especialista') ...[
               // El Residente ve su módulo habitual
               if (_rol == 'Residente')
                ListTile(
                  leading: const Icon(Icons.medical_services),
                  title: const Text('Módulo de Residentes'),
                  onTap: () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const ResidentHomeScreen()));
                 },
               ),

               const Divider(), 
               
               // AMBOS ven el nuevo módulo de Historia Clínica
               ListTile(
                leading: const Icon(Icons.history_edu, color: Colors.indigo),
                title: const Text('Historia Clínica'),
                subtitle: const Text('Ver y actualizar pacientes'),
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
      
      // CUERPO DE LA PANTALLA
      body: _rol != null && _rol!.toLowerCase().contains('enfermer')
          ? Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  color: Colors.pink[50],
                  child: Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.pink[800]),
                      const SizedBox(width: 10),
                      Text(
                        "Resumen de Pendientes",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink[900]),
                      ),
                    ],
                  ),
                ),
                const Expanded(child: OrdenesPendientesTab(allowActions: false)),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_hospital, size: 100, color: Colors.deepPurple.shade200),
                  const SizedBox(height: 20),
                  Text('¡Hola, ${_rol ?? 'Usuario'}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('Selecciona una opción del menú lateral.', style: TextStyle(color: Colors.grey)),
                  
                  // 3. TIP VISUAL PARA MÉDICOS
                  if (_rol == 'Residente' || _rol == 'Especialista')
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text('💡 Tip: Usa "Historia Clínica" para\ngestionar pacientes y órdenes.', textAlign: TextAlign.center, style: TextStyle(color: Colors.indigo)),
                    )
                ],
              ),
            ),
    );
  }
}