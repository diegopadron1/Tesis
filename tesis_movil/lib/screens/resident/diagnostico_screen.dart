import 'package:flutter/material.dart';
import '../../services/diagnostico_service.dart';

class DiagnosticoScreen extends StatefulWidget {
  const DiagnosticoScreen({super.key});

  @override
  State<DiagnosticoScreen> createState() => _DiagnosticoScreenState();
}

class _DiagnosticoScreenState extends State<DiagnosticoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _diagnosticoController = TextEditingController();
  
  final DiagnosticoService _diagnosticoService = DiagnosticoService();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _cedulaController.dispose();
    _diagnosticoController.dispose();
    super.dispose();
  }

  void _guardarDiagnostico() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _diagnosticoService.createDiagnostico(
      _cedulaController.text.trim(),
      _diagnosticoController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Éxito! ${result['message']}'), 
          backgroundColor: Colors.green
        ),
      );
      // Limpiar campos
      _cedulaController.clear();
      _diagnosticoController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']), 
          backgroundColor: Colors.redAccent
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Motivo Diagnóstico'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "1. Paciente a Diagnosticar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cedulaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cédula del Paciente *',
                  prefixIcon: const Icon(Icons.person_search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 29, 3, 146),
                ),
                validator: (v) => (v == null || v.length < 5) ? 'Cédula inválida' : null,
              ),
              
              const SizedBox(height: 30),

              const Text(
                "2. Diagnóstico Definitivo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _diagnosticoController,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Escriba el diagnóstico médico *',
                  alignLabelWithHint: true,
                  hintText: 'Detalle la patología confirmada...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 29, 3, 146),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'El diagnóstico es obligatorio' : null,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _guardarDiagnostico,
                  icon: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                      : const Icon(Icons.medical_information, size: 28),
                  label: Text(
                    _isLoading ? 'Guardando...' : 'Registrar Diagnóstico', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[800], // Diferenciamos color
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}