import 'package:flutter/material.dart';
import '../../services/diagnostico_service.dart';

class DiagnosticoScreen extends StatefulWidget {
  const DiagnosticoScreen({super.key});

  @override
  State<DiagnosticoScreen> createState() => _DiagnosticoScreenState();
}

class _DiagnosticoScreenState extends State<DiagnosticoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores Básicos
  final _cedulaCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  
  // Controladores Órdenes Médicas (Nuevos)
  final _indicacionesCtrl = TextEditingController();
  final _tratamientosCtrl = TextEditingController();
  final _medicamentosCtrl = TextEditingController();
  final _examenesCtrl = TextEditingController();
  final _conductaCtrl = TextEditingController();

  String _tipoDiagnostico = 'Presuntivo';
  final DiagnosticoService _service = DiagnosticoService();
  bool _isLoading = false;

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _service.createDiagnostico({
      'cedula_paciente': _cedulaCtrl.text.trim(),
      'descripcion': _descripcionCtrl.text.trim(),
      'tipo': _tipoDiagnostico,
      'observaciones': _observacionesCtrl.text.trim(),
      // Nuevos campos
      'indicaciones_inmediatas': _indicacionesCtrl.text.trim(),
      'tratamientos_sugeridos': _tratamientosCtrl.text.trim(),
      'requerimiento_medicamentos': _medicamentosCtrl.text.trim(),
      'examenes_complementarios': _examenesCtrl.text.trim(),
      'conducta_seguir': _conductaCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );
      _limpiarFormulario();
    } else {
      // Aquí se mostrará el mensaje de error si faltan antecedentes, etc.
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("No se puede guardar"),
          content: Text(result['message'], style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Entendido"))
          ],
        ),
      );
    }
  }

  void _limpiarFormulario() {
    _cedulaCtrl.clear();
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
            const Text("1. Datos del Diagnóstico", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const Divider(),
            _buildInput(_cedulaCtrl, "Cédula del Paciente", icon: Icons.person, isNumber: true),
            const SizedBox(height: 15),
            _buildInput(_descripcionCtrl, "Diagnóstico (Ej: Neumonía)", maxLines: 2),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _tipoDiagnostico,
              decoration: InputDecoration(
                labelText: "Tipo de Diagnóstico",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: ['Presuntivo', 'Definitivo']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _tipoDiagnostico = v!),
            ),
            const SizedBox(height: 15),
            _buildInput(_observacionesCtrl, "Observaciones Generales", maxLines: 2, isRequired: false),
            
            const SizedBox(height: 30),
            const Text("2. Órdenes Médicas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const Divider(),
            
            _buildInput(_indicacionesCtrl, "Indicaciones Inmediatas", maxLines: 2, isRequired: false),
            const SizedBox(height: 10),
            _buildInput(_tratamientosCtrl, "Tratamientos Sugeridos", maxLines: 2, isRequired: false),
            const SizedBox(height: 10),
            _buildInput(_medicamentosCtrl, "Requerimiento de Medicamentos", maxLines: 2, isRequired: false),
            const SizedBox(height: 10),
            _buildInput(_examenesCtrl, "Exámenes Complementarios", maxLines: 2, isRequired: false),
            const SizedBox(height: 10),
            _buildInput(_conductaCtrl, "Conducta a Seguir (Ej: Hospitalizar)", maxLines: 2, isRequired: false),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _guardar,
                icon: const Icon(Icons.save_as),
                label: Text(_isLoading ? "Verificando y Guardando..." : "Emitir Diagnóstico y Órdenes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, {IconData? icon, bool isNumber = false, int maxLines = 1, bool isRequired = true}) {
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
      validator: (v) {
        if (!isRequired) return null;
        return (v == null || v.isEmpty) ? 'Campo obligatorio' : null;
      },
    );
  }
}