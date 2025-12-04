import 'package:flutter/material.dart';
import '../../services/examen_service.dart';

class ExamenScreen extends StatefulWidget {
  final String cedulaPaciente; // Recibimos cédula

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
    return Column( // Quitamos Scaffold porque ya estamos dentro de uno
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
              // Pasamos la cédula a los hijos
              _FormularioFisico(cedula: widget.cedulaPaciente),
              _FormularioFuncional(cedula: widget.cedulaPaciente),
            ],
          ),
        ),
      ],
    );
  }
}

// --- SUB-WIDGET FÍSICO ---
class _FormularioFisico extends StatefulWidget {
  final String cedula;
  const _FormularioFisico({required this.cedula});

  @override
  State<_FormularioFisico> createState() => _FormularioFisicoState();
}

class _FormularioFisicoState extends State<_FormularioFisico> {
  final _formKey = GlobalKey<FormState>();
  final _areaCtrl = TextEditingController();
  final _hallazgosCtrl = TextEditingController();
  final _service = ExamenService();
  bool _isLoading = false;

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    final res = await _service.createExamenFisico(widget.cedula, _areaCtrl.text, _hallazgosCtrl.text); // Usamos widget.cedula
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red));
      if (res['success']) { _areaCtrl.clear(); _hallazgosCtrl.clear(); }
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
             TextFormField(controller: _areaCtrl, decoration: const InputDecoration(labelText: "Área (Ej: Tórax)", border: OutlineInputBorder()), validator: (v)=>v!.isEmpty?'Requerido':null),
             const SizedBox(height: 15),
             TextFormField(controller: _hallazgosCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Hallazgos", border: OutlineInputBorder()), validator: (v)=>v!.isEmpty?'Requerido':null),
             const SizedBox(height: 20),
             ElevatedButton.icon(onPressed: _isLoading ? null : _guardar, icon: const Icon(Icons.save), label: const Text("Guardar Físico"))
          ],
        ),
      ),
    );
  }
}

// --- SUB-WIDGET FUNCIONAL ---
class _FormularioFuncional extends StatefulWidget {
  final String cedula;
  const _FormularioFuncional({required this.cedula});
  @override
  State<_FormularioFuncional> createState() => _FormularioFuncionalState();
}

class _FormularioFuncionalState extends State<_FormularioFuncional> {
  final _formKey = GlobalKey<FormState>();
  final _sistemaCtrl = TextEditingController();
  final _hallazgosCtrl = TextEditingController();
  final _service = ExamenService();
  bool _isLoading = false;

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    final res = await _service.createExamenFuncional(widget.cedula, _sistemaCtrl.text, _hallazgosCtrl.text);
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red));
      if (res['success']) { _sistemaCtrl.clear(); _hallazgosCtrl.clear(); }
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
             TextFormField(controller: _sistemaCtrl, decoration: const InputDecoration(labelText: "Sistema (Ej: Respiratorio)", border: OutlineInputBorder()), validator: (v)=>v!.isEmpty?'Requerido':null),
             const SizedBox(height: 15),
             TextFormField(controller: _hallazgosCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Hallazgos", border: OutlineInputBorder()), validator: (v)=>v!.isEmpty?'Requerido':null),
             const SizedBox(height: 20),
             ElevatedButton.icon(onPressed: _isLoading ? null : _guardar, icon: const Icon(Icons.save), label: const Text("Guardar Funcional"))
          ],
        ),
      ),
    );
  }
}