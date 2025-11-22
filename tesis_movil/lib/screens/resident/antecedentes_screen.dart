import 'package:flutter/material.dart';
import '../../services/antecedentes_service.dart';

class AntecedentesScreen extends StatefulWidget {
  const AntecedentesScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulo de Antecedentes'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true, // Para que quepan bien los textos
          tabs: const [
            Tab(icon: Icon(Icons.person), text: "Personales"),
            Tab(icon: Icon(Icons.family_restroom), text: "Familiares"),
            Tab(icon: Icon(Icons.smoking_rooms), text: "Hábitos"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FormPersonal(),
          _FormFamiliar(),
          _FormHabitos(),
        ],
      ),
    );
  }
}

// --- TAB 1: Personales ---
class _FormPersonal extends StatefulWidget {
  const _FormPersonal();
  @override
  State<_FormPersonal> createState() => _FormPersonalState();
}

class _FormPersonalState extends State<_FormPersonal> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaCtrl = TextEditingController();
  final _tipoCtrl = TextEditingController();
  final _detalleCtrl = TextEditingController();
  final _service = AntecedentesService();
  bool _isLoading = false;

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final res = await _service.createPersonal(_cedulaCtrl.text, _tipoCtrl.text, _detalleCtrl.text);
    if (mounted) {
      setState(() => _isLoading = false);
      _mostrarSnack(context, res);
      if (res['success']) { _tipoCtrl.clear(); _detalleCtrl.clear(); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(children: [
          const Text("Antecedentes Personales", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildInput(_cedulaCtrl, "Cédula Paciente *", isNumber: true),
          const SizedBox(height: 15),
          _buildInput(_tipoCtrl, "Tipo (Ej: Alérgico, Quirúrgico) *"),
          const SizedBox(height: 15),
          _buildInput(_detalleCtrl, "Detalle (Ej: Penicilina) *", maxLines: 3),
          const SizedBox(height: 20),
          _buildBtn(_isLoading, _guardar, "Guardar Personal"),
        ]),
      ),
    );
  }
}

// --- TAB 2: Familiares ---
class _FormFamiliar extends StatefulWidget {
  const _FormFamiliar();
  @override
  State<_FormFamiliar> createState() => _FormFamiliarState();
}

class _FormFamiliarState extends State<_FormFamiliar> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaCtrl = TextEditingController();
  final _tipoCtrl = TextEditingController(); // Madre, Padre...
  final _edadCtrl = TextEditingController();
  final _patologiasCtrl = TextEditingController();
  String _vivoMuerto = 'Vivo'; // Valor por defecto
  final _service = AntecedentesService();
  bool _isLoading = false;

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final res = await _service.createFamiliar(
      _cedulaCtrl.text, _tipoCtrl.text, _vivoMuerto, _edadCtrl.text, _patologiasCtrl.text
    );
    if (mounted) {
      setState(() => _isLoading = false);
      _mostrarSnack(context, res);
      if (res['success']) { _tipoCtrl.clear(); _edadCtrl.clear(); _patologiasCtrl.clear(); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(children: [
          const Text("Antecedentes Familiares", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildInput(_cedulaCtrl, "Cédula Paciente *", isNumber: true),
          const SizedBox(height: 15),
          _buildInput(_tipoCtrl, "Parentesco (Ej: Madre) *"),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            initialValue: _vivoMuerto,
            decoration: InputDecoration(labelText: "Estado *", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            items: ['Vivo', 'Muerto'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _vivoMuerto = v!),
          ),
          const SizedBox(height: 15),
          _buildInput(_edadCtrl, "Edad (Opcional)", isNumber: true, isRequired: false),
          const SizedBox(height: 15),
          _buildInput(_patologiasCtrl, "Patologías (Opcional)", maxLines: 3, isRequired: false),
          const SizedBox(height: 20),
          _buildBtn(_isLoading, _guardar, "Guardar Familiar"),
        ]),
      ),
    );
  }
}

// --- TAB 3: Hábitos ---
class _FormHabitos extends StatefulWidget {
  const _FormHabitos();
  @override
  State<_FormHabitos> createState() => _FormHabitosState();
}

class _FormHabitosState extends State<_FormHabitos> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaCtrl = TextEditingController();
  final _cafeCtrl = TextEditingController(text: "Niega");
  final _tabacoCtrl = TextEditingController(text: "Niega");
  final _alcoholCtrl = TextEditingController(text: "Niega");
  final _drogasCtrl = TextEditingController(text: "Niega");
  final _ocupacionCtrl = TextEditingController();
  final _suenoCtrl = TextEditingController();
  final _viviendaCtrl = TextEditingController();
  final _service = AntecedentesService();
  bool _isLoading = false;

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final res = await _service.createHabitos(
      _cedulaCtrl.text, _cafeCtrl.text, _tabacoCtrl.text, _alcoholCtrl.text,
      _drogasCtrl.text, _ocupacionCtrl.text, _suenoCtrl.text, _viviendaCtrl.text
    );
    if (mounted) {
      setState(() => _isLoading = false);
      _mostrarSnack(context, res);
      // No limpiamos campos aquí porque suelen ser muchos valores por defecto
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(children: [
          const Text("Hábitos Psicobiológicos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildInput(_cedulaCtrl, "Cédula Paciente *", isNumber: true),
          const SizedBox(height: 15),
          Row(children: [
             Expanded(child: _buildInput(_cafeCtrl, "Café")),
             const SizedBox(width: 10),
             Expanded(child: _buildInput(_tabacoCtrl, "Tabaco")),
          ]),
          const SizedBox(height: 15),
          Row(children: [
             Expanded(child: _buildInput(_alcoholCtrl, "Alcohol")),
             const SizedBox(width: 10),
             Expanded(child: _buildInput(_drogasCtrl, "Drogas")),
          ]),
          const SizedBox(height: 15),
          _buildInput(_ocupacionCtrl, "Ocupación"),
          const SizedBox(height: 15),
          _buildInput(_suenoCtrl, "Sueño (Ej: 8 horas)"),
          const SizedBox(height: 15),
          _buildInput(_viviendaCtrl, "Vivienda (Ej: Casa/Apto)"),
          const SizedBox(height: 20),
          _buildBtn(_isLoading, _guardar, "Guardar Hábitos"),
        ]),
      ),
    );
  }
}

// --- HELPERS GLOBALES ---
Widget _buildInput(TextEditingController ctrl, String label, {bool isNumber = false, int maxLines = 1, bool isRequired = true}) {
  return TextFormField(
    controller: ctrl,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
     
    ),
    validator: (v) => (isRequired && (v == null || v.isEmpty)) ? 'Obligatorio' : null,
  );
}

Widget _buildBtn(bool loading, VoidCallback press, String text) {
  return SizedBox(
    width: double.infinity, height: 50,
    child: ElevatedButton.icon(
      onPressed: loading ? null : press,
      icon: const Icon(Icons.save),
      label: Text(loading ? "Guardando..." : text),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white),
    ),
  );
}

void _mostrarSnack(BuildContext context, Map<String, dynamic> res) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(res['message']),
    backgroundColor: res['success'] ? Colors.green : Colors.red,
  ));
}