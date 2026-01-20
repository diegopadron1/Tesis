import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
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

// =================================================================
// TAB 1: GESTIÓN DE ÓRDENES (CON VALIDACIÓN DE ENTREGA)
// =================================================================
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
              final nombreCompleto = paciente['nombre_apellido'] ?? 'Desconocido';
              final cedulaP = paciente['cedula'] ?? orden['cedula_paciente'] ?? '';
              final edad = paciente['edad']?.toString() ?? '?'; 
              final zona = orden['ubicacion'] ?? paciente['ubicacion'] ?? 'Ubicación pendiente';
              final String? listaMedicamentos = orden['requerimiento_medicamentos'];
              final indicaciones = orden['indicaciones_inmediatas'] ?? 'Ninguna';
              final tratamiento = orden['tratamientos_sugeridos'] ?? 'No especificado';

              // OBTENEMOS LAS SOLICITUDES VINCULADAS
              final List<dynamic> solicitudes = orden['SolicitudMedicamentos'] ?? [];
              
              // VALIDACIÓN: ¿Hay algo pendiente por entregar en farmacia?
              // Bloqueamos el suministro si hay medicamentos en 'PENDIENTE' o 'LISTO' (pero no entregados aún)
              bool tienePendientesFarmacia = solicitudes.any((s) => s['estatus'] != 'ENTREGADO');

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.pink.withValues(alpha: 0.3)) 
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.pink[700], 
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    nombreCompleto, 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.pink[800]),
                  ),
                  subtitle: Text("C.I: $cedulaP - $edad años\n$zona", style: const TextStyle(fontSize: 13)),
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
                          if (listaMedicamentos != null && listaMedicamentos.isNotEmpty) ...[
                            const Text("MEDICAMENTOS ORDENADOS:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                            const SizedBox(height: 5),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(5)
                              ),
                              child: Text(listaMedicamentos, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4)),
                            ),
                          ],
                          const Divider(height: 20, color: Colors.blueAccent),
                          
                          // LISTA VISUAL DE ESTADOS DE FARMACIA
                          if (solicitudes.isNotEmpty) ...[
                            const Text("ESTADO EN FARMACIA:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 12)),
                            const SizedBox(height: 5),
                            ...solicitudes.map((sol) {
                              final nombreMed = sol['medicamento']?['nombre'] ?? 'Desconocido';
                              final estado = sol['estatus'];
                              Color colorEstado = Colors.orange;
                              if (estado == 'LISTO') colorEstado = Colors.blue;
                              if (estado == 'ENTREGADO') colorEstado = Colors.green;
                              if (estado == 'RECHAZADO') colorEstado = Colors.red;

                              return Text("• $nombreMed: $estado", style: TextStyle(color: colorEstado, fontSize: 13, fontWeight: FontWeight.bold));
                            }),
                            const SizedBox(height: 10),
                          ],

                          _infoRow("Indicaciones:", indicaciones),
                          _infoRow("Tratamiento:", tratamiento),
                          
                          const Divider(),
                          if (widget.allowActions) ...[
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  if (widget.onSolicitarFarmacia != null && cedulaP.isNotEmpty) {
                                    widget.onSolicitarFarmacia!(cedulaP);
                                  }
                                },
                                icon: const Icon(Icons.add_shopping_cart, size: 18),
                                label: const Text("Solicitar Medicamento a Farmacia"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.pink[700],
                                  side: BorderSide(color: Colors.pink[700]!),
                                  padding: const EdgeInsets.symmetric(vertical: 12)
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            
                            if (tienePendientesFarmacia)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  "⚠️ No puede suministrar hasta retirar todo de farmacia.",
                                  style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _actualizarOrden(orden['id_orden'], 'NO_REALIZADA'),
                                  icon: const Icon(Icons.cancel, size: 18),
                                  label: const Text("No Realizado"),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red[900]),
                                ),
                                ElevatedButton.icon(
                                  // BLOQUEO DE BOTÓN SEGÚN ESTADO DE FARMACIA
                                  onPressed: tienePendientesFarmacia ? null : () => _actualizarOrden(orden['id_orden'], 'COMPLETADA'),
                                  icon: const Icon(Icons.check_circle, size: 18),
                                  label: const Text("Suministrado"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700], 
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey[300]
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
                  TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(text: value, style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// TAB 2: SOLICITUD MEDICAMENTO (CON VALIDACIÓN DE RECETA)
// =================================================================
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
  final List<Map<String, dynamic>> _carrito = [];

  bool _isLoading = false;
  bool _isSearchingOrder = false;
  String? _textoOrdenDoctor; 

  @override
  void initState() {
    super.initState();
    _cargarMedicamentos();
    if (widget.cedulaPrellenada != null) {
      _cedulaCtrl.text = widget.cedulaPrellenada!;
      Future.delayed(Duration.zero, () => _buscarOrdenAutomatica(widget.cedulaPrellenada!));
    }
  }

  void _cargarMedicamentos() async {
    final lista = await _service.getListaMedicamentos();
    if (mounted) setState(() => _listaMedicamentos = lista);
  }

  void _buscarOrdenAutomatica(String cedula) async {
    if (cedula.length < 7) {
      setState(() => _textoOrdenDoctor = null);
      return; 
    }
    setState(() => _isSearchingOrder = true);
    final data = await _service.getMedicamentoAutorizado(cedula);

    if (mounted) {
      setState(() {
        _isSearchingOrder = false;
        if (data != null) {
          _textoOrdenDoctor = data['dosis_recetada'] ?? data['requerimiento_medicamentos'];
        } else {
          _textoOrdenDoctor = null;
        }
      });
    }
  }

  void _agregarAlCarrito() {
    if (_selectedMedicamento == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleccione un medicamento")));
      return;
    }

    // VALIDACIÓN: ¿EL MEDICAMENTO SELECCIONADO ESTÁ EN LA RECETA DEL DOCTOR?
    if (_textoOrdenDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No hay una orden médica activa para validar este medicamento."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Comparamos el nombre del medicamento con el texto de la orden (ignorando mayúsculas)
    bool estaEnReceta = _textoOrdenDoctor!.toLowerCase().contains(_selectedMedicamento!.nombre.toLowerCase());

    if (!estaEnReceta) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ El medicamento '${_selectedMedicamento!.nombre}' no ha sido recetado por el doctor."),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ));
      return;
    }
    
    if (_cantidadCtrl.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingrese una cantidad")));
       return;
    }

    final int? cantidad = int.tryParse(_cantidadCtrl.text.trim());

    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cantidad inválida"), backgroundColor: Colors.red));
      return;
    }

    if (cantidad > _selectedMedicamento!.cantidadDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Stock insuficiente (${_selectedMedicamento!.cantidadDisponible})"), backgroundColor: Colors.orange));
      return;
    }

    final existeIndex = _carrito.indexWhere((item) => item['medicamento'].idMedicamento == _selectedMedicamento!.idMedicamento);
    
    setState(() {
      if (existeIndex != -1) {
        _carrito[existeIndex]['cantidad'] += cantidad;
      } else {
        _carrito.add({ 'medicamento': _selectedMedicamento, 'cantidad': cantidad });
      }
      _selectedMedicamento = null;
      _cantidadCtrl.clear();
    });
  }

  void _removerDelCarrito(int index) {
    setState(() => _carrito.removeAt(index));
  }

  void _procesarSolicitudCompleta() async {
    if (_carrito.isEmpty) return;
    if (_cedulaCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta la cédula del paciente")));
      return;
    }

    setState(() => _isLoading = true);
    int exito = 0;
    int fallos = 0;

    for (var item in _carrito) {
      final Medicamento med = item['medicamento'];
      final int cant = item['cantidad'];
      final res = await _service.solicitarMedicamento(_cedulaCtrl.text.trim(), med.idMedicamento, cant);
      if (res['success']) { exito++;
      } else {
        fallos++;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (fallos == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Solicitud enviada"), backgroundColor: Colors.green));
        setState(() => _carrito.clear());
        _cargarMedicamentos(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ Completado: $exito. Fallos: $fallos"), backgroundColor: Colors.orange));
        setState(() => _carrito.clear()); 
        _cargarMedicamentos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Solicitud Múltiple a Farmacia", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _cedulaCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: "Cédula del Paciente", 
              border: const OutlineInputBorder(), 
              prefixIcon: const Icon(Icons.person),
              suffixIcon: _isSearchingOrder 
                ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                : const Icon(Icons.search),
            ),
            onChanged: (value) => _buscarOrdenAutomatica(value),
          ),
          
          if (_textoOrdenDoctor != null) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50], 
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📋 El doctor ordenó:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[900])),
                  const SizedBox(height: 5),
                  Text(_textoOrdenDoctor!, style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],

          const Divider(height: 30, thickness: 1.5),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Autocomplete<Medicamento>(
                            displayStringForOption: (Medicamento option) => option.nombre,
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text == '') return const Iterable<Medicamento>.empty();
                              return _listaMedicamentos.where((Medicamento option) => option.nombre.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (Medicamento selection) {
                              setState(() => _selectedMedicamento = selection);
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  child: SizedBox(
                                    width: constraints.maxWidth,
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          title: Text(option.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text("${option.presentacion ?? ''} - ${option.concentracion} | Stock: ${option.cantidadDisponible}", style: TextStyle(color: Colors.grey[700])),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: "Medicamento", 
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15)
                                ),
                              );
                            },
                          );
                        }
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _cantidadCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: "Cant.", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: _agregarAlCarrito, 
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(backgroundColor: Colors.pink[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    )
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text("Lista para Solicitar:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 150, 
            decoration: BoxDecoration(color: Colors.grey[50], border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
            child: _carrito.isEmpty 
              ? const Center(child: Text("Lista vacía", style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  itemCount: _carrito.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final item = _carrito[index];
                    final Medicamento med = item['medicamento'];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.medication, color: Colors.pink),
                      title: Text(med.nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      subtitle: Text("Cantidad: ${item['cantidad']}"),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _removerDelCarrito(index)),
                    );
                  },
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (_isLoading || _carrito.isEmpty) ? null : _procesarSolicitudCompleta,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
              label: Text(_isLoading ? "Procesando..." : "Enviar Solicitud (${_carrito.length} ítems)"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[700], foregroundColor: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}