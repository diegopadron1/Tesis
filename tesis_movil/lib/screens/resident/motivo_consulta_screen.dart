import 'package:flutter/material.dart';
import '../../services/motivo_consulta_service.dart';

class MotivoConsultaScreen extends StatefulWidget {
  // Constructor simple: No requiere recibir datos de otra pantalla
  const MotivoConsultaScreen({super.key});

  @override
  State<MotivoConsultaScreen> createState() => _MotivoConsultaScreenState();
}

class _MotivoConsultaScreenState extends State<MotivoConsultaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores: Uno para la cédula (ahora manual) y otro para el motivo
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();
  
  final MotivoConsultaService _motivoService = MotivoConsultaService();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _cedulaController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  void _guardarMotivo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Enviamos los datos capturados en los inputs al servicio
    final result = await _motivoService.createMotivoConsulta(
      _cedulaController.text.trim(),
      _motivoController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      // ÉXITO: Mostramos mensaje verde
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Éxito! ${result['message']}'), 
          backgroundColor: Colors.green
        ),
      );
      
      // Limpiamos campos para permitir otro registro inmediato
      _cedulaController.clear();
      _motivoController.clear();
      
    } else {
      // ERROR: Mostramos mensaje rojo
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
        title: const Text('Nuevo Motivo de Consulta'),
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
                "1. Identificación del Paciente",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 15),

              // --- CAMPO DE CÉDULA (EDITABLE) ---
              TextFormField(
                controller: _cedulaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cédula del Paciente *',
                  hintText: 'Ingrese la cédula del paciente',
                  prefixIcon: const Icon(Icons.person_search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 29, 3, 146),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La cédula es obligatoria.';
                  }
                  if (value.length < 5) {
                    return 'Ingrese una cédula válida.';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 30),

              const Text(
                "2. Detalle de la Emergencia",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 15),

              // --- CAMPO DE MOTIVO ---
              TextFormField(
                controller: _motivoController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Motivo de Consulta *',
                  alignLabelWithHint: true,
                  hintText: 'Describa síntomas, dolor, tiempo, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 29, 3, 146),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El motivo es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // --- BOTÓN GUARDAR ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _guardarMotivo,
                  icon: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                      : const Icon(Icons.save, size: 28),
                  label: Text(
                    _isLoading ? 'Guardando...' : 'Registrar Motivo', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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