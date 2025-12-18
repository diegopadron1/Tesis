import 'package:flutter/material.dart';
import '../../services/antecedentes_service.dart';

class AntecedentesScreen extends StatefulWidget {
  final String cedulaPaciente;
  const AntecedentesScreen({super.key, required this.cedulaPaciente});

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
              _FormPersonal(cedula: widget.cedulaPaciente),
              _FormFamiliar(cedula: widget.cedulaPaciente),
              _FormHabitos(cedula: widget.cedulaPaciente),
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
  const _FormPersonal({required this.cedula});
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
           // CAPTURA ID: 'id_antecedente'
           if (_idGuardado == null && res['data'] != null) {
              _idGuardado = res['data']['id_antecedente'] ?? res['data']['id'];
              debugPrint("✅ Personal ID: $_idGuardado");
           }
           setState(() => _isLocked = true);
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(controller: _tipoCtrl, enabled: !_isLocked, decoration: const InputDecoration(labelText: "Tipo (Alergia, etc)", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _detalleCtrl, enabled: !_isLocked, decoration: const InputDecoration(labelText: "Detalle", border: OutlineInputBorder())),
        const SizedBox(height: 20),
        
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
  const _FormFamiliar({required this.cedula});
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
         // CAPTURA ID: 'id_familiar'
         if (_idGuardado == null && res['data'] != null) {
            _idGuardado = res['data']['id_familiar'] ?? res['data']['id'];
            debugPrint("✅ Familiar ID: $_idGuardado");
         }
         setState(() => _isLocked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(controller: _tipoCtrl, enabled: !_isLocked, decoration: const InputDecoration(labelText: "Parentesco (Ej: Madre)", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        DropdownButtonFormField<String>(
          initialValue: _vivo,
          decoration: const InputDecoration(labelText: "Estado", border: OutlineInputBorder()),
          items: ['Vivo', 'Muerto'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: _isLocked ? null : (v) => setState(() => _vivo = v!),
        ),
        const SizedBox(height: 15),
        TextField(controller: _edadCtrl, enabled: !_isLocked, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Edad", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _patologiasCtrl, enabled: !_isLocked, maxLines: 2, decoration: const InputDecoration(labelText: "Patologías", border: OutlineInputBorder())),
        const SizedBox(height: 30),

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
  const _FormHabitos({required this.cedula});
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
         // CAPTURA ID: 'id_habito'
         if (_idGuardado == null && res['data'] != null) {
            _idGuardado = res['data']['id_habito'] ?? res['data']['id'];
            debugPrint("✅ Habito ID: $_idGuardado");
         }
         setState(() => _isLocked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Consumos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 15),
        _buildField(_cafe, "Café", _isLocked),
        const SizedBox(height: 15),
        _buildField(_tabaco, "Tabaco", _isLocked),
        const SizedBox(height: 15),
        _buildField(_alcohol, "Alcohol", _isLocked),
        const SizedBox(height: 15),
        _buildField(_drogas, "Drogas", _isLocked),
        const SizedBox(height: 30),
        const Text("Estilo de Vida", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 15),
        _buildField(_ocupacion, "Ocupación", _isLocked),
        const SizedBox(height: 15),
        _buildField(_sueno, "Sueño (Ej: 8 horas)", _isLocked),
        const SizedBox(height: 15),
        _buildField(_vivienda, "Vivienda", _isLocked),
        const SizedBox(height: 30),

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