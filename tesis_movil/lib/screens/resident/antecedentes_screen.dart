import 'package:flutter/material.dart';
// 1. IMPORTACIÓN NECESARIA PARA FORMATEADORES DE TEXTO
import 'package:flutter/services.dart'; 
import '../../services/antecedentes_service.dart';

class AntecedentesScreen extends StatefulWidget {
  final String cedulaPaciente;
  final bool readOnly; 

  const AntecedentesScreen({
    super.key, 
    required this.cedulaPaciente, 
    this.readOnly = false
  });

  @override
  State<AntecedentesScreen> createState() => _AntecedentesScreenState();
}

class _AntecedentesScreenState extends State<AntecedentesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          color: Colors.teal[800],
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: "Personales"),
              Tab(text: "Familiares"),
              Tab(text: "Hábitos"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FormPersonal(cedula: widget.cedulaPaciente, readOnly: widget.readOnly),
              _FormFamiliar(cedula: widget.cedulaPaciente, readOnly: widget.readOnly),
              _FormHabitos(cedula: widget.cedulaPaciente, readOnly: widget.readOnly),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 1. PERSONALES
// ==========================================
class _FormPersonal extends StatefulWidget {
  final String cedula;
  final bool readOnly;
  const _FormPersonal({required this.cedula, required this.readOnly});
  @override
  State<_FormPersonal> createState() => _FormPersonalState();
}

class _FormPersonalState extends State<_FormPersonal> with AutomaticKeepAliveClientMixin {
  final _service = AntecedentesService();
  final _tipoCtrl = TextEditingController();
  final _detalleCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _isLocked = false;
  int? _idGuardado;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar(); 
  }

  void _cargar() async {
    setState(() => _isLoading = true);
    try {
       final res = await _service.getDatosHoy(widget.cedula);
       if(mounted && res['success'] && res['data'] != null && res['data']['personal'] != null) {
          final data = res['data']['personal'];
          setState(() {
             _tipoCtrl.text = data['tipo']?.toString() ?? '';
             _detalleCtrl.text = data['detalle']?.toString() ?? '';
             _idGuardado = data['id_antecedente'] ?? data['id'];
             _isLocked = true; 
          });
       }
    } catch(e) { 
      debugPrint("Error cargando personal: $e"); 
    } finally { 
      if(mounted) setState(() => _isLoading = false); 
    }
  }

  void _guardar() async {
      if(_tipoCtrl.text.isEmpty) return;
      setState(() => _isLoading = true);

      Map<String, dynamic> res;
      if (_idGuardado == null) {
        res = await _service.createPersonal(widget.cedula, _tipoCtrl.text, _detalleCtrl.text);
      } else {
        res = await _service.updatePersonal(_idGuardado!, _tipoCtrl.text, _detalleCtrl.text);
      }

      if(mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red)
        );

        if (res['success']) {
           if (_idGuardado == null && res['data'] != null) {
              _idGuardado = res['data']['id_antecedente'] ?? res['data']['id'];
           }
           setState(() => _isLocked = true);
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool bloqueadoTotal = _isLocked || widget.readOnly;

    if (_isLoading && _idGuardado == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(controller: _tipoCtrl, enabled: !bloqueadoTotal, decoration: const InputDecoration(labelText: "Tipo (Alergia, etc)", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _detalleCtrl, enabled: !bloqueadoTotal, decoration: const InputDecoration(labelText: "Detalle", border: OutlineInputBorder())),
        const SizedBox(height: 20),
        
        if (!widget.readOnly)
          _buildDynamicButton(_isLoading, _isLocked, "Personal", _guardar, () => setState(() => _isLocked = false))
      ],
    );
  }
}

// ==========================================
// 2. FAMILIARES
// ==========================================
class _FormFamiliar extends StatefulWidget {
  final String cedula;
  final bool readOnly;
  const _FormFamiliar({required this.cedula, required this.readOnly});
  @override
  State<_FormFamiliar> createState() => _FormFamiliarState();
}

class _FormFamiliarState extends State<_FormFamiliar> with AutomaticKeepAliveClientMixin {
  final _service = AntecedentesService();
  final _tipoCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _patologiasCtrl = TextEditingController();
  String _vivo = 'Vivo';
  
  bool _isLoading = false;
  bool _isLocked = false;
  int? _idGuardado;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() async {
    setState(() => _isLoading = true);
    try {
       final res = await _service.getDatosHoy(widget.cedula);
       if(mounted && res['success'] && res['data'] != null && res['data']['familiar'] != null) {
          final data = res['data']['familiar'];
          setState(() {
             _tipoCtrl.text = data['tipo_familiar']?.toString() ?? '';
             _edadCtrl.text = data['edad']?.toString() ?? '';
             _patologiasCtrl.text = data['patologias']?.toString() ?? '';
             
             String vivoTraido = data['vivo_muerto']?.toString() ?? 'Vivo';
             if (['Vivo', 'Muerto'].contains(vivoTraido)) {
               _vivo = vivoTraido;
             }

             _idGuardado = data['id_familiar'] ?? data['id'];
             _isLocked = true;
          });
       }
    } catch(e) { 
      debugPrint("Error cargando familiar: $e"); 
    } finally { 
      if(mounted) setState(() => _isLoading = false); 
    }
  }

  void _guardar() async {
    if (_tipoCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    Map<String, dynamic> res;
    if (_idGuardado == null) {
      res = await _service.createFamiliar(widget.cedula, _tipoCtrl.text, _vivo, _edadCtrl.text, _patologiasCtrl.text);
    } else {
      res = await _service.updateFamiliar(_idGuardado!, _tipoCtrl.text, _vivo, _edadCtrl.text, _patologiasCtrl.text);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red)
      );
      
      if (res['success']) {
         if (_idGuardado == null && res['data'] != null) {
            _idGuardado = res['data']['id_familiar'] ?? res['data']['id'];
         }
         setState(() => _isLocked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool bloqueadoTotal = _isLocked || widget.readOnly;

    if (_isLoading && _idGuardado == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(controller: _tipoCtrl, enabled: !bloqueadoTotal, decoration: const InputDecoration(labelText: "Parentesco (Ej: Madre)", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        DropdownButtonFormField<String>(
          initialValue: _vivo, 
          decoration: const InputDecoration(labelText: "Estado", border: OutlineInputBorder()),
          items: ['Vivo', 'Muerto'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: bloqueadoTotal ? null : (v) => setState(() => _vivo = v!),
        ),
        const SizedBox(height: 15),

        // --- CAMBIO AQUÍ: VALIDACIÓN DE SOLO NÚMEROS PARA LA EDAD ---
        TextField(
          controller: _edadCtrl, 
          enabled: !bloqueadoTotal, 
          keyboardType: TextInputType.number, 
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // Bloquea cualquier carácter que no sea número
          ],
          decoration: const InputDecoration(
            labelText: "Edad", 
            border: OutlineInputBorder()
          ),
        ),

        const SizedBox(height: 15),
        TextField(controller: _patologiasCtrl, enabled: !bloqueadoTotal, maxLines: 2, decoration: const InputDecoration(labelText: "Patologías", border: OutlineInputBorder())),
        const SizedBox(height: 30),

        if (!widget.readOnly)
          _buildDynamicButton(_isLoading, _isLocked, "Familiar", _guardar, () => setState(() => _isLocked = false))
      ],
    );
  }
}

// ==========================================
// 3. HÁBITOS
// ==========================================
class _FormHabitos extends StatefulWidget {
  final String cedula;
  final bool readOnly;
  const _FormHabitos({required this.cedula, required this.readOnly});
  @override
  State<_FormHabitos> createState() => _FormHabitosState();
}

class _FormHabitosState extends State<_FormHabitos> with AutomaticKeepAliveClientMixin {
  final _service = AntecedentesService();
  final _cafe = TextEditingController(text: "Niega");
  final _tabaco = TextEditingController(text: "Niega");
  final _alcohol = TextEditingController(text: "Niega");
  final _drogas = TextEditingController(text: "Niega");
  final _ocupacion = TextEditingController();
  final _sueno = TextEditingController();
  final _vivienda = TextEditingController();

  bool _isLoading = false;
  bool _isLocked = false;
  int? _idGuardado;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() async {
    setState(() => _isLoading = true);
    try {
       final res = await _service.getDatosHoy(widget.cedula);
       if(mounted && res['success'] && res['data'] != null && res['data']['habitos'] != null) {
          final data = res['data']['habitos'];
          setState(() {
             _cafe.text = data['cafe']?.toString() ?? 'Niega';
             _tabaco.text = data['tabaco']?.toString() ?? 'Niega';
             _alcohol.text = data['alcohol']?.toString() ?? 'Niega';
             _drogas.text = data['drogas_ilicitas']?.toString() ?? 'Niega';
             _ocupacion.text = data['ocupacion']?.toString() ?? '';
             _sueno.text = data['sueño']?.toString() ?? data['sueno']?.toString() ?? '';
             _vivienda.text = data['vivienda']?.toString() ?? '';
             
             _idGuardado = data['id_habito'] ?? data['id'];
             _isLocked = true;
          });
       }
    } catch(e) { 
      debugPrint("Error cargando habitos: $e"); 
    } finally { 
      if(mounted) setState(() => _isLoading = false); 
    }
  }

  void _guardar() async {
    setState(() => _isLoading = true);
    
    Map<String, dynamic> res;
    if (_idGuardado == null) {
      res = await _service.createHabitos(widget.cedula, _cafe.text, _tabaco.text, _alcohol.text, _drogas.text, _ocupacion.text, _sueno.text, _vivienda.text);
    } else {
      res = await _service.updateHabitos(_idGuardado!, _cafe.text, _tabaco.text, _alcohol.text, _drogas.text, _ocupacion.text, _sueno.text, _vivienda.text);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red)
      );

      if (res['success']) {
         if (_idGuardado == null && res['data'] != null) {
            _idGuardado = res['data']['id_habito'] ?? res['data']['id'];
         }
         setState(() => _isLocked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool bloqueadoTotal = _isLocked || widget.readOnly;

    if (_isLoading && _idGuardado == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Consumos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 15),
        _buildField(_cafe, "Café", bloqueadoTotal),
        const SizedBox(height: 15),
        _buildField(_tabaco, "Tabaco", bloqueadoTotal),
        const SizedBox(height: 15),
        _buildField(_alcohol, "Alcohol", bloqueadoTotal),
        const SizedBox(height: 15),
        _buildField(_drogas, "Drogas", bloqueadoTotal),
        const SizedBox(height: 30),
        const Text("Estilo de Vida", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 15),
        _buildField(_ocupacion, "Ocupación", bloqueadoTotal),
        const SizedBox(height: 15),
        _buildField(_sueno, "Sueño (Ej: 8 horas)", bloqueadoTotal),
        const SizedBox(height: 15),
        _buildField(_vivienda, "Vivienda", bloqueadoTotal),
        const SizedBox(height: 30),

        if (!widget.readOnly)
          _buildDynamicButton(_isLoading, _isLocked, "Hábitos", _guardar, () => setState(() => _isLocked = false))
      ],
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, bool locked) {
    return TextField(
      controller: ctrl,
      enabled: !locked,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15)),
    );
  }
}

// ==========================================
// WIDGET HELPER: BOTÓN DINÁMICO
// ==========================================
Widget _buildDynamicButton(bool isLoading, bool isLocked, String label, VoidCallback onSave, VoidCallback onEdit) {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton.icon(
      onPressed: isLoading ? null : (isLocked ? onEdit : onSave),
      icon: isLoading 
        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : Icon(isLocked ? Icons.edit : Icons.save),
      label: Text(
        isLoading ? "Guardando..." : (isLocked ? "Editar $label" : "Guardar $label"),
        style: const TextStyle(fontSize: 18),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isLocked ? Colors.orange[800] : Colors.teal[700],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}