import 'package:flutter/material.dart';
import '../../services/enfermeria_service.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import '../../models/medicamento.dart';

class NurseHomeScreen extends StatefulWidget {
  final int initialIndex; 
  final String? initialCedula;

  const NurseHomeScreen({
    super.key, 
    this.initialIndex = 0, 
    this.initialCedula
  });

  @override
  State<NurseHomeScreen> createState() => _NurseHomeScreenState();
}

class _NurseHomeScreenState extends State<NurseHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  
  String? _cedulaParaSolicitud;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    
    if (widget.initialCedula != null) {
      _cedulaParaSolicitud = widget.initialCedula;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _irASolicitudFarmacia(String cedula) {
    setState(() {
      _cedulaParaSolicitud = cedula;
    });
    _tabController.animateTo(1); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Módulo de Enfermería"),
        backgroundColor: Colors.pink[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
              }
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.assignment_turned_in), text: "Gestionar Órdenes"),
            Tab(icon: Icon(Icons.medication_liquid), text: "Solicitar Medicamento"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OrdenesPendientesTab(
            allowActions: true, 
            onSolicitarFarmacia: _irASolicitudFarmacia, 
          ),
          SolicitudMedicamentoTab(cedulaPrellenada: _cedulaParaSolicitud),
        ],
      ),
    );
  }
}

// --- TAB 1: GESTIÓN DE ÓRDENES ---
class OrdenesPendientesTab extends StatefulWidget {
  final bool allowActions; 
  final Function(String)? onSolicitarFarmacia;

  const OrdenesPendientesTab({
    super.key, 
    this.allowActions = true,
    this.onSolicitarFarmacia,
  });

  @override
  State<OrdenesPendientesTab> createState() => _OrdenesPendientesTabState();
}

class _OrdenesPendientesTabState extends State<OrdenesPendientesTab> {
  final EnfermeriaService _service = EnfermeriaService();
  late Future<List<dynamic>> _ordenesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _ordenesFuture = _service.getOrdenesPendientes();
    });
  }

  void _actualizarOrden(int idOrden, String nuevoEstatus, {String? obs}) async {
    String observaciones = obs ?? "Suministro realizado exitosamente.";
    
    if (nuevoEstatus == 'NO_REALIZADA' && obs == null) {
      final motivo = await showDialog<String>(
        context: context,
        builder: (ctx) {
          String razon = "";
          return AlertDialog(
            title: const Text("Reportar No Realizado"),
            content: TextField(
              onChanged: (v) => razon = v,
              decoration: const InputDecoration(labelText: "Motivo (Ej: Paciente se negó)"),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
              TextButton(onPressed: () => Navigator.pop(ctx, razon), child: const Text("Confirmar")),
            ],
          );
        },
      );
      if (motivo == null || motivo.isEmpty) return;
      observaciones = motivo;
    }

    final res = await _service.actualizarOrden(idOrden, nuevoEstatus, observaciones);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message']),
        backgroundColor: res['success'] ? Colors.green : Colors.red,
      ));
      if (res['success']) _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _ordenesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No hay órdenes pendientes."));
        }

        final list = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final orden = list[i];
              final paciente = orden['Paciente'] ?? {};
              final medInfo = orden['medicamento'] ?? {}; 
              
              // --- DATOS DEL PACIENTE ---
              final nombreCompleto = paciente['nombre_apellido'] ?? 'Desconocido';
              final cedulaP = paciente['cedula'] ?? orden['cedula_paciente'] ?? '';
              final edad = paciente['edad']?.toString() ?? '?'; 
              
              // Intentamos obtener la ubicación de varios lugares posibles del JSON
              final zona = orden['ubicacion'] ?? paciente['ubicacion'] ?? 'Ubicación pendiente';

              // --- DATOS DEL MEDICAMENTO ---
              final nombreFarma = medInfo['nombre'] ?? 'Sin fármaco asignado';
              final concentracion = medInfo['concentracion'] ?? '';
              final indicaciones = orden['indicaciones_inmediatas'] ?? 'Ninguna';
              final tratamiento = orden['tratamientos_sugeridos'] ?? 'No especificado';
              final dosis = orden['requerimiento_medicamentos'] ?? 'Según criterio';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ExpansionTile(
                  initiallyExpanded: false, 
                  leading: CircleAvatar(
                    backgroundColor: Colors.pink[700], 
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  // TÍTULO: Nombre del Paciente
                  title: Text(
                    nombreCompleto, 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.pink[800]),
                  ),
                  // SUBTÍTULO: Datos demográficos y Zona
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text("C.I: $cedulaP", style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 10),
                          Icon(Icons.cake, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text("$edad años", style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // ZONA DESTACADA
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3))
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              zona, 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue[800])
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50], 
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15))
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NOMBRE DEL MEDICAMENTO + CONCENTRACIÓN
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.medication_liquid, color: Colors.blue, size: 28),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 16, color: Colors.blue),
                                    children: [
                                      TextSpan(
                                        text: nombreFarma.toString().toUpperCase(), 
                                        style: const TextStyle(fontWeight: FontWeight.w900)
                                      ),
                                      if (concentracion.isNotEmpty)
                                        TextSpan(
                                          text: "  $concentracion", // Concentración al lado
                                          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.blue[800], fontSize: 15)
                                        ),
                                    ]
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: Colors.blueAccent),
                          
                          // Resto de datos abajo
                          _infoRow("Frecuencia/Dosis:", dosis),
                          _infoRow("Indicaciones:", indicaciones),
                          _infoRow("Tratamiento Sugerido:", tratamiento),
                          
                          const Divider(),
                          if (widget.allowActions) ...[
                            // BOTÓN DE SOLICITUD A FARMACIA
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  if (widget.onSolicitarFarmacia != null && cedulaP.isNotEmpty) {
                                    widget.onSolicitarFarmacia!(cedulaP);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se encontró cédula válida")));
                                  }
                                },
                                icon: const Icon(Icons.add_shopping_cart, size: 18),
                                label: const Text("Solicitar a Farmacia"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.pink[700],
                                  side: BorderSide(color: Colors.pink[700]!),
                                  padding: const EdgeInsets.symmetric(vertical: 12)
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            
                            // BOTONES DE ACCIÓN
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _actualizarOrden(orden['id_orden'], 'NO_REALIZADA'),
                                  icon: const Icon(Icons.cancel, size: 18),
                                  label: const Text("No Realizado"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white, 
                                    foregroundColor: Colors.red[900],
                                    side: BorderSide(color: Colors.red[900]!)
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _actualizarOrden(orden['id_orden'], 'COMPLETADA'),
                                  icon: const Icon(Icons.check_circle, size: 18),
                                  label: const Text("Suministrado"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700], 
                                    foregroundColor: Colors.white
                                  ),
                                ),
                              ],
                            )
                          ]
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 20, color: Colors.grey),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- TAB 2: SOLICITAR MEDICAMENTO ---
class SolicitudMedicamentoTab extends StatefulWidget {
  final String? cedulaPrellenada; 

  const SolicitudMedicamentoTab({super.key, this.cedulaPrellenada});

  @override
  State<SolicitudMedicamentoTab> createState() => _SolicitudMedicamentoTabState();
}

class _SolicitudMedicamentoTabState extends State<SolicitudMedicamentoTab> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final EnfermeriaService _service = EnfermeriaService();
  
  Medicamento? _selectedMedicamento;
  List<Medicamento> _listaMedicamentos = [];
  Key _dropdownKey = UniqueKey();
  
  bool _isLoading = false;
  bool _isSearchingOrder = false;

  @override
  void initState() {
    super.initState();
    _cargarMedicamentos();
    if (widget.cedulaPrellenada != null) {
      _cedulaCtrl.text = widget.cedulaPrellenada!;
      Future.delayed(Duration.zero, () => _buscarOrdenAutomatica(widget.cedulaPrellenada!));
    }
  }

  @override
  void didUpdateWidget(covariant SolicitudMedicamentoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cedulaPrellenada != oldWidget.cedulaPrellenada && widget.cedulaPrellenada != null) {
      _cedulaCtrl.text = widget.cedulaPrellenada!;
      _buscarOrdenAutomatica(widget.cedulaPrellenada!);
    }
  }

  void _cargarMedicamentos() async {
    final lista = await _service.getListaMedicamentos();
    if (mounted) setState(() => _listaMedicamentos = lista);
  }

  void _buscarOrdenAutomatica(String cedula) async {
    if (cedula.length < 7) return; 

    setState(() => _isSearchingOrder = true);
    final data = await _service.getMedicamentoAutorizado(cedula);

    if (data != null && mounted) {
      try {
        final medEncontrado = _listaMedicamentos.firstWhere(
          (m) => m.idMedicamento == data['id_medicamento']
        );

        setState(() {
          _selectedMedicamento = medEncontrado;
          _dropdownKey = UniqueKey(); 
          _isSearchingOrder = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Orden detectada: ${data['nombre']}. Dosis: ${data['dosis_recetada']}"),
            backgroundColor: Colors.blue[700],
            duration: const Duration(seconds: 4),
          )
        );
      } catch (e) {
        if(mounted) setState(() => _isSearchingOrder = false);
      }
    } else {
      if(mounted) setState(() => _isSearchingOrder = false);
    }
  }

  void _enviarSolicitud() async {
    if (!_formKey.currentState!.validate() || _selectedMedicamento == null) {
      if (_selectedMedicamento == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleccione un medicamento")));
      }
      return;
    }

    setState(() => _isLoading = true);
    final res = await _service.solicitarMedicamento(
      _cedulaCtrl.text.trim(),
      _selectedMedicamento!.idMedicamento,
      int.parse(_cantidadCtrl.text.trim()),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message']),
        backgroundColor: res['success'] ? Colors.green : Colors.red,
      ));
      if (res['success']) {
        _cedulaCtrl.clear();
        _cantidadCtrl.clear();
        setState(() {
          _selectedMedicamento = null;
          _dropdownKey = UniqueKey();
        });
        _cargarMedicamentos(); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text("Solicitud a Farmacia", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _cedulaCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Cédula del Paciente", 
                border: const OutlineInputBorder(), 
                prefixIcon: const Icon(Icons.person),
                suffixIcon: _isSearchingOrder 
                  ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                  : const Icon(Icons.search),
              ),
              onChanged: (value) => _buscarOrdenAutomatica(value),
              validator: (v) => v!.isEmpty ? "Requerido" : null,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<Medicamento>(
              key: _dropdownKey,
              initialValue: _selectedMedicamento, 
              isExpanded: true,
              decoration: const InputDecoration(labelText: "Medicamento", border: OutlineInputBorder(), prefixIcon: Icon(Icons.medication)),
              items: _listaMedicamentos.map((med) {
                return DropdownMenuItem(
                  value: med, 
                  child: Text("${med.nombre} (${med.cantidadDisponible})", overflow: TextOverflow.ellipsis)
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedMedicamento = val),
              validator: (v) => v == null ? "Seleccione un medicamento" : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Cantidad", border: OutlineInputBorder(), prefixIcon: Icon(Icons.numbers)),
              validator: (v) => v!.isEmpty ? "Requerido" : null,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _enviarSolicitud,
                icon: const Icon(Icons.send),
                label: Text(_isLoading ? "Enviando..." : "Enviar Solicitud"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[700], foregroundColor: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}