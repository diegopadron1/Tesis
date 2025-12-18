import 'package:flutter/material.dart';
import '../../services/motivo_consulta_service.dart';
import '../../services/triaje_service.dart'; 

class MotivoConsultaScreen extends StatefulWidget {
  final String cedulaPaciente;

  const MotivoConsultaScreen({super.key, required this.cedulaPaciente});

  @override
  State<MotivoConsultaScreen> createState() => _MotivoConsultaScreenState();
}

// 1. AGREGAMOS EL MIXIN AQUÍ
class _MotivoConsultaScreenState extends State<MotivoConsultaScreen> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Controla si el formulario es editable
  bool _formularioBloqueado = false; 

  // --- VARIABLES PARA CONTROLAR EDICIÓN (Evitar Duplicados) ---
  int? _idMotivoGuardado;
  int? _idTriajeGuardado;
  // ----------------------------------------------------------

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
    'Pasillo 1', 'Pasillo 2', 'Quirofanito paciente delicados', 
    'Trauma shock', 'Sillas', 'Libanes', 'USAV'
  ];

  // 2. INDICAMOS QUE QUEREMOS MANTENER VIVO EL ESTADO
  @override
  bool get wantKeepAlive => true;

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

  // --- FUNCIÓN INTELIGENTE: CREAR O ACTUALIZAR ---
  void _guardarTodo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // =============================================
    // PASO 1: MOTIVO DE CONSULTA
    // =============================================
    Map<String, dynamic> resMotivo;
    
    if (_idMotivoGuardado == null) {
      // A) No existe ID -> CREAMOS NUEVO
      resMotivo = await _motivoService.createMotivoConsulta(
        widget.cedulaPaciente,
        _motivoController.text.trim(),
      );
    } else {
      // B) Ya existe ID -> ACTUALIZAMOS
      resMotivo = await _motivoService.updateMotivo(
        _idMotivoGuardado!,
        _motivoController.text.trim(),
      );
    }

    if (!resMotivo['success']) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resMotivo['message']), backgroundColor: Colors.red)
        );
      }
      return; 
    }

    // --- CAPTURAR ID DEL MOTIVO ---
    if (_idMotivoGuardado == null && resMotivo['data'] != null) {
        var idCapturado = resMotivo['data']['id_consulta'];
        idCapturado ??= resMotivo['data']['id']; 

        if (idCapturado != null) {
          _idMotivoGuardado = idCapturado;
          debugPrint("✅ ID MOTIVO CAPTURADO: $_idMotivoGuardado"); 
        }
    }

    // =============================================
    // PASO 2: TRIAJE
    // =============================================
    Map<String, dynamic> resTriaje;

    if (_idTriajeGuardado == null) {
      // A) No existe ID -> CREAMOS NUEVO
      resTriaje = await _triajeService.createTriaje(
        cedulaPaciente: widget.cedulaPaciente,
        color: _colorSeleccionado,
        ubicacion: _ubicacionSeleccionada,
        signosVitales: _signosVitalesController.text.trim(),
        motivoIngreso: _motivoController.text.trim(), 
      );
    } else {
      // B) Ya existe ID -> ACTUALIZAMOS
      resTriaje = await _triajeService.updateTriaje(
        _idTriajeGuardado!,
        {
          'color': _colorSeleccionado,
          'ubicacion': _ubicacionSeleccionada,
          'signos_vitales': _signosVitalesController.text.trim(),
          'motivo_ingreso': _motivoController.text.trim(),
        }
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resTriaje['success']) {
      // --- CAPTURAR ID DEL TRIAJE ---
      if (_idTriajeGuardado == null && resTriaje['data'] != null) {
         var idCapturado = resTriaje['data']['id_triaje'];
         idCapturado ??= resTriaje['data']['id']; 

         if (idCapturado != null) {
            _idTriajeGuardado = idCapturado;
            debugPrint("✅ ID TRIAJE CAPTURADO: $_idTriajeGuardado");
         }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Información guardada correctamente"), backgroundColor: Colors.green)
      );
      
      // Bloqueamos el formulario tras guardar/actualizar con éxito
      setState(() {
        _formularioBloqueado = true;
      });

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error en Triaje: ${resTriaje['message']}"), backgroundColor: Colors.orange)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. LLAMAMOS A SUPER.BUILD AL INICIO
    super.build(context);

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
              enabled: !_formularioBloqueado, 
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
              initialValue: _colorSeleccionado,
              key: Key("color_$_colorSeleccionado"), 
              
              onChanged: _formularioBloqueado ? null : (v) {
                setState(() {
                  _colorSeleccionado = v!;
                });
              },
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
            ),
            const SizedBox(height: 15),

            // Selector de Zona
            DropdownButtonFormField<String>(
              initialValue: _ubicacionSeleccionada,
              key: Key("zona_$_ubicacionSeleccionada"),

              onChanged: _formularioBloqueado ? null : (v) {
                setState(() {
                  _ubicacionSeleccionada = v!;
                });
              },
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
            ),
            const SizedBox(height: 15),

            // Signos Vitales
            TextFormField(
              controller: _signosVitalesController,
              enabled: !_formularioBloqueado, 
              decoration: const InputDecoration(
                labelText: 'Signos Vitales (TA, FC, Tº)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_heart),
                filled: true,
              ),
            ),

            const SizedBox(height: 40),

            // BOTÓN DINÁMICO
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading 
                    ? null 
                    : () {
                        if (_formularioBloqueado) {
                          // QUEREMOS EDITAR: Desbloqueamos
                          setState(() {
                            _formularioBloqueado = false;
                          });
                        } else {
                          // QUEREMOS GUARDAR: Llamamos a la lógica inteligente
                          _guardarTodo();
                        }
                      },
                icon: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(_formularioBloqueado ? Icons.edit : Icons.save_as),
                label: Text(
                  _isLoading 
                      ? "Guardando..." 
                      : (_formularioBloqueado ? "Editar Consulta y Triaje" : "Registrar Consulta y Triaje"),
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _formularioBloqueado ? Colors.orange[800] : Colors.blue[800],
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