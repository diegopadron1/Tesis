import 'package:flutter/material.dart';
import '../../services/diagnostico_service.dart';
import '../../services/enfermeria_service.dart'; 
import '../../models/medicamento.dart';          

class DiagnosticoScreen extends StatefulWidget {
  final String cedulaPaciente;
  final bool readOnly; 

  const DiagnosticoScreen({
    super.key, 
    required this.cedulaPaciente, 
    this.readOnly = false 
  });

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
  
  // Variable para capturar el controlador del Autocomplete y poder limpiarlo
  TextEditingController? _autocompleteController;

  // --- SERVICIOS ---
  final DiagnosticoService _service = DiagnosticoService();
  final EnfermeriaService _enfermeriaService = EnfermeriaService();

  // --- ESTADO ---
  String _tipoDiagnostico = 'Presuntivo';
  bool _isLoading = false;
  bool _formularioBloqueado = false;

  // --- MULTI-SELECCIÓN DE MEDICAMENTOS ---
  final List<Medicamento> _medicamentosSeleccionados = [];
  int? _idOrdenGuardada;
  int? _idDiagnosticoGuardado;

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
          // Nota: Aquí se podrían cargar los medicamentos previos si el backend devolviera la lista.
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

  void _agregarMedicamento(Medicamento med) {
    // Evitar duplicados
    if (_medicamentosSeleccionados.any((m) => m.idMedicamento == med.idMedicamento)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este medicamento ya está en la lista"), duration: Duration(milliseconds: 1500)),
      );
      _autocompleteController?.clear();
      return;
    }

    setState(() {
      _medicamentosSeleccionados.add(med);
      
      // Concatenar texto en el campo de indicaciones para facilitar al médico
      String detalle = "${med.nombre} ${med.concentracion ?? ''} (${med.presentacion ?? ''})";
      if (_medicamentosCtrl.text.isEmpty) {
        _medicamentosCtrl.text = "- $detalle: ";
      } else {
        _medicamentosCtrl.text = "${_medicamentosCtrl.text}\n- $detalle: ";
      }
    });
    
    // Limpiamos el buscador usando la referencia capturada
    _autocompleteController?.clear();
  }

  void _removerMedicamento(Medicamento med) {
    setState(() {
      _medicamentosSeleccionados.remove(med);
    });
  }

  void _procesarGuardado() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Lógica temporal: enviamos el ID del primero para temas de stock en backend
    int? idPrincipal = _medicamentosSeleccionados.isNotEmpty 
        ? _medicamentosSeleccionados.first.idMedicamento 
        : null;

    final Map<String, dynamic> datosEnviar = {
      'cedula_paciente': widget.cedulaPaciente,
      'descripcion': _descripcionCtrl.text.trim(),
      'tipo': _tipoDiagnostico,
      'observaciones': _observacionesCtrl.text.trim(),
      'id_medicamento': idPrincipal, 
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

    final bool camposDeshabilitados = _formularioBloqueado || widget.readOnly;

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
              enabled: !camposDeshabilitados, 
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Diagnóstico Principal *", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              key: ValueKey(_tipoDiagnostico),
              initialValue: _tipoDiagnostico,
              onChanged: camposDeshabilitados ? null : (v) => setState(() => _tipoDiagnostico = v!), 
              items: ['Presuntivo', 'Definitivo'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              decoration: const InputDecoration(labelText: "Tipo", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _observacionesCtrl,
              enabled: !camposDeshabilitados, 
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
              enabled: !camposDeshabilitados, 
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Indicaciones Inmediatas", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            // --- SECCIÓN DE MEDICAMENTOS MULTI-SELECT ---
            const Text("Selección de Medicamentos (Inventario)",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),

            // 1. CHIPS DE MEDICAMENTOS SELECCIONADOS
            if (_medicamentosSeleccionados.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2))
                ),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _medicamentosSeleccionados.map((med) {
                    
                    // --- CORRECCIÓN DE NULL SAFETY PARA EVITAR CRASH ---
                    String inicialPresentacion = 'M';
                    if (med.presentacion != null && med.presentacion!.isNotEmpty) {
                      inicialPresentacion = med.presentacion![0].toUpperCase();
                    }
                    // --------------------------------------------------

                    return InputChip(
                      label: Text("${med.nombre} ${med.concentracion ?? ''}", 
                          style: const TextStyle(fontSize: 13)),
                      avatar: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(inicialPresentacion, 
                                    style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                      backgroundColor: Colors.white,
                      elevation: 1,
                      shadowColor: Colors.grey[200],
                      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                      onDeleted: camposDeshabilitados ? null : () => _removerMedicamento(med),
                    );
                  }).toList(),
                ),
              ),
            
            // 2. BUSCADOR CON DETALLES (CORREGIDO PARA EVITAR ERROR DE SETSTATE)
            Autocomplete<Medicamento>(
              // displayStringForOption vacio para limpiar visualmente al seleccionar
              displayStringForOption: (Medicamento option) => '',
              
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty || camposDeshabilitados) return const Iterable<Medicamento>.empty();
                
                final resultados = await _enfermeriaService.getListaMedicamentos(query: textEditingValue.text);
                
                if (resultados.isEmpty) {
                  return [Medicamento(idMedicamento: -1, nombre: "No encontrado", principioActivo: "", concentracion: "", presentacion: "", cantidadDisponible: 0, stockMinimo: 0)];
                }
                // Filtrar los que ya están seleccionados
                return resultados.where((m) => !_medicamentosSeleccionados.any((s) => s.idMedicamento == m.idMedicamento));
              },
              onSelected: (Medicamento selection) {
                if (selection.idMedicamento != -1) {
                  _agregarMedicamento(selection);
                }
              },
              fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                // CORRECCIÓN: Guardamos referencia sin modificar el estado durante el build
                _autocompleteController = textController;
                
                return TextFormField(
                  controller: textController,
                  focusNode: focusNode,
                  enabled: !camposDeshabilitados, 
                  decoration: const InputDecoration(
                    labelText: "Buscar por nombre o principio activo...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    hintText: "Ej: Paracetamol..."
                  ),
                );
              },
              // PERSONALIZACIÓN DE LA LISTA DESPLEGABLE
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 250, 
                        maxWidth: MediaQuery.of(context).size.width - 40 
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final Medicamento option = options.elementAt(index);
                          
                          if (option.idMedicamento == -1) {
                            return ListTile(
                              title: Text(option.nombre, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                            );
                          }

                          return ListTile(
                            title: Text(
                              "${option.nombre} ${option.concentracion ?? ''}",
                              style: const TextStyle(fontWeight: FontWeight.bold)
                            ),
                            subtitle: Text(
                              "${option.presentacion ?? 'N/A'} • ${option.principioActivo ?? ''}\nStock: ${option.cantidadDisponible}",
                              style: const TextStyle(fontSize: 12)
                            ),
                            trailing: const Icon(Icons.add_circle, color: Colors.green),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: _medicamentosCtrl,
              enabled: !camposDeshabilitados, 
              maxLines: 4, 
              decoration: const InputDecoration(
                labelText: "Indicaciones de Medicamentos y Dosis *",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _tratamientosCtrl,
              enabled: !camposDeshabilitados, 
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Tratamientos Sugeridos/Otros", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _examenesCtrl,
              enabled: !camposDeshabilitados, 
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Exámenes Complementarios", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _conductaCtrl,
              enabled: !camposDeshabilitados, 
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Conducta a Seguir", border: OutlineInputBorder()),
            ),

            const SizedBox(height: 30),

            // --- BOTÓN ---
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