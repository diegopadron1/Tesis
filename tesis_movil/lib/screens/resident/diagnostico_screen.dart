import 'package:flutter/material.dart';
import '../../services/diagnostico_service.dart';
import '../../services/enfermeria_service.dart'; 
import '../../models/medicamento.dart';          

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
  final _medicamentosCtrl = TextEditingController(); // Fármaco, Dosis y Frecuencia
  final _examenesCtrl = TextEditingController();
  final _conductaCtrl = TextEditingController();

  // --- SERVICIOS ---
  final DiagnosticoService _service = DiagnosticoService();
  final EnfermeriaService _enfermeriaService = EnfermeriaService();

  // --- ESTADO ---
  String _tipoDiagnostico = 'Presuntivo';
  bool _isLoading = false;
  bool _formularioBloqueado = false;

  // --- SELECCIÓN DE MEDICAMENTO ---
  int? _idMedicamentoSeleccionado; 
  Medicamento? _medicamentoSeleccionado; 

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.getDatosHoy(widget.cedulaPaciente);

      if (mounted && res['success'] && res['data'] != null) {
        final data = res['data'];
        bool encontroAlgo = false;

        if (data['diagnostico'] != null) {
          _descripcionCtrl.text = data['diagnostico']['descripcion'] ?? '';
          _observacionesCtrl.text = data['diagnostico']['observaciones'] ?? '';
          _tipoDiagnostico = data['diagnostico']['tipo'] ?? 'Presuntivo';
          _idDiagnosticoGuardado = data['diagnostico']['id_diagnostico'];
          encontroAlgo = true;
        }

        if (data['orden'] != null) {
          _indicacionesCtrl.text = data['orden']['indicaciones_inmediatas'] ?? '';
          _tratamientosCtrl.text = data['orden']['tratamientos_sugeridos'] ?? '';
          _medicamentosCtrl.text = data['orden']['requerimiento_medicamentos'] ?? '';
          _examenesCtrl.text = data['orden']['examenes_complementarios'] ?? '';
          _conductaCtrl.text = data['orden']['conducta_seguir'] ?? '';
          _idOrdenGuardada = data['orden']['id_orden'];
          _idMedicamentoSeleccionado = data['orden']['id_medicamento'];
          encontroAlgo = true;
        }

        if (encontroAlgo) setState(() => _formularioBloqueado = true);
      }
    } catch (e) {
      debugPrint("Error loading: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int? _idDiagnosticoGuardado;
  int? _idOrdenGuardada;

  void _procesarGuardado() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final Map<String, dynamic> datosEnviar = {
      'cedula_paciente': widget.cedulaPaciente,
      'descripcion': _descripcionCtrl.text.trim(),
      'tipo': _tipoDiagnostico,
      'observaciones': _observacionesCtrl.text.trim(),
      'id_medicamento': _idMedicamentoSeleccionado, 
      'indicaciones_inmediatas': _indicacionesCtrl.text.trim(),
      'tratamientos_sugeridos': _tratamientosCtrl.text.trim(),
      'requerimiento_medicamentos': _medicamentosCtrl.text.trim(), 
      'examenes_complementarios': _examenesCtrl.text.trim(),
      'conducta_seguir': _conductaCtrl.text.trim(),
    };

    Map<String, dynamic> result;
    if (_idDiagnosticoGuardado == null) {
      result = await _service.createDiagnostico(datosEnviar);
    } else {
      datosEnviar['id_orden'] = _idOrdenGuardada;
      result = await _service.updateDiagnostico(_idDiagnosticoGuardado!, datosEnviar);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red));

    if (result['success']) setState(() => _formularioBloqueado = true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading && _idDiagnosticoGuardado == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              key: ValueKey(_tipoDiagnostico),
              initialValue: _tipoDiagnostico,
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
            const SizedBox(height: 20),

            // --- BUSCADOR DE MEDICAMENTOS (AUTOCOMPLETE) ---
            const Text("Seleccionar Medicamento (Inventario)",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            
            Autocomplete<Medicamento>(
              displayStringForOption: (Medicamento option) => option.idMedicamento == -1 
                  ? option.nombre 
                  : "${option.nombre} (${option.concentracion})",
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) return const Iterable<Medicamento>.empty();
                
                final resultados = await _enfermeriaService.getListaMedicamentos(query: textEditingValue.text);
                
                if (resultados.isEmpty) {
                  return [
                    Medicamento(
                      idMedicamento: -1, 
                      nombre: "Sin existencias en farmacia", 
                      principioActivo: "",
                      concentracion: "", 
                      presentacion: "", 
                      cantidadDisponible: 0,
                      stockMinimo: 0, 
                    )
                  ];
                }
                return resultados;
              },
              onSelected: (Medicamento selection) {
                setState(() {
                  if (selection.idMedicamento == -1) {
                    _idMedicamentoSeleccionado = null;
                    _medicamentoSeleccionado = null;
                  } else {
                    _idMedicamentoSeleccionado = selection.idMedicamento;
                    _medicamentoSeleccionado = selection;
                  }
                });
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  enabled: !_formularioBloqueado,
                  decoration: const InputDecoration(
                    labelText: "Buscar fármaco en stock...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),

            // --- PANEL INFORMATIVO DE STOCK (SOLO SI SE SELECCIONA UNO VÁLIDO) ---
            if (_medicamentoSeleccionado != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Stock: ${_medicamentoSeleccionado!.cantidadDisponible} unidades (${_medicamentoSeleccionado!.presentacion})",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 15),

            TextFormField(
              controller: _medicamentosCtrl,
              enabled: !_formularioBloqueado,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Descripción del Medicamento y Dosis *",
                hintText: "Ej: Ampicilina 500mg, cada 8 horas",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Campo obligatorio para la orden' : null,
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _tratamientosCtrl,
              enabled: !_formularioBloqueado,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Tratamientos Sugeridos/Otros", border: OutlineInputBorder()),
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
              decoration: const InputDecoration(labelText: "Conducta a Seguir", border: OutlineInputBorder()),
            ),

            const SizedBox(height: 30),

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
                          _procesarGuardado();
                        }
                      },
                icon: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(_formularioBloqueado ? Icons.edit : Icons.save_as),
                label: Text(
                  _isLoading ? "Guardando..." : (_formularioBloqueado ? "Editar Diagnóstico" : "Emitir Diagnóstico y Órdenes"),
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _formularioBloqueado ? Colors.orange[800] : Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}