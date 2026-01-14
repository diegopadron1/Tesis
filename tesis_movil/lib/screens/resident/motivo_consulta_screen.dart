import 'package:flutter/material.dart';
import '../../services/motivo_consulta_service.dart';
import '../../services/triaje_service.dart'; 

class MotivoConsultaScreen extends StatefulWidget {
  final String cedulaPaciente;
  final bool readOnly; 

  const MotivoConsultaScreen({
    super.key, 
    required this.cedulaPaciente, 
    this.readOnly = false 
  });

  @override
  State<MotivoConsultaScreen> createState() => _MotivoConsultaScreenState();
}

class _MotivoConsultaScreenState extends State<MotivoConsultaScreen> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _formularioBloqueado = false; 

  int? _idMotivoGuardado;
  int? _idTriajeGuardado;

  final _motivoService = MotivoConsultaService();
  final _triajeService = TriajeService();

  final _motivoController = TextEditingController();
  final _signosVitalesController = TextEditingController();
  
  String _colorSeleccionado = 'Verde';
  String _ubicacionSeleccionada = 'Sillas';

  final List<String> _colores = ['Rojo', 'Naranja', 'Amarillo', 'Verde', 'Azul'];
  final List<String> _zonas = [
    'Pasillo 1', 'Pasillo 2', 'Quirofanito paciente delicados', 
    'Trauma shock', 'Sillas', 'Libanes', 'USAV'
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _signosVitalesController.dispose();
    super.dispose();
  }

  void _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final res = await _motivoService.getDatosHoy(widget.cedulaPaciente);
      if (mounted && res['success'] && res['data'] != null) {
        final data = res['data'];
        bool datosEncontrados = false;

        setState(() {
          if (data['motivo'] != null) {
             _motivoController.text = data['motivo']['motivo_consulta'] ?? '';
             _idMotivoGuardado = data['motivo']['id_consulta'] ?? data['motivo']['id'];
             datosEncontrados = true;
          }
          if (data['triaje'] != null) {
             _signosVitalesController.text = data['triaje']['signos_vitales'] ?? '';
             if (_colores.contains(data['triaje']['color'])) {
               _colorSeleccionado = data['triaje']['color'];
             }
             if (_zonas.contains(data['triaje']['ubicacion'])) {
               _ubicacionSeleccionada = data['triaje']['ubicacion'];
             }
             _idTriajeGuardado = data['triaje']['id_triaje'] ?? data['triaje']['id'];
             datosEncontrados = true;
          }
          if (datosEncontrados) _formularioBloqueado = true;
        });
      }
    } catch (e) {
      debugPrint("Error cargando datos: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _guardarTodo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    Map<String, dynamic> resMotivo;
    if (_idMotivoGuardado == null) {
      resMotivo = await _motivoService.createMotivoConsulta(widget.cedulaPaciente, _motivoController.text.trim());
    } else {
      resMotivo = await _motivoService.updateMotivo(_idMotivoGuardado!, _motivoController.text.trim());
    }

    if (!resMotivo['success']) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resMotivo['message']), backgroundColor: Colors.red));
      return; 
    }

    Map<String, dynamic> resTriaje;
    if (_idTriajeGuardado == null) {
      resTriaje = await _triajeService.createTriaje(
        cedulaPaciente: widget.cedulaPaciente,
        color: _colorSeleccionado,
        ubicacion: _ubicacionSeleccionada,
        signosVitales: _signosVitalesController.text.trim(),
        motivoIngreso: _motivoController.text.trim(), 
      );
    } else {
      resTriaje = await _triajeService.updateTriaje(_idTriajeGuardado!, {
        'color': _colorSeleccionado,
        'ubicacion': _ubicacionSeleccionada,
        'signos_vitales': _signosVitalesController.text.trim(),
        'motivo_ingreso': _motivoController.text.trim(),
      });
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resTriaje['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Información guardada"), backgroundColor: Colors.green));
      setState(() => _formularioBloqueado = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${resTriaje['message']}"), backgroundColor: Colors.orange));
    }
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool bloqueadoPorRol = _formularioBloqueado || widget.readOnly;

    if (_isLoading && _idMotivoGuardado == null && _idTriajeGuardado == null) {
       return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("1. Motivo de Consulta", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                if (bloqueadoPorRol) const Icon(Icons.lock, color: Colors.grey, size: 20)
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            
            TextFormField(
              controller: _motivoController,
              enabled: !bloqueadoPorRol,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Motivo de Ingreso', border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit_note), filled: true),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),

            const SizedBox(height: 30),
            const Text("2. Triaje y Ubicación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Divider(),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              initialValue: _colorSeleccionado, 
              key: Key("color_$_colorSeleccionado"), 
              onChanged: bloqueadoPorRol ? null : (v) => setState(() => _colorSeleccionado = v!),
              decoration: InputDecoration(labelText: 'Nivel de Urgencia', border: const OutlineInputBorder(), prefixIcon: Icon(Icons.circle, color: _getColor(_colorSeleccionado)), filled: true),
              items: _colores.map((color) => DropdownMenuItem(value: color, child: Text(color, style: TextStyle(color: _getColor(color), fontWeight: FontWeight.bold)))).toList(),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              initialValue: _ubicacionSeleccionada, 
              key: Key("zona_$_ubicacionSeleccionada"),
              onChanged: bloqueadoPorRol ? null : (v) => setState(() => _ubicacionSeleccionada = v!),
              isExpanded: true, 
              decoration: const InputDecoration(labelText: 'Zona Asignada', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on), filled: true),
              items: _zonas.map((zona) => DropdownMenuItem(value: zona, child: Text(zona))).toList(),
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _signosVitalesController,
              enabled: !bloqueadoPorRol,
              decoration: const InputDecoration(labelText: 'Signos Vitales (TA, FC, Tº)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.monitor_heart), filled: true),
            ),

            const SizedBox(height: 40),

            // --- CAMBIO SOLICITADO: OCULTAR BOTÓN COMPLETAMENTE SI ES READONLY ---
            if (!widget.readOnly) 
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading 
                      ? null 
                      : () {
                          if (_formularioBloqueado) {
                            setState(() => _formularioBloqueado = false);
                          } else {
                            _guardarTodo();
                          }
                        },
                  icon: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(_formularioBloqueado ? Icons.edit : Icons.save_as),
                  label: Text(
                    _isLoading ? "Guardando..." : (_formularioBloqueado ? "Editar Consulta y Triaje" : "Guardar Información"),
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _formularioBloqueado ? Colors.orange[800] : Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            else
              const Center(
                child: Text(
                  "Modo Consulta",
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }
}