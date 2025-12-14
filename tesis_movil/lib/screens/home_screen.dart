import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/triaje_service.dart'; // Servicio para traer la lista
import 'admin_board_screen.dart';
import 'resident/patient_search_screen.dart'; 
import 'resident/resident_home_screen.dart'; // Para navegar al detalle desde la tarjeta
import 'pharmacy/farmacia_inventory_screen.dart';
import 'nurse/nurse_home_screen.dart';
import 'historia_clinica_screen.dart';
import 'consultar_historia_screen.dart'; 
import '../widgets/patient_card.dart'; // El widget de la tarjeta que creamos

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final TriajeService _triajeService = TriajeService();
  
  String? _rol;
  String? _nombreUsuario;
  bool _isLoading = true;
  List<dynamic> _pacientesUrgencias = [];
  bool _loadingPacientes = false;

  @override
  void initState() {
    super.initState();
    _loadUserRol();
  }

  // ... (TUS FUNCIONES _loadUserRol, _cargarPacientes, _darDeAlta, _atenderPaciente, _logout SE QUEDAN IGUAL) ...
  // Copia aquí tus funciones tal cual las tenías.
  // Solo asegúrate de que _cargarPacientes llene _pacientesUrgencias.

  Future<void> _loadUserRol() async {
    final rol = await _authService.getRol();
    final nombre = await _authService.getNombreCompleto();
    if (mounted) {
      setState(() {
        _rol = rol;
        _nombreUsuario = nombre;
        _isLoading = false;
      });
      if (rol == 'Residente') {
        _cargarPacientes();
      }
    }
  }

  Future<void> _cargarPacientes() async {
    setState(() => _loadingPacientes = true);
    final lista = await _triajeService.getTriajesActivos();
    if (mounted) {
      setState(() {
        _pacientesUrgencias = lista;
        _loadingPacientes = false;
      });
    }
  }

  void _darDeAlta(int idTriaje) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Alta"),
        content: const Text("¿Desea dar de alta a este paciente?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Dar de Alta"),
          )
        ],
      )
    ) ?? false;

    if (confirm) {
      final success = await _triajeService.cambiarEstado(idTriaje, 'Alta');
      if (success) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Paciente dado de alta"), backgroundColor: Colors.green));
        _cargarPacientes();
      }
    }
  }

  void _atenderPaciente(int idTriaje) async {
    String? nombreGuardado = await _authService.getNombreCompleto();
    if (!mounted) return;
    String nombreDoctor = nombreGuardado ?? "Residente de Guardia"; 

    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Atención"),
        content: Text("¿Desea marcar este paciente como 'Siendo Atendido' por: $nombreDoctor?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text("Atender"),
          )
        ],
      )
    ) ?? false;

    if (!mounted) return;

    if (confirm) {
      final success = await _triajeService.atenderPaciente(idTriaje, nombreDoctor);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Paciente en atención"), backgroundColor: Colors.indigo));
        _cargarPacientes(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar"), backgroundColor: Colors.red));
      }
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

    // 1. FILTRADO DE LISTAS
    // Creamos dos listas derivadas de la principal
    final enEspera = _pacientesUrgencias.where((p) => p['estado'] == 'En Espera').toList();
    final enAtencion = _pacientesUrgencias.where((p) => p['estado'] != 'En Espera').toList();

    // 2. DefaultTabController
    return DefaultTabController(
      length: 2, // Dos pestañas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Principal'),
          actions: [
            if (_rol == 'Residente')
              IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarPacientes),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
          ],
          // 3. TABBAR (Solo si es Residente)
          bottom: _rol == 'Residente' 
            ? const TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(icon: Icon(Icons.access_time), text: "En Espera"),
                  Tab(icon: Icon(Icons.medical_services_outlined), text: "En Atención"),
                ],
              )
            : null,
        ),
        drawer: _buildDrawer(context),
        
        // 4. TABBAR VIEW (Cuerpo cambiante)
        body: _rol == 'Residente' 
          ? TabBarView(
              children: [
                // Pestaña 1: Lista de Espera
                _buildTabContent(lista: enEspera, esEnEspera: true),
                // Pestaña 2: Lista de Atención
                _buildTabContent(lista: enAtencion, esEnEspera: false),
              ],
            ) 
          : _buildDefaultWelcome(),
      ),
    );
  }

  // --- FUNCIÓN REUTILIZABLE PARA CONSTRUIR LAS LISTAS ---
  Widget _buildTabContent({required List<dynamic> lista, required bool esEnEspera}) {
    if (_loadingPacientes) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado Vacío
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              esEnEspera ? Icons.check_circle_outline : Icons.playlist_add_check, 
              size: 80, 
              color: Colors.grey.withValues(alpha: 0.3)
            ),
            const SizedBox(height: 20),
            Text(
              esEnEspera ? "No hay pacientes en espera" : "No hay pacientes en tratamiento", 
              style: const TextStyle(fontSize: 18, color: Colors.grey)
            ),
            
            // Botón de registro solo en la pestaña de Espera
            if (esEnEspera) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientSearchScreen()));
                },
                icon: const Icon(Icons.person_add),
                label: const Text("Registrar Nuevo Ingreso"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
              )
            ]
          ],
        ),
      );
    }

    // Lista con Datos
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Icon(esEnEspera ? Icons.timelapse : Icons.health_and_safety, color: esEnEspera ? Colors.orange : Colors.blue),
              const SizedBox(width: 8),
              Text(
                esEnEspera ? "Sala de Espera (${lista.length})" : "En Tratamiento (${lista.length})", 
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: esEnEspera ? Colors.orange[800] : Colors.blue[800]
                )
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarPacientes,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              itemCount: lista.length,
              itemBuilder: (context, index) {
                final p = lista[index];
                return PatientCard(
                  paciente: p,
                  onDarAlta: () => _darDeAlta(p['id_triaje']),
                  onAtender: () => _atenderPaciente(p['id_triaje']),
                  onTap: () {
                    final datosParaHome = {
                      'cedula': p['cedula_paciente'],
                      'nombre': p['nombre'],
                      'apellido': p['apellido'],
                      'edad': p['edad'],
                    };
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => ResidentHomeScreen(pacienteData: datosParaHome))
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultWelcome() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Icon(Icons.local_hospital, size: 100, color: Colors.deepPurple.shade200),
           const SizedBox(height: 20),
           Text('¡Hola, ${_rol ?? 'Usuario'}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
           if (_rol == 'Especialista')
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text("Accede al menú lateral para consultar historiales.", style: TextStyle(color: Colors.grey)),
            )
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
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
                Text(
                  _nombreUsuario ?? _rol ?? 'Usuario', // Muestra Nombre. Si no hay, Rol. Si no, 'Usuario'.
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 20, 
                   fontWeight: FontWeight.bold
                ),
                maxLines: 2, // Por si el nombre es muy largo
                overflow: TextOverflow.ellipsis, // Pone "..." si no cabe
              ),
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
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseHomeScreen()));
              },
            ),

          if (_rol == 'Residente' || _rol == 'Especialista') ...[
             
             if (_rol == 'Residente')
              ListTile(
                leading: const Icon(Icons.person_search), 
                title: const Text('Buscar / Registrar Paciente'), 
                subtitle: const Text('Registrar, Diagnosticar, Exámenes'),
                onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientSearchScreen()));
                },
              ),

             const Divider(), 
             
             ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.indigo),
              title: const Text('Actualizar Historia Clínica'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoriaClinicaScreen()));
              },
            ),

            if (_rol == 'Especialista')
              ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.teal),
                title: const Text('Consultar Historial'),
                subtitle: const Text('Modo Lectura'),
                // CORRECCIÓN AQUÍ TAMBIÉN
                tileColor: Colors.teal.withValues(alpha: 0.05),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultarHistoriaScreen()));
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
    );
  }
}