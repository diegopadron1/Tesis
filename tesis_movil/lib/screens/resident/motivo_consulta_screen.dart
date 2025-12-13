import 'package:flutter/material.dart';
import '../../services/motivo_consulta_service.dart';
import '../../services/triaje_service.dart'; 

class MotivoConsultaScreen extends StatefulWidget {
  final String cedulaPaciente;

  const MotivoConsultaScreen({super.key, required this.cedulaPaciente});

  @override
  State<MotivoConsultaScreen> createState() => _MotivoConsultaScreenState();
}

class _MotivoConsultaScreenState extends State<MotivoConsultaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- SECCIÓN 1: MOTIVO ---
  final _motivoService = MotivoConsultaService();
  final _motivoController = TextEditingController();

  // --- SECCIÓN 2: TRIAJE ---
  final _triajeService = TriajeService();
  final _signosVitalesController = TextEditingController();
  
  // Valores por defecto
  String _colorSeleccionado = 'Verde';
  String _ubicacionSeleccionada = 'Sillas';

  // Listas de opciones
  final List<String> _colores = ['Rojo', 'Naranja', 'Amarillo', 'Verde', 'Azul'];
  final List<String> _zonas = [
    'Pasillo 1', 
    'Pasillo 2', 
    'Quirofanito paciente delicados', 
    'Trauma shock', 
    'Sillas', 
    'Libanes', 
    'USAV'
  ];

  @override
  void dispose() {
    _motivoController.dispose();
    _signosVitalesController.dispose();
    super.dispose();
  }

  Color _getColor(String color) {
    switch (color) {
      case 'Rojo': return Colors.red;
      case 'Naranja': return Colors.orange;
      case 'Amarillo': return Colors.yellow.shade700;
      case 'Verde': return Colors.green;
      case 'Azul': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _guardarTodo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // PASO 1: Guardar Motivo
    final resMotivo = await _motivoService.createMotivoConsulta(
      widget.cedulaPaciente,
      _motivoController.text.trim(),
    );

    if (!resMotivo['success']) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resMotivo['message']), backgroundColor: Colors.red)
        );
      }
      return; 
    }

    // PASO 2: Guardar Triaje
    final resTriaje = await _triajeService.createTriaje(
      cedulaPaciente: widget.cedulaPaciente,
      color: _colorSeleccionado,
      ubicacion: _ubicacionSeleccionada,
      signosVitales: _signosVitalesController.text.trim(),
      motivoIngreso: _motivoController.text.trim(), 
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resTriaje['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingreso registrado correctamente"), backgroundColor: Colors.green)
      );
      _motivoController.clear();
      _signosVitalesController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Motivo guardado, pero error en Triaje: ${resTriaje['message']}"), backgroundColor: Colors.orange)
      );
    }
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
            // --- SECCIÓN 1: MOTIVO ---
            const Text("1. Motivo de Consulta", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Divider(),
            const SizedBox(height: 10),
            
            TextFormField(
              controller: _motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Describa el motivo *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
                filled: true,
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),

            const SizedBox(height: 30),

            // --- SECCIÓN 2: TRIAJE ---
            const Text("2. Triaje y Ubicación", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Divider(),
            const SizedBox(height: 10),

            // Selector de Color
            DropdownButtonFormField<String>(
              // CORRECCIÓN: Usamos initialValue en lugar de value
              initialValue: _colorSeleccionado,
              decoration: InputDecoration(
                labelText: 'Nivel de Urgencia (Color)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.circle, color: _getColor(_colorSeleccionado)),
                filled: true,
              ),
              items: _colores.map((color) => DropdownMenuItem(
                value: color,
                child: Text(color, style: TextStyle(
                  color: _getColor(color), 
                  fontWeight: FontWeight.bold
                )),
              )).toList(),
              onChanged: (v) {
                setState(() {
                  _colorSeleccionado = v!;
                });
              },
            ),
            const SizedBox(height: 15),

            // Selector de Zona
            DropdownButtonFormField<String>(
              // CORRECCIÓN: Usamos initialValue en lugar de value
              initialValue: _ubicacionSeleccionada,
              isExpanded: true, 
              decoration: const InputDecoration(
                labelText: 'Zona Asignada',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                filled: true,
              ),
              items: _zonas.map((zona) => DropdownMenuItem(
                value: zona,
                child: Text(zona),
              )).toList(),
              onChanged: (v) {
                setState(() {
                  _ubicacionSeleccionada = v!;
                });
              },
            ),
            const SizedBox(height: 15),

            // Signos Vitales
            TextFormField(
              controller: _signosVitalesController,
              decoration: const InputDecoration(
                labelText: 'Signos Vitales (TA, FC, Tº)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_heart),
                filled: true,
              ),
            ),

            const SizedBox(height: 40),

            // Botón Guardar
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _guardarTodo,
                icon: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_as),
                label: Text(
                  _isLoading ? "Guardando..." : "Registrar Consulta y Triaje",
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}