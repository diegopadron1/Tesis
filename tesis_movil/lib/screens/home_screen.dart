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
import '../theme_notifier.dart'; 

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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        leading: const Icon(Icons.notification_important, color: Colors.amber, size: 35),
        backgroundColor: Colors.indigo[900], 
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseHomeScreen()));
            },
            child: const Text("VER ÓRDENES", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
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
          title: const Text('Gestionar Salida', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
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
          title: const Text('Finalizar Caso', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
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
            decoration: BoxDecoration(color: color?.withValues(alpha: 0.15) ?? Colors.grey.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icono, color: color),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
        title: Text("Confirmar $seleccion", style: const TextStyle(color: Colors.black)),
        content: Text("¿Está seguro de finalizar este paciente como '$seleccion'?\n\nEsta acción cerrará la carpeta.", style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: color));
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
              title: const Text("Atender Paciente", style: TextStyle(color: Colors.black)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ubicación actual: $ubicacionActual", 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("¿Mover paciente?", style: TextStyle(fontSize: 16, color: Colors.black87)),
                      Switch(
                        value: cambiarZona,
                        activeTrackColor: Colors.blue[200],
                        activeThumbColor: Colors.blue[800], 
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
                        style: const TextStyle(color: Colors.black, fontSize: 16),
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
          backgroundColor: const Color.fromARGB(255, 62, 2, 129),
          foregroundColor: Colors.white,
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
                indicatorColor: Colors.amberAccent,
                indicatorWeight: 5,
                unselectedLabelColor: Colors.white60,
                labelColor: Colors.white,
                labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 0.5),
                tabs: [
                  Tab(icon: Icon(Icons.access_time_filled, size: 22), text: "EN ESPERA"),
                  Tab(icon: Icon(Icons.medical_services, size: 22), text: "EN ATENCIÓN"),
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
              : _buildDefaultWelcome()), 
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
            Text(esEnEspera ? "No hay pacientes en espera" : "No hay pacientes en tratamiento", 
                style: const TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500)),
            if (esEnEspera) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientSearchScreen()));
                },
                icon: const Icon(Icons.person_add),
                label: const Text("Registrar Nuevo Ingreso"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
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
                      'rol': _rol, 
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
            Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.teal.withValues(alpha: 0.2)),
            const SizedBox(height: 20),
            const Text("No hay pacientes pendientes", style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            IconButton(icon: const Icon(Icons.refresh, size: 30, color: Colors.teal), onPressed: _cargarReferidos)
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[900])),
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
                      'rol': _rol, 
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
          Icon(Icons.local_hospital, size: 120, color: Colors.indigo.withValues(alpha: 0.15)),
          const SizedBox(height: 25),
          Text("Bienvenido(a),", style: TextStyle(fontSize: 20, color: Colors.grey[700])),
          Text("$_nombreUsuario", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(20)),
            child: Text("ROL: $_rol", style: TextStyle(color: Colors.indigo[800], fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
          const Text("Hospital Dr. Luis Razetti", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black45, fontSize: 16)),
        ],
      ),
    );
  }
  
  Widget _buildDrawer(BuildContext context) {
      // Usamos el ValueListenableBuilder para saber si estamos en dark mode
      return ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeNotifier.themeMode,
        builder: (context, mode, _) {
          final isDark = mode == ThemeMode.dark;
          final textColor = isDark ? Colors.white : Colors.black87;
          final iconColor = isDark ? Colors.white70 : Colors.indigo[800];

          return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: const BoxDecoration(color: Color.fromARGB(255, 62, 2, 129)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.account_circle, size: 60, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text('Sesión iniciada como:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(
                      _nombreUsuario ?? _rol ?? 'Usuario', 
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              if (_rol == 'Administrador')
                _buildDrawerItem(Icons.group_add, 'Gestión de Personal', textColor, iconColor, () {
                    Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBoardScreen()));
                }),
                
              if (_rol == 'Farmacia')
                _buildDrawerItem(Icons.local_pharmacy, 'Gestión de Inventario', textColor, iconColor, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmaciaInventoryScreen()));
                }),

              if (_rol != null && _rol!.toLowerCase().contains('enfermer'))
                _buildDrawerItem(Icons.health_and_safety, 'Módulo de Enfermería', textColor, iconColor, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NurseHomeScreen()));
                }),

              if (_rol == 'Residente' || _rol == 'Especialista') ...[
                  if (_rol == 'Residente')
                  _buildDrawerItem(Icons.person_search, 'Buscar / Registrar Paciente', textColor, iconColor, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientSearchScreen()));
                  }),
                  const Divider(), 
                  _buildDrawerItem(Icons.edit_note, 'Actualizar Historia Clínica', textColor, iconColor, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoriaClinicaScreen()));
                  }),
                if (_rol == 'Especialista')
                  _buildDrawerItem(Icons.menu_book, 'Consultar Historial', textColor, iconColor, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultarHistoriaScreen()));
                  }),
              ],
              
              const Divider(),

              ListTile(
                leading: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: isDark ? Colors.amber[700] : Colors.indigo[900],
                ),
                title: Text(
                  isDark ? "Cambiar a Modo Claro" : "Cambiar a Modo Oscuro",
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                ),
                trailing: Switch(
                  value: isDark,
                  activeThumbColor: Colors.amber[700],
                  onChanged: (_) => ThemeNotifier.toggleTheme(),
                ),
                onTap: () => ThemeNotifier.toggleTheme(),
              ),

              const Divider(),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: _logout,
              ),
            ],
          ),
        );
      }
    );
  }

  // Widget helper modificado para aceptar colores condicionales
  Widget _buildDrawerItem(IconData icon, String title, Color textColor, Color? iconColor, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 15)),
      onTap: onTap,
    );
  }
}