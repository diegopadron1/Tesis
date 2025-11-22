import 'package:flutter/material.dart';
import '../../services/examen_service.dart';

class ExamenScreen extends StatefulWidget {
  const ExamenScreen({super.key});

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
    // Usamos Scaffold para tener AppBar propia con pestañas
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulo de Exámenes'),
        backgroundColor: Colors.teal[700], // Color diferente para distinguir
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.accessibility), text: "Examen Físico"),
            Tab(icon: Icon(Icons.settings_accessibility), text: "Examen Funcional"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FormularioFisico(),
          _FormularioFuncional(),
        ],
      ),
    );
  }
}

// --- SUB-WIDGET: Formulario Examen Físico ---
class _FormularioFisico extends StatefulWidget {
  const _FormularioFisico();

  @override
  State<_FormularioFisico> createState() => _FormularioFisicoState();
}

class _FormularioFisicoState extends State<_FormularioFisico> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _hallazgosCtrl = TextEditingController();
  final _service = ExamenService();
  bool _isLoading = false;

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    final res = await _service.createExamenFisico(
      _cedulaCtrl.text.trim(),
      _areaCtrl.text.trim(),
      _hallazgosCtrl.text.trim(),
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message']),
        backgroundColor: res['success'] ? Colors.green : Colors.red,
      ));
      if (res['success']) {
        _areaCtrl.clear();
        _hallazgosCtrl.clear();
        // No limpiamos la cédula por si quiere registrar otra área al mismo paciente
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
            const Text("Registro de Examen Físico", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildInput(_cedulaCtrl, "Cédula Paciente", icon: Icons.person, isNumber: true),
            const SizedBox(height: 15),
            _buildInput(_areaCtrl, "Área (Ej: Abdomen, Tórax)", icon: Icons.location_on),
            const SizedBox(height: 15),
            _buildInput(_hallazgosCtrl, "Hallazgos Físicos", maxLines: 4),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _guardar,
              icon: const Icon(Icons.save),
              label: Text(_isLoading ? "Guardando..." : "Guardar Físico"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            )
          ],
        ),
      ),
    );
  }
}

// --- SUB-WIDGET: Formulario Examen Funcional ---
class _FormularioFuncional extends StatefulWidget {
  const _FormularioFuncional();

  @override
  State<_FormularioFuncional> createState() => _FormularioFuncionalState();
}

class _FormularioFuncionalState extends State<_FormularioFuncional> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaCtrl = TextEditingController();
  final _sistemaCtrl = TextEditingController();
  final _hallazgosCtrl = TextEditingController();
  final _service = ExamenService();
  bool _isLoading = false;

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    final res = await _service.createExamenFuncional(
      _cedulaCtrl.text.trim(),
      _sistemaCtrl.text.trim(),
      _hallazgosCtrl.text.trim(),
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message']),
        backgroundColor: res['success'] ? Colors.green : Colors.red,
      ));
      if (res['success']) {
        _sistemaCtrl.clear();
        _hallazgosCtrl.clear();
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
            const Text("Registro de Examen Funcional", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildInput(_cedulaCtrl, "Cédula Paciente", icon: Icons.person, isNumber: true),
            const SizedBox(height: 15),
            _buildInput(_sistemaCtrl, "Sistema (Ej: Respiratorio)", icon: Icons.settings_system_daydream),
            const SizedBox(height: 15),
            _buildInput(_hallazgosCtrl, "Hallazgos Funcionales", maxLines: 4),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _guardar,
              icon: const Icon(Icons.save),
              label: Text(_isLoading ? "Guardando..." : "Guardar Funcional"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800], foregroundColor: Colors.white),
            )
          ],
        ),
      ),
    );
  }
}

// Helper simple para inputs
Widget _buildInput(TextEditingController ctrl, String label, {IconData? icon, bool isNumber = false, int maxLines = 1}) {
  return TextFormField(
    controller: ctrl,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      
    ),
    validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
  );
}