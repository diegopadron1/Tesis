import 'package:flutter/material.dart';
import '../../services/enfermeria_service.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import '../../models/medicamento.dart';

class NurseHomeScreen extends StatefulWidget {
  const NurseHomeScreen({super.key});

  @override
  State<NurseHomeScreen> createState() => _NurseHomeScreenState();
}

class _NurseHomeScreenState extends State<NurseHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        children: const [
          OrdenesPendientesTab(allowActions: true),
          SolicitudMedicamentoTab(),
        ],
      ),
    );
  }
}

// --- TAB 1: GESTIÓN DE ÓRDENES ---
class OrdenesPendientesTab extends StatefulWidget {
  final bool allowActions; 

  const OrdenesPendientesTab({super.key, this.allowActions = true});

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
              
              // --- CORRECCIÓN DEFINITIVA ---
              // Usamos directamente 'nombre_apellido'
              final nombreCompleto = paciente['nombre_apellido'] ?? 'Desconocido';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  initiallyExpanded: widget.allowActions, 
                  leading: const CircleAvatar(backgroundColor: Color.fromARGB(255, 14, 82, 1), child: Icon(Icons.assignment, color: Colors.white)),
                  title: Text(nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold)), // Mostramos nombre_apellido
                  subtitle: Text("C.I: ${orden['cedula_paciente']} • Orden #${orden['id_orden']}"),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      color: Colors.pink[50],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow("Indicaciones:", orden['indicaciones_inmediatas']),
                          _infoRow("Medicamentos:", orden['requerimiento_medicamentos']),
                          _infoRow("Tratamientos:", orden['tratamientos_sugeridos']),
                          
                          if (widget.allowActions) ...[
                            const SizedBox(height: 15),
                            const Divider(),
                            const Text("Acciones:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _actualizarOrden(orden['id_orden'], 'NO_REALIZADA'),
                                  icon: const Icon(Icons.cancel, size: 18),
                                  label: const Text("No Realizado"),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100], foregroundColor: Colors.red[900]),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _actualizarOrden(orden['id_orden'], 'COMPLETADA'),
                                  icon: const Icon(Icons.check_circle, size: 18),
                                  label: const Text("Confirmar"),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                ),
                              ],
                            )
                          ] else ...[
                            const SizedBox(height: 10),
                            const Align(
                                alignment: Alignment.centerRight,
                                child: Text("Ir a Módulo de Enfermería para gestionar", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey))
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
      padding: const EdgeInsets.only(bottom: 5),
      child: Text("$label $value", style: const TextStyle(fontSize: 14)),
    );
  }
}

// --- TAB 2: SOLICITAR MEDICAMENTO ---
class SolicitudMedicamentoTab extends StatefulWidget {
  const SolicitudMedicamentoTab({super.key});

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarMedicamentos();
  }

  void _cargarMedicamentos() async {
    final lista = await _service.getListaMedicamentos();
    if (mounted) setState(() => _listaMedicamentos = lista);
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
        setState(() => _selectedMedicamento = null);
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
              decoration: const InputDecoration(labelText: "Cédula del Paciente", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              validator: (v) => v!.isEmpty ? "Requerido" : null,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<Medicamento>(
              initialValue: _selectedMedicamento,
              isExpanded: true,
              decoration: const InputDecoration(labelText: "Medicamento", border: OutlineInputBorder(), prefixIcon: Icon(Icons.medication)),
              items: _listaMedicamentos.map((med) {
                return DropdownMenuItem(value: med, child: Text("${med.nombre} (${med.cantidadDisponible})", overflow: TextOverflow.ellipsis));
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