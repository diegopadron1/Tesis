import 'package:flutter/material.dart';
import '../../services/motivo_consulta_service.dart';

class MotivoConsultaScreen extends StatefulWidget {
  // Aceptamos la cédula desde el Home
  final String cedulaPaciente;

  const MotivoConsultaScreen({super.key, required this.cedulaPaciente});

  @override
  State<MotivoConsultaScreen> createState() => _MotivoConsultaScreenState();
}

class _MotivoConsultaScreenState extends State<MotivoConsultaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motivoService = MotivoConsultaService(); // Instancia del servicio
  final _motivoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  void _guardarMotivo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Usamos widget.cedulaPaciente
    final result = await _motivoService.createMotivoConsulta(
      widget.cedulaPaciente,
      _motivoController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.green));
      _motivoController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
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
            Text("Paciente: ${widget.cedulaPaciente}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _motivoController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Motivo de Consulta',
                border: OutlineInputBorder(),
                filled: true,
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _guardarMotivo,
                icon: const Icon(Icons.save),
                label: Text(_isLoading ? "Guardando..." : "Registrar Motivo"),
              ),
            )
          ],
        ),
      ),
    );
  }
}