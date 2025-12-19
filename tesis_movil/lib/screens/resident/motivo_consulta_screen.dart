import 'package:flutter/material.dart';
import '../../services/motivo_consulta_service.dart';
import '../../services/triaje_service.dart'; 

class MotivoConsultaScreen extends StatefulWidget {
  final String cedulaPaciente;

  const MotivoConsultaScreen({super.key, required this.cedulaPaciente});

  @override
  State<MotivoConsultaScreen> createState() => _MotivoConsultaScreenState();
}

class _MotivoConsultaScreenState extends State<MotivoConsultaScreen> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Controla si el formulario es editable
  // Si encontramos datos al entrar, esto será TRUE (bloqueado)
  bool _formularioBloqueado = false; 

  // --- VARIABLES PARA CONTROLAR EDICIÓN (Evitar Duplicados) ---
  int? _idMotivoGuardado;
  int? _idTriajeGuardado;

  // --- SERVICIOS ---
  final _motivoService = MotivoConsultaService();
  final _triajeService = TriajeService();

  // --- CONTROLADORES ---
  final _motivoController = TextEditingController();
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 1. CARGAR DATOS AL INICIAR
    _cargarDatos();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _signosVitalesController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN PARA CARGAR DATOS DESDE LA BD ---
  void _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      // Llamamos al servicio (Asegúrate de haber agregado getDatosHoy en tu servicio)
      final res = await _motivoService.getDatosHoy(widget.cedulaPaciente);

      if (mounted) {
        if (res['success'] && res['data'] != null) {
          final data = res['data'];
          bool datosEncontrados = false;

          setState(() {
            // A. LLENAR MOTIVO SI EXISTE
            if (data['motivo'] != null) {
               _motivoController.text = data['motivo']['motivo_consulta'] ?? '';
               _idMotivoGuardado = data['motivo']['id_consulta'] ?? data['motivo']['id'];
               datosEncontrados = true;
               debugPrint("✅ Motivo cargado: ${_motivoController.text}");
            }

            // B. LLENAR TRIAJE SI EXISTE
            if (data['triaje'] != null) {
               _signosVitalesController.text = data['triaje']['signos_vitales'] ?? '';
               
               // Validar color
               String colorTraido = data['triaje']['color'];
               if (_colores.contains(colorTraido)) {
                 _colorSeleccionado = colorTraido;
               }

               // Validar ubicación
               String ubicacionTraida = data['triaje']['ubicacion'];
               if (_zonas.contains(ubicacionTraida)) {
                 _ubicacionSeleccionada = ubicacionTraida;
               }

               _idTriajeGuardado = data['triaje']['id_triaje'] ?? data['triaje']['id'];
               datosEncontrados = true;
               debugPrint("✅ Triaje cargado.");
            }

            // Si encontramos datos, bloqueamos el formulario para que se vea "Guardado"
            if (datosEncontrados) {
              _formularioBloqueado = true;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error cargando datos: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNCIÓN GUARDAR / ACTUALIZAR ---
  void _guardarTodo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // 1. MOTIVO
    Map<String, dynamic> resMotivo;
    if (_idMotivoGuardado == null) {
      resMotivo = await _motivoService.createMotivoConsulta(
        widget.cedulaPaciente,
        _motivoController.text.trim(),
      );
    } else {
      resMotivo = await _motivoService.updateMotivo(
        _idMotivoGuardado!,
        _motivoController.text.trim(),
      );
    }

    if (!resMotivo['success']) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resMotivo['message']), backgroundColor: Colors.red));
      return; 
    }

    // Capturar ID Motivo
    if (_idMotivoGuardado == null && resMotivo['data'] != null) {
        var id = resMotivo['data']['id_consulta'] ?? resMotivo['data']['id'];
        if (id != null) _idMotivoGuardado = id;
    }

    // 2. TRIAJE
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
      if (_idTriajeGuardado == null && resTriaje['data'] != null) {
         var id = resTriaje['data']['id_triaje'] ?? resTriaje['data']['id'];
         if (id != null) _idTriajeGuardado = id;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Información guardada correctamente"), backgroundColor: Colors.green)
      );
      
      // AL GUARDAR EXITOSAMENTE, BLOQUEAMOS (MODO VISUALIZACIÓN)
      setState(() {
        _formularioBloqueado = true;
      });

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error en Triaje: ${resTriaje['message']}"), backgroundColor: Colors.orange)
      );
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

    // Spinner inicial mientras carga datos
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
            // --- SECCIÓN 1: MOTIVO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("1. Motivo de Consulta", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                if (_formularioBloqueado) const Icon(Icons.lock, color: Colors.grey, size: 20)
              ],
            ),
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
            const Text("2. Triaje y Ubicación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Divider(),
            const SizedBox(height: 10),

            // Selector de Color
            DropdownButtonFormField<String>(
              initialValue: _colorSeleccionado, // Usamos 'value' no 'initialValue' para que se actualice al cargar
              key: Key("color_$_colorSeleccionado"), 
              onChanged: _formularioBloqueado ? null : (v) {
                setState(() => _colorSeleccionado = v!);
              },
              decoration: InputDecoration(
                labelText: 'Nivel de Urgencia',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.circle, color: _getColor(_colorSeleccionado)),
                filled: true,
              ),
              items: _colores.map((color) => DropdownMenuItem(
                value: color,
                child: Text(color, style: TextStyle(color: _getColor(color), fontWeight: FontWeight.bold)),
              )).toList(),
            ),
            const SizedBox(height: 15),

            // Selector de Zona
            DropdownButtonFormField<String>(
              initialValue: _ubicacionSeleccionada, // Usamos 'value'
              key: Key("zona_$_ubicacionSeleccionada"),
              onChanged: _formularioBloqueado ? null : (v) {
                setState(() => _ubicacionSeleccionada = v!);
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
                          // MODO EDICIÓN: Desbloqueamos
                          setState(() {
                            _formularioBloqueado = false;
                          });
                        } else {
                          // MODO GUARDAR: Enviamos datos
                          _guardarTodo();
                        }
                      },
                icon: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(_formularioBloqueado ? Icons.edit : Icons.save_as),
                label: Text(
                  _isLoading 
                      ? "Guardando..." 
                      : (_formularioBloqueado ? "Editar Consulta y Triaje" : "Guardar Información"),
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