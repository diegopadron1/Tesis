import 'package:flutter/material.dart';
import '../../services/diagnostico_service.dart';

class DiagnosticoScreen extends StatefulWidget {
  final String cedulaPaciente; // Mantenemos la recepción de la cédula

  const DiagnosticoScreen({super.key, required this.cedulaPaciente});

  @override
  State<DiagnosticoScreen> createState() => _DiagnosticoScreenState();
}

class _DiagnosticoScreenState extends State<DiagnosticoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // --- CONTROLADORES ---
  final _descripcionCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  
  // Controladores Órdenes Médicas (Restaurados)
  final _indicacionesCtrl = TextEditingController();
  final _tratamientosCtrl = TextEditingController(); // Restaurado
  final _medicamentosCtrl = TextEditingController();
  final _examenesCtrl = TextEditingController();     // Restaurado
  final _conductaCtrl = TextEditingController();     // Restaurado

  String _tipoDiagnostico = 'Presuntivo';
  final DiagnosticoService _service = DiagnosticoService();
  bool _isLoading = false;

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Enviamos TODOS los campos al servicio
    final result = await _service.createDiagnostico({
      'cedula_paciente': widget.cedulaPaciente, // Usamos la cédula que viene del widget
      'descripcion': _descripcionCtrl.text.trim(),
      'tipo': _tipoDiagnostico,
      'observaciones': _observacionesCtrl.text.trim(),
      // Campos de órdenes médicas
      'indicaciones_inmediatas': _indicacionesCtrl.text.trim(),
      'tratamientos_sugeridos': _tratamientosCtrl.text.trim(),
      'requerimiento_medicamentos': _medicamentosCtrl.text.trim(),
      'examenes_complementarios': _examenesCtrl.text.trim(),
      'conducta_seguir': _conductaCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']), 
        backgroundColor: result['success'] ? Colors.green : Colors.red
      )
    );
    
    if (result['success']) {
       _limpiarFormulario();
    }
  }

  void _limpiarFormulario() {
    _descripcionCtrl.clear();
    _observacionesCtrl.clear();
    _indicacionesCtrl.clear();
    _tratamientosCtrl.clear();
    _medicamentosCtrl.clear();
    _examenesCtrl.clear();
    _conductaCtrl.clear();
    setState(() => _tipoDiagnostico = 'Presuntivo');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN 1: DATOS DEL DIAGNÓSTICO ---
            const Text("1. Datos del Diagnóstico", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const Divider(),
            const SizedBox(height: 10),

            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Diagnóstico Principal *", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 15),
            
            DropdownButtonFormField<String>(
              initialValue: _tipoDiagnostico, 
              items: ['Presuntivo', 'Definitivo'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _tipoDiagnostico = v!),
              decoration: const InputDecoration(labelText: "Tipo", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _observacionesCtrl, // Campo restaurado en la vista
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Observaciones Generales", border: OutlineInputBorder()),
            ),

            const SizedBox(height: 30),

            // --- SECCIÓN 2: ÓRDENES MÉDICAS ---
            const Text("2. Órdenes Médicas", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const Divider(),
            const SizedBox(height: 10),

            TextFormField(
              controller: _indicacionesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Indicaciones Inmediatas", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextFormField( // Campo Restaurado
              controller: _tratamientosCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Tratamientos Sugeridos", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _medicamentosCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Requerimiento de Medicamentos", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextFormField( // Campo Restaurado
              controller: _examenesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Exámenes Complementarios", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextFormField( // Campo Restaurado
              controller: _conductaCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Conducta a Seguir (Ej: Hospitalizar)", border: OutlineInputBorder()),
            ),
            
            const SizedBox(height: 30),

            // --- BOTÓN ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _guardar,
                icon: const Icon(Icons.save_as),
                label: Text(_isLoading ? "Guardando..." : "Emitir Diagnóstico y Órdenes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}