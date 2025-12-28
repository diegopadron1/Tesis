import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/triaje_service.dart'; 
import '../services/enfermeria_service.dart'; 
import 'admin_board_screen.dart';
import 'resident/patient_search_screen.dart'; 
import 'resident/resident_home_screen.dart'; 
import 'pharmacy/farmacia_inventory_screen.dart';
import 'nurse/nurse_home_screen.dart';
import 'historia_clinica_screen.dart';
import 'consultar_historia_screen.dart'; 
import '../widgets/patient_card.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final TriajeService _triajeService = TriajeService();
  final EnfermeriaService _enfermeriaService = EnfermeriaService(); 
  
  String? _rol;
  String? _nombreUsuario;
  bool _isLoading = true;
  
  List<dynamic> _pacientesUrgencias = []; 
  List<dynamic> _pacientesReferidos = []; 
  bool _loadingPacientes = false;
  int _ordenesPendientesCount = 0; 

  final List<String> _zonas = [
    'Pasillo 1', 'Pasillo 2', 'Quirofanito paciente delicados', 
    'Trauma shock', 'Sillas', 'Libanes', 'USAV'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRol();
  }

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
      } else if (rol == 'Especialista') {
        _cargarReferidos();
      } else if (rol != null && rol.toLowerCase().contains('enfermer')) {
        _verificarOrdenesPendientes();
      }
    }
  }

  // --- LÓGICA DE NOTIFICACIÓN PARA ENFERMERÍA ---
  Future<void> _verificarOrdenesPendientes() async {
    try {
      final ordenes = await _enfermeriaService.getOrdenesPendientes();
      if (mounted && ordenes.isNotEmpty) {
        setState(() {
          _ordenesPendientesCount = ordenes.length;
        });
        _mostrarNotificacionEnfermeria();
      }
    } catch (e) {
      debugPrint("Error verificando órdenes: $e");
    }
  }

  void _mostrarNotificacionEnfermeria() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.all(15),
        content: Text(
          "📢 ATENCIÓN: Hay $_ordenesPendientesCount órdenes médicas pendientes por administrar.",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: const Icon(Icons.notification_important, color: Colors.amber, size: 30),
        backgroundColor: Colors.indigo[700],
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseHomeScreen()));
            },
            child: const Text("VER ÓRDENES", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text("CERRAR", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
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

  Future<void> _cargarReferidos() async {
    setState(() => _loadingPacientes = true);
    final lista = await _triajeService.getPacientesReferidos();
    if (mounted) {
      setState(() {
        _pacientesReferidos = lista;
        _loadingPacientes = false;
      });
    }
  }

  void _finalizarAtencion(int idTriaje) async {
    String? seleccion = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return SimpleDialog(
          title: const Text('Gestionar Salida', style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          children: <Widget>[
            _buildDialogOption(ctx, 'Alta', Icons.check_circle_outline, Colors.green, 'Alta Médica', 'Paciente recuperado'),
            const Divider(),
            _buildDialogOption(ctx, 'Traslado', Icons.local_hospital, Colors.orange, 'Traslado', 'Enviar a especialista'),
            const Divider(),
            _buildDialogOption(ctx, 'Fallecido', Icons.person_off, Colors.grey, 'Fallecido', 'Cierre por deceso'),
          ],
        );
      },
    );
    if (seleccion != null) _procesarCambioEstado(idTriaje, seleccion);
  }

  void _finalizarEspecialista(int idTriaje) async {
    String? seleccion = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return SimpleDialog(
          title: const Text('Finalizar Caso', style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          children: <Widget>[
            _buildDialogOption(ctx, 'Alta', Icons.assignment_turned_in, Colors.teal, 'Alta Médica', 'Cerrar caso clínico'),
            const Divider(),
            _buildDialogOption(ctx, 'Fallecido', Icons.person_off, Colors.grey, 'Fallecido', 'Reportar deceso'),
          ],
        );
      },
    );

    if (seleccion == null) return;
    bool confirm = await _mostrarConfirmacion(seleccion);
    
    if (confirm && mounted) {
      final success = await _triajeService.finalizarCasoEspecialista(idTriaje, seleccion);
      if (!mounted) return;
      if (success) {
        _mostrarSnackBar("Caso cerrado: $seleccion", Colors.teal);
        _cargarReferidos(); 
      } else {
        _mostrarSnackBar("Error al finalizar caso", Colors.red);
      }
    }
  }

  Widget _buildDialogOption(BuildContext ctx, String valor, IconData icono, MaterialColor? color, String titulo, String sub) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(ctx, valor),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color?.withValues(alpha: 0.1) ?? Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icono, color: color),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _mostrarConfirmacion(String seleccion) async {
     return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Confirmar $seleccion"),
        content: Text("¿Está seguro de finalizar este paciente como '$seleccion'?\n\nEsta acción cerrará la carpeta."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
            child: const Text("Confirmar"),
          )
        ],
      )
    ) ?? false;
  }

  void _procesarCambioEstado(int idTriaje, String seleccion) async {
    bool confirm = await _mostrarConfirmacion(seleccion);
    if (confirm && mounted) {
      final success = await _triajeService.cambiarEstado(idTriaje, seleccion);
      if (!mounted) return;
      if (success) {
         _mostrarSnackBar("Estado actualizado: $seleccion", Colors.indigo);
        _cargarPacientes(); 
      } else {
        _mostrarSnackBar("Error al actualizar", Colors.red);
      }
    }
  }

  void _mostrarSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _atenderPaciente(int idTriaje, String ubicacionActual) {
    String? nuevaZonaSeleccionada;
    bool cambiarZona = false;

    showDialog(
      context: context, 
      builder: (dialogContext) { 
        return StatefulBuilder(
          builder: (sbContext, setStateDialog) { 
            return AlertDialog(
              title: const Text("Atender Paciente"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ubicación actual: $ubicacionActual", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("¿Mover paciente?", style: TextStyle(fontSize: 16)),
                      Switch(
                        value: cambiarZona,
                        activeTrackColor: Colors.blue[800], 
                        activeThumbColor: Colors.white,
                        onChanged: (val) {
                          setStateDialog(() {
                            cambiarZona = val;
                            if (!val) nuevaZonaSeleccionada = null; 
                          });
                        },
                      ),
                    ],
                  ),
                  if (cambiarZona)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: "Nueva Zona", border: OutlineInputBorder()),
                        items: _zonas.where((z) => z != ubicacionActual).map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                        onChanged: (val) => setStateDialog(() => nuevaZonaSeleccionada = val),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                  onPressed: () async {
                    if (cambiarZona && nuevaZonaSeleccionada == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Seleccione la nueva zona")));
                      return;
                    }
                    Navigator.pop(dialogContext); 
                    final success = await _triajeService.atenderPaciente(idTriaje, nuevaZonaSeleccionada);
                    if (!mounted) return;
                    if (success) {
                      _mostrarSnackBar("✅ Paciente en atención", Colors.indigo);
                      _cargarPacientes(); 
                    } else {
                      _mostrarSnackBar("❌ Error al actualizar", Colors.red);
                    }
                  },
                  child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _logout() async {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); 
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final enEspera = _pacientesUrgencias.where((p) => p['estado'] == 'En Espera').toList();
    final enAtencion = _pacientesUrgencias.where((p) => p['estado'] != 'En Espera').toList();

    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: Text(_rol == 'Especialista' ? 'Panel de Especialista' : 'Panel Principal'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh), 
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                _rol == 'Especialista' ? _cargarReferidos() : _cargarPacientes();
                if (_rol != null && _rol!.toLowerCase().contains('enfermer')) _verificarOrdenesPendientes();
              }
            ),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
          ],
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
        body: _rol == 'Residente' 
          ? TabBarView(
              children: [
                _buildTabContent(lista: enEspera, esEnEspera: true),
                _buildTabContent(lista: enAtencion, esEnEspera: false),
              ],
            ) 
          : (_rol == 'Especialista' 
              ? _buildSpecialistView() 
              : _buildDefaultWelcome()), // Volvimos al Welcome por defecto para Enfermería
      ),
    );
  }

  Widget _buildTabContent({required List<dynamic> lista, required bool esEnEspera}) {
    if (_loadingPacientes) return const Center(child: CircularProgressIndicator());
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(esEnEspera ? Icons.check_circle_outline : Icons.playlist_add_check, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            Text(esEnEspera ? "No hay pacientes en espera" : "No hay pacientes en tratamiento", style: const TextStyle(fontSize: 18, color: Colors.grey)),
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

    return RefreshIndicator(
      onRefresh: _cargarPacientes,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        itemCount: lista.length,
        itemBuilder: (context, index) {
          final p = lista[index];
          return PatientCard(
            paciente: p,
            onDarAlta: () => _finalizarAtencion(p['id_triaje']),
            onAtender: () => _atenderPaciente(p['id_triaje'], p['ubicacion'] ?? 'Desconocida'),
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
    );
  }

  Widget _buildSpecialistView() {
    if (_loadingPacientes) return const Center(child: CircularProgressIndicator());
    if (_pacientesReferidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.teal.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            const Text("No hay pacientes pendientes", style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 20),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarReferidos)
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Pacientes Trasladados (${_pacientesReferidos.length})", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal[800])),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _pacientesReferidos.length,
            itemBuilder: (ctx, i) {
              final p = _pacientesReferidos[i];
              return PatientCard(
                paciente: p,
                onDarAlta: () => _finalizarEspecialista(p['id_triaje']),
                onAtender: null, 
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
      ],
    );
  }

  Widget _buildDefaultWelcome() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_hospital, size: 100, color: Colors.indigo.withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          Text("Bienvenido(a), $_nombreUsuario", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("Rol: $_rol", style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 20),
          const Text("Sistema de Gestión Hospitalaria Razetti", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
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
                  _nombreUsuario ?? _rol ?? 'Usuario', 
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis,
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