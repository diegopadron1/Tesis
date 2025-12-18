import 'package:flutter/material.dart';
import '../../services/diagnostico_service.dart';

class DiagnosticoScreen extends StatefulWidget {
  final String cedulaPaciente; 

  const DiagnosticoScreen({super.key, required this.cedulaPaciente});

  @override
  State<DiagnosticoScreen> createState() => _DiagnosticoScreenState();
}

class _DiagnosticoScreenState extends State<DiagnosticoScreen> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  
  // --- CONTROLADORES ---
  final _descripcionCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  final _indicacionesCtrl = TextEditingController();
  final _tratamientosCtrl = TextEditingController(); 
  final _medicamentosCtrl = TextEditingController();
  final _examenesCtrl = TextEditingController();    
  final _conductaCtrl = TextEditingController();    

  String _tipoDiagnostico = 'Presuntivo';
  final DiagnosticoService _service = DiagnosticoService();
  
  bool _isLoading = false;
  bool _formularioBloqueado = false; // Control de bloqueo
  
  // --- IDS PARA CONTROLAR EDICIÓN ---
  int? _idDiagnosticoGuardado;
  int? _idOrdenGuardada;

  @override
  bool get wantKeepAlive => true; // Mantener vivo

  void _procesarGuardado() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    Map<String, dynamic> result;

    // Datos comunes a enviar
    final Map<String, dynamic> datosEnviar = {
      'cedula_paciente': widget.cedulaPaciente,
      'descripcion': _descripcionCtrl.text.trim(),
      'tipo': _tipoDiagnostico,
      'observaciones': _observacionesCtrl.text.trim(),
      // Órdenes médicas
      'indicaciones_inmediatas': _indicacionesCtrl.text.trim(),
      'tratamientos_sugeridos': _tratamientosCtrl.text.trim(),
      'requerimiento_medicamentos': _medicamentosCtrl.text.trim(),
      'examenes_complementarios': _examenesCtrl.text.trim(),
      'conducta_seguir': _conductaCtrl.text.trim(),
    };

    // --- LÓGICA CREAR O ACTUALIZAR ---
    if (_idDiagnosticoGuardado == null) {
      // CREAR
      result = await _service.createDiagnostico(datosEnviar);
    } else {
      // ACTUALIZAR (Enviamos también el id_orden para actualizarla)
      datosEnviar['id_orden'] = _idOrdenGuardada; 
      result = await _service.updateDiagnostico(_idDiagnosticoGuardado!, datosEnviar);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']), 
        backgroundColor: result['success'] ? Colors.green : Colors.red
      )
    );
    
    if (result['success']) {
       // --- CAPTURAR IDs ---
       // Tu backend devuelve: { diagnostico: {...}, orden: {...} } al crear
       // Y devuelve: { data: { diagnostico: {...}, orden: {...} } } al actualizar
       
       var data = result['data'] ?? result; // Ajuste por si la estructura varía levemente
       
       // Capturar ID Diagnóstico
       if (_idDiagnosticoGuardado == null) {
          if (data['diagnostico'] != null) {
             _idDiagnosticoGuardado = data['diagnostico']['id_diagnostico'];
             debugPrint("✅ ID Diagnóstico: $_idDiagnosticoGuardado");
          }
       }

       // Capturar ID Orden
       if (_idOrdenGuardada == null) {
          if (data['orden'] != null) {
             _idOrdenGuardada = data['orden']['id_orden'];
             debugPrint("✅ ID Orden: $_idOrdenGuardada");
          }
       }

       // Bloquear formulario
       setState(() {
         _formularioBloqueado = true;
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para KeepAlive
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
              enabled: !_formularioBloqueado,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Diagnóstico Principal *", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 15),
            
            DropdownButtonFormField<String>(
              initialValue: _tipoDiagnostico, 
              // Usamos null en onChanged para deshabilitar si está bloqueado
              onChanged: _formularioBloqueado ? null : (v) => setState(() => _tipoDiagnostico = v!),
              items: ['Presuntivo', 'Definitivo'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              decoration: const InputDecoration(labelText: "Tipo", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _observacionesCtrl,
              enabled: !_formularioBloqueado,
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
              enabled: !_formularioBloqueado,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Indicaciones Inmediatas", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextFormField( 
              controller: _tratamientosCtrl,
              enabled: !_formularioBloqueado,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Tratamientos Sugeridos", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _medicamentosCtrl,
              enabled: !_formularioBloqueado,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Requerimiento de Medicamentos", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextFormField( 
              controller: _examenesCtrl,
              enabled: !_formularioBloqueado,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Exámenes Complementarios", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextFormField( 
              controller: _conductaCtrl,
              enabled: !_formularioBloqueado,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Conducta a Seguir (Ej: Hospitalizar)", border: OutlineInputBorder()),
            ),
            
            const SizedBox(height: 30),

            // --- BOTÓN DINÁMICO ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading 
                    ? null 
                    : () {
                        if (_formularioBloqueado) {
                          setState(() => _formularioBloqueado = false); // Desbloquear
                        } else {
                          _procesarGuardado(); // Guardar
                        }
                      },
                icon: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(_formularioBloqueado ? Icons.edit : Icons.save_as),
                label: Text(
                  _isLoading 
                      ? "Guardando..." 
                      : (_formularioBloqueado ? "Editar Diagnóstico" : "Emitir Diagnóstico y Órdenes"),
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