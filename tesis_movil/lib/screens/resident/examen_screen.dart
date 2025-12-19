import 'package:flutter/material.dart';
import '../../services/examen_service.dart';

class ExamenScreen extends StatefulWidget {
  final String cedulaPaciente;

  const ExamenScreen({super.key, required this.cedulaPaciente});

  @override
  State<ExamenScreen> createState() => _ExamenScreenState();
}

class _ExamenScreenState extends State<ExamenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Column(
      children: [
        Container(
          color: Colors.teal[700],
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.accessibility), text: "Físico"),
              Tab(icon: Icon(Icons.settings_accessibility), text: "Funcional"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FormularioFisico(cedula: widget.cedulaPaciente),
              _FormularioFuncional(cedula: widget.cedulaPaciente),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 1. SUB-WIDGET FÍSICO
// ==========================================
class _FormularioFisico extends StatefulWidget {
  final String cedula;
  const _FormularioFisico({required this.cedula});

  @override
  State<_FormularioFisico> createState() => _FormularioFisicoState();
}

class _FormularioFisicoState extends State<_FormularioFisico> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _areaCtrl = TextEditingController();
  final _hallazgosCtrl = TextEditingController();
  final _service = ExamenService();
  
  bool _isLoading = false;
  bool _formularioBloqueado = false; 
  int? _idGuardado; 

  @override
  bool get wantKeepAlive => true; 

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // --- CARGAR DATOS ---
  void _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.getDatosHoy(widget.cedula);
      
      if (mounted) {
        if (res['success'] && res['data'] != null) {
          final data = res['data'];
          
          // Si existe examen FÍSICO
          if (data['fisico'] != null) {
             setState(() {
                _areaCtrl.text = data['fisico']['area'] ?? '';
                _hallazgosCtrl.text = data['fisico']['hallazgos'] ?? '';
                _idGuardado = data['fisico']['id_fisico'];
                _formularioBloqueado = true; // Bloquear visualmente
             });
             debugPrint("✅ Examen Físico cargado.");
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading fisico: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _procesarGuardado() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    Map<String, dynamic> res;

    if (_idGuardado == null) {
      res = await _service.createExamenFisico(widget.cedula, _areaCtrl.text, _hallazgosCtrl.text);
    } else {
      res = await _service.updateExamenFisico(_idGuardado!, _areaCtrl.text, _hallazgosCtrl.text);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Examen Físico Guardado"), backgroundColor: Colors.green));
        
        if (_idGuardado == null && res['data'] != null) {
           var id = res['data']['id_fisico'] ?? res['data']['id']; 
           if (id != null) _idGuardado = id;
        }
        
        setState(() => _formularioBloqueado = true);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading && _idGuardado == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
             TextFormField(
               controller: _areaCtrl, 
               enabled: !_formularioBloqueado,
               decoration: const InputDecoration(labelText: "Área (Ej: Tórax)", border: OutlineInputBorder(), filled: true), 
               validator: (v)=>v!.isEmpty?'Requerido':null
             ),
             const SizedBox(height: 15),
             TextFormField(
               controller: _hallazgosCtrl, 
               enabled: !_formularioBloqueado,
               maxLines: 3, 
               decoration: const InputDecoration(labelText: "Hallazgos", border: OutlineInputBorder(), filled: true), 
               validator: (v)=>v!.isEmpty?'Requerido':null
             ),
             const SizedBox(height: 30),
             
             SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () {
                        if (_formularioBloqueado) {
                          setState(() => _formularioBloqueado = false); 
                        } else {
                          _procesarGuardado(); 
                        }
                      },
                icon: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(_formularioBloqueado ? Icons.edit : Icons.save),
                label: Text(
                  _isLoading ? "Guardando..." : (_formularioBloqueado ? "Editar Examen Físico" : "Guardar Examen Físico"),
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _formularioBloqueado ? Colors.orange[800] : Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. SUB-WIDGET FUNCIONAL
// ==========================================
class _FormularioFuncional extends StatefulWidget {
  final String cedula;
  const _FormularioFuncional({required this.cedula});
  @override
  State<_FormularioFuncional> createState() => _FormularioFuncionalState();
}

class _FormularioFuncionalState extends State<_FormularioFuncional> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _sistemaCtrl = TextEditingController();
  final _hallazgosCtrl = TextEditingController();
  final _service = ExamenService();
  
  bool _isLoading = false;
  bool _formularioBloqueado = false;
  int? _idGuardado;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // --- CARGAR DATOS ---
  void _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.getDatosHoy(widget.cedula);
      
      if (mounted) {
        if (res['success'] && res['data'] != null) {
          final data = res['data'];
          
          // Si existe examen FUNCIONAL
          if (data['funcional'] != null) {
             setState(() {
                _sistemaCtrl.text = data['funcional']['sistema'] ?? '';
                _hallazgosCtrl.text = data['funcional']['hallazgos'] ?? '';
                
                // Intento robusto de capturar ID
                _idGuardado = data['funcional']['id_examen'] ?? data['funcional']['id_examen_funcional'] ?? data['funcional']['id'];
                
                _formularioBloqueado = true;
             });
             debugPrint("✅ Examen Funcional cargado.");
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading funcional: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _procesarGuardado() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    Map<String, dynamic> res;

    if (_idGuardado == null) {
      res = await _service.createExamenFuncional(widget.cedula, _sistemaCtrl.text, _hallazgosCtrl.text);
    } else {
      res = await _service.updateExamenFuncional(_idGuardado!, _sistemaCtrl.text, _hallazgosCtrl.text);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Examen Funcional Guardado"), backgroundColor: Colors.green));
        
        if (_idGuardado == null && res['data'] != null) {
           var id = res['data']['id_examen'] ?? res['data']['id_examen_funcional'] ?? res['data']['id']; 
           if (id != null) _idGuardado = id;
        }
        
        setState(() => _formularioBloqueado = true);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading && _idGuardado == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
             TextFormField(
               controller: _sistemaCtrl, 
               enabled: !_formularioBloqueado,
               decoration: const InputDecoration(labelText: "Sistema (Ej: Respiratorio)", border: OutlineInputBorder(), filled: true), 
               validator: (v)=>v!.isEmpty?'Requerido':null
             ),
             const SizedBox(height: 15),
             TextFormField(
               controller: _hallazgosCtrl, 
               enabled: !_formularioBloqueado,
               maxLines: 3, 
               decoration: const InputDecoration(labelText: "Hallazgos", border: OutlineInputBorder(), filled: true), 
               validator: (v)=>v!.isEmpty?'Requerido':null
             ),
             const SizedBox(height: 30),
             
             SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () {
                        if (_formularioBloqueado) {
                          setState(() => _formularioBloqueado = false);
                        } else {
                          _procesarGuardado();
                        }
                      },
                icon: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(_formularioBloqueado ? Icons.edit : Icons.save),
                label: Text(
                  _isLoading ? "Guardando..." : (_formularioBloqueado ? "Editar Examen Funcional" : "Guardar Examen Funcional"),
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _formularioBloqueado ? Colors.orange[800] : Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}