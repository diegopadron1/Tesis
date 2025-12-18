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

  void _procesarGuardado() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    Map<String, dynamic> res;

    if (_idGuardado == null) {
      // CREAR
      res = await _service.createExamenFisico(widget.cedula, _areaCtrl.text, _hallazgosCtrl.text);
    } else {
      // ACTUALIZAR
      res = await _service.updateExamenFisico(_idGuardado!, _areaCtrl.text, _hallazgosCtrl.text);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Examen Físico Guardado"), backgroundColor: Colors.green));
        
        // --- CAPTURA DEL ID FÍSICO (id_fisico) ---
        if (_idGuardado == null && res['data'] != null) {
           var idCapturado = res['data']['id_fisico'];
           idCapturado ??= res['data']['id']; 
           
           if (idCapturado != null) {
             _idGuardado = idCapturado;
             debugPrint("✅ ID FÍSICO CAPTURADO: $_idGuardado");
           }
        }
        
        setState(() {
          _formularioBloqueado = true;
        });

      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 
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
                onPressed: _isLoading 
                    ? null 
                    : () {
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
                  _isLoading 
                      ? "Guardando..." 
                      : (_formularioBloqueado ? "Editar Examen Físico" : "Guardar Examen Físico"),
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

  void _procesarGuardado() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    Map<String, dynamic> res;

    // --- CREAR O ACTUALIZAR ---
    if (_idGuardado == null) {
      res = await _service.createExamenFuncional(widget.cedula, _sistemaCtrl.text, _hallazgosCtrl.text);
    } else {
      res = await _service.updateExamenFuncional(_idGuardado!, _sistemaCtrl.text, _hallazgosCtrl.text);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Examen Funcional Guardado"), backgroundColor: Colors.green));
        
        // --- CAPTURA DEL ID FUNCIONAL (CORREGIDA) ---
        if (_idGuardado == null && res['data'] != null) {
           
           // INTENTO 1: 'id_examen' (Según tu foto de la base de datos)
           var idCapturado = res['data']['id_examen']; 
           
           // INTENTO 2: 'id_examen_funcional' (Por si acaso)
           idCapturado ??= res['data']['id_examen_funcional'];
           
           // INTENTO 3: 'id' (Genérico)
           idCapturado ??= res['data']['id']; 
           
           if (idCapturado != null) {
             _idGuardado = idCapturado;
             debugPrint("✅ ID FUNCIONAL CAPTURADO: $_idGuardado");
           } else {
             debugPrint("⚠️ ALERTA: No se encontró ID (Buscamos 'id_examen'). Data: ${res['data']}");
           }
        }
        
        setState(() {
          _formularioBloqueado = true;
        });

      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                onPressed: _isLoading 
                    ? null 
                    : () {
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
                  _isLoading 
                      ? "Guardando..." 
                      : (_formularioBloqueado ? "Editar Examen Funcional" : "Guardar Examen Funcional"),
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