import 'package:flutter/material.dart';
import '../../services/historia_service.dart';
import '../../services/enfermeria_service.dart';
import '../../models/medicamento.dart'; 

class HistoriaClinicaScreen extends StatefulWidget {
  const HistoriaClinicaScreen({super.key});

  @override
  State<HistoriaClinicaScreen> createState() => _HistoriaClinicaScreenState();
}

class _HistoriaClinicaScreenState extends State<HistoriaClinicaScreen> {
  final _cedulaSearchCtrl = TextEditingController();
  final HistoriaService _service = HistoriaService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _pacienteData; 
  bool _notFound = false;
  int? _mostRecentCarpetaId;

  void _buscarPaciente() async {
    if (_cedulaSearchCtrl.text.isEmpty) return;
    
    setState(() { 
      _isLoading = true; 
      _notFound = false; 
      _pacienteData = null; 
      _mostRecentCarpetaId = null; 
    });
    
    try {
      final data = await _service.getHistoriaClinica(_cedulaSearchCtrl.text.trim());
      
      if (!mounted) return; 

      setState(() {
        if (data.isEmpty) {
          _notFound = true;
        } else {
          _pacienteData = data;
          final motivos = data['MotivoConsultas'] as List? ?? [];
          if (motivos.isNotEmpty) {
            _mostRecentCarpetaId = motivos.first['id_carpeta'];
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _guardarSeccion(String seccion, Map<String, dynamic> datos) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guardando...")));
    
    final datosConFirma = {
      ...datos,
      'id_usuario': '123456', 
      'atendido_por': 'Dr. Especialista' 
    };

    final res = await _service.guardarSeccion(_cedulaSearchCtrl.text, seccion, datosConFirma);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['message']),
      backgroundColor: res['success'] ? Colors.green : Colors.red,
    ));

    if (res['success']) _buscarPaciente(); 
  }

  Map<String, dynamic> _extraerData(List<String> keysPosibles, {bool dependeDeCarpeta = true}) {
    if (_pacienteData == null) return {};
    dynamic rawData;
    for (var key in keysPosibles) {
      if (_pacienteData!.containsKey(key) && _pacienteData![key] != null) {
        rawData = _pacienteData![key];
        break;
      }
    }
    if (rawData == null) return {};

    if (!dependeDeCarpeta) {
       if (rawData is List && rawData.isNotEmpty) return Map<String, dynamic>.from(rawData.first);
       if (rawData is Map) return Map<String, dynamic>.from(rawData);
       return {};
    }

    if (rawData is List && rawData.isNotEmpty) {
      if (_mostRecentCarpetaId == null) return {};
      try {
        final itemMatch = rawData.firstWhere(
          (element) => element['id_carpeta'] == _mostRecentCarpetaId,
          orElse: () => null
        );
        return itemMatch != null ? Map<String, dynamic>.from(itemMatch) : {};
      } catch (e) { return {}; }
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Actualizar Historial"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildBarraBusqueda(),
          if (_notFound) _buildMensajeError(),
          if (_pacienteData != null)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  _buildHeaderPaciente(),
                  if (_mostRecentCarpetaId != null) 
                    Center(child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Chip(
                        backgroundColor: Colors.indigo.withValues(alpha: 0.2),
                        label: Text("Carpeta de Visita: #$_mostRecentCarpetaId", 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent))
                      ),
                    )),
                  const Divider(height: 30, thickness: 2),
                  
                  _SeccionDatosPersonales(
                    data: _pacienteData!,
                    onSave: (d) => _guardarSeccion('datos_personales', d),
                  ),

                  _SeccionGenerica(
                    titulo: "Contacto de Emergencia",
                    icon: Icons.contact_phone,
                    data: _extraerData(['ContactoEmergencia', 'ContactoEmergencium'], dependeDeCarpeta: false), 
                    campos: const ['nombre_apellido', 'parentesco', 'cedula_contacto', 'telefono'],
                    seccionKey: 'contacto_emergencia', 
                    onSave: _guardarSeccion,
                  ),

                  _SeccionGenerica(
                    titulo: "Motivo de Consulta",
                    icon: Icons.chat_bubble_outline,
                    data: _extraerData(['MotivoConsulta', 'MotivoConsultas'], dependeDeCarpeta: true), 
                    campos: const ['motivo_consulta'], 
                    seccionKey: 'motivo',
                    onSave: _guardarSeccion,
                  ),

                  _SeccionGenerica(
                    titulo: "Diagnóstico",
                    icon: Icons.local_hospital,
                    data: _extraerData(['Diagnostico', 'Diagnosticos'], dependeDeCarpeta: true),
                    campos: const ['descripcion', 'tipo', 'observaciones'],
                    seccionKey: 'diagnostico',
                    onSave: _guardarSeccion,
                  ),

                  _SeccionGenerica(
                    titulo: "Examen Físico",
                    icon: Icons.accessibility_new,
                    data: _extraerData(['ExamenFisico', 'ExamenFisicos'], dependeDeCarpeta: true),
                    campos: const ['area', 'hallazgos'], 
                    seccionKey: 'fisico',
                    onSave: _guardarSeccion,
                  ),

                  _SeccionGenerica(
                    titulo: "Examen Funcional",
                    icon: Icons.directions_walk,
                    data: _extraerData(['ExamenFuncional', 'ExamenFuncionals'], dependeDeCarpeta: true),
                    campos: const ['sistema', 'hallazgos'], 
                    seccionKey: 'funcional',
                    onSave: _guardarSeccion,
                  ),

                  _SeccionGenerica(
                    titulo: "Antecedentes Personales",
                    icon: Icons.history,
                    data: _extraerData(['AntecedentesPersonales', 'AntecedentesPersonale'], dependeDeCarpeta: false), 
                    campos: const ['tipo', 'detalle'], 
                    seccionKey: 'ant_pers',
                    onSave: _guardarSeccion,
                  ),

                  _SeccionGenerica(
                    titulo: "Antecedentes Familiares",
                    icon: Icons.family_restroom,
                    data: _extraerData(['AntecedentesFamiliares', 'AntecedentesFamiliare'], dependeDeCarpeta: false), 
                    campos: const ['tipo_familiar', 'patologias', 'vivo_muerto'], 
                    seccionKey: 'ant_fam',
                    onSave: _guardarSeccion,
                  ),

                  _SeccionGenerica(
                    titulo: "Hábitos Psicobiológicos",
                    icon: Icons.smoking_rooms,
                    data: _extraerData(['HabitosPsicobiologicos', 'HabitosPsicobiologico'], dependeDeCarpeta: false), 
                    campos: const ['cafe', 'tabaco', 'alcohol', 'sueño'], 
                    seccionKey: 'ant_hab',
                    onSave: _guardarSeccion,
                  ),

                  _SeccionOrdenesMedicas(
                    ordenes: (_pacienteData!['OrdenesMedicas'] as List? ?? [])
                        .where((o) => o['id_carpeta'] == _mostRecentCarpetaId)
                        .toList(),
                    service: _service,
                    onUpdate: _buscarPaciente,
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarraBusqueda() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _cedulaSearchCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Cédula del Paciente", border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _isLoading ? null : _buscarPaciente,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
            child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("BUSCAR"),
          )
        ],
      ),
    );
  }

  Widget _buildMensajeError() => const Padding(padding: EdgeInsets.all(20), child: Text("Paciente no encontrado.", style: TextStyle(color: Colors.red)));

  Widget _buildHeaderPaciente() {
    final p = _pacienteData!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.indigo.withValues(alpha: 0.1), 
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(radius: 30, backgroundColor: Colors.indigo, child: Icon(Icons.person, color: Colors.white, size: 35)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${p['nombre_apellido'] ?? 'Sin Nombre'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.indigoAccent)),
                  Text("C.I: ${p['cedula']} • Sexo: ${p['sexo'] ?? 'No registrado'}"),
                  Text("Edad: ${_calcularEdad(p['fecha_nacimiento'])} años"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calcularEdad(String? fecha) {
    if (fecha == null) return "?";
    try {
      final nac = DateTime.parse(fecha);
      final hoy = DateTime.now();
      int edad = hoy.year - nac.year;
      if (hoy.month < nac.month || (hoy.month == nac.month && hoy.day < nac.day)) edad--;
      return edad.toString();
    } catch (e) { return "?"; }
  }
}

// --- SECCIÓN DATOS PERSONALES ACTUALIZADA CON SEXO ---
class _SeccionDatosPersonales extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onSave;
  const _SeccionDatosPersonales({required this.data, required this.onSave});
  @override
  State<_SeccionDatosPersonales> createState() => _SeccionDatosPersonalesState();
}

class _SeccionDatosPersonalesState extends State<_SeccionDatosPersonales> {
  late TextEditingController _nombreCtrl, _telefonoCtrl, _direccionCtrl, _estadoCivilCtrl, _religionCtrl, _fechaNacCtrl, _lugarNacCtrl;
  String? _sexoSeleccionado;
  bool _isEditing = false;
  final List<String> _opcionesSexo = ['Masculino', 'Femenino', 'Otro'];

  @override
  void initState() { super.initState(); _initCtrls(); }
  
  void _initCtrls() {
    _nombreCtrl = TextEditingController(text: widget.data['nombre_apellido']?.toString() ?? '');
    _telefonoCtrl = TextEditingController(text: widget.data['telefono']?.toString() ?? '');
    _direccionCtrl = TextEditingController(text: widget.data['direccion_actual']?.toString() ?? '');
    _estadoCivilCtrl = TextEditingController(text: widget.data['Estado_civil']?.toString() ?? '');
    _religionCtrl = TextEditingController(text: widget.data['Religion']?.toString() ?? '');
    _fechaNacCtrl = TextEditingController(text: widget.data['fecha_nacimiento']?.toString() ?? '');
    _lugarNacCtrl = TextEditingController(text: widget.data['lugar_nacimiento']?.toString() ?? '');
    
    // Validar que el sexo actual exista en las opciones, sino null
    final sexoActual = widget.data['sexo']?.toString();
    _sexoSeleccionado = _opcionesSexo.contains(sexoActual) ? sexoActual : null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        leading: const Icon(Icons.person_outline, color: Colors.indigo),
        title: const Text("Datos Personales", style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: IconButton(icon: Icon(_isEditing ? Icons.close : Icons.edit), onPressed: () => setState(() { if (_isEditing) _initCtrls(); _isEditing = !_isEditing; })),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _isEditing ? Column(children: [
              _buildField(_nombreCtrl, "Nombre Completo"),
              // Dropdown para Sexo
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DropdownButtonFormField<String>(
                  value: _sexoSeleccionado,
                  decoration: const InputDecoration(labelText: "Sexo", border: OutlineInputBorder(), filled: true, fillColor: Colors.black12),
                  items: _opcionesSexo.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _sexoSeleccionado = val),
                ),
              ),
              _buildField(_telefonoCtrl, "Teléfono"),
              _buildField(_fechaNacCtrl, "Fecha Nacimiento (AAAA-MM-DD)"),
              _buildField(_lugarNacCtrl, "Lugar de Nacimiento"),
              _buildField(_direccionCtrl, "Dirección"),
              _buildField(_estadoCivilCtrl, "Estado Civil"),
              _buildField(_religionCtrl, "Religión"),
              ElevatedButton(onPressed: () {
                widget.onSave({
                  'nombre_apellido': _nombreCtrl.text, 
                  'sexo': _sexoSeleccionado,
                  'telefono': _telefonoCtrl.text, 
                  'fecha_nacimiento': _fechaNacCtrl.text, 
                  'lugar_nacimiento': _lugarNacCtrl.text, 
                  'direccion_actual': _direccionCtrl.text, 
                  'Estado_civil': _estadoCivilCtrl.text, 
                  'Religion': _religionCtrl.text
                });
                setState(() => _isEditing = false);
              }, child: const Text("Actualizar"))
            ]) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _info("Nombre", _nombreCtrl.text), 
              _info("Sexo", _sexoSeleccionado ?? 'No registrado'),
              _info("F. Nacimiento", _fechaNacCtrl.text), 
              _info("Lugar", _lugarNacCtrl.text), 
              _info("Teléfono", _telefonoCtrl.text), 
              _info("Dirección", _direccionCtrl.text), 
              _info("Estado Civil", _estadoCivilCtrl.text), 
              _info("Religión", _religionCtrl.text),
            ]),
          )
        ],
      ),
    );
  }
  Widget _buildField(TextEditingController ctrl, String label) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: ctrl, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), filled: true, fillColor: Colors.black12)));
  Widget _info(String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("$l: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent)), Expanded(child: Text(v))]));
}

// --- RESTO DE SECCIONES (GENÉRICA Y ÓRDENES) ---
class _SeccionGenerica extends StatefulWidget {
  final String titulo;
  final IconData icon;
  final Map<String, dynamic> data;
  final List<String> campos;
  final String seccionKey;
  final Function(String, Map<String, dynamic>) onSave;
  const _SeccionGenerica({required this.titulo, required this.icon, required this.data, required this.campos, required this.seccionKey, required this.onSave});
  @override
  State<_SeccionGenerica> createState() => _SeccionGenericaState();
}

class _SeccionGenericaState extends State<_SeccionGenerica> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isEditing = false;
  @override
  void initState() { super.initState(); _initControllers(); }
  void _initControllers() {
    for (var campo in widget.campos) {
      _controllers[campo] = TextEditingController(text: widget.data[campo]?.toString() ?? '');
    }
  }
  @override
  void didUpdateWidget(covariant _SeccionGenerica oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data && !_isEditing) _initControllers();
  }
  @override
  Widget build(BuildContext context) {
    final tieneDatos = widget.data.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(widget.icon, color: tieneDatos ? Colors.indigo : Colors.grey),
        title: Text(widget.titulo, style: TextStyle(fontWeight: FontWeight.bold, color: tieneDatos ? Colors.indigoAccent : Colors.grey[600])),
        trailing: IconButton(
          icon: Icon(_isEditing ? Icons.close : (tieneDatos ? Icons.edit : Icons.add_circle_outline)),
          color: _isEditing ? Colors.red : (tieneDatos ? Colors.indigo : Colors.green),
          onPressed: () => setState(() { if (_isEditing) _initControllers(); _isEditing = !_isEditing; }),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _isEditing ? _buildFormulario() : _buildVistaLectura(tieneDatos),
          )
        ],
      ),
    );
  }
  Widget _buildVistaLectura(bool tieneDatos) {
    if (!tieneDatos) return const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("Pendiente por registrar.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.campos.map((campo) {
        final valor = widget.data[campo]?.toString();
        if (valor == null || valor.isEmpty) return const SizedBox.shrink(); 
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("${campo.replaceAll('_', ' ').toUpperCase()}: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigoAccent)),
            Expanded(child: Text(valor)),
          ]),
        );
      }).toList(),
    );
  }
  Widget _buildFormulario() {
    return Column(children: [
      const Divider(),
      ...widget.campos.map((campo) => Padding(
        padding: const EdgeInsets.only(bottom: 12), 
        child: TextField(
          controller: _controllers[campo], 
          decoration: InputDecoration(
            labelText: campo.replaceAll('_', ' ').toUpperCase(), 
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.black12, 
          ), 
          maxLines: campo.contains('hallazgos') || campo.contains('detalle') || campo.contains('motivo') ? 3 : 1
        )
      )),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text("Cancelar")),
        ElevatedButton(onPressed: () {
          final Map<String, dynamic> datosEnv = {};
          _controllers.forEach((k, v) => datosEnv[k] = v.text);
          widget.onSave(widget.seccionKey, datosEnv);
          setState(() => _isEditing = false);
        }, child: const Text("Guardar")),
      ])
    ]);
  }
}

class _SeccionOrdenesMedicas extends StatefulWidget {
  final List<dynamic> ordenes;
  final HistoriaService service;
  final VoidCallback onUpdate;
  const _SeccionOrdenesMedicas({required this.ordenes, required this.service, required this.onUpdate});
  @override
  State<_SeccionOrdenesMedicas> createState() => _SeccionOrdenesMedicasState();
}

class _SeccionOrdenesMedicasState extends State<_SeccionOrdenesMedicas> {
  final EnfermeriaService _enfService = EnfermeriaService();

  void _editarOrden(BuildContext context, Map<String, dynamic> orden) {
    final indicacionesCtrl = TextEditingController(text: orden['indicaciones_inmediatas']);
    final posologiaCtrl = TextEditingController(text: orden['requerimiento_medicamentos']);
    
    int? selectedMedId = orden['id_medicamento'];
    Medicamento? selectedMedObj;

    showDialog(
      context: context, 
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text("Editar Prescripción"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                Autocomplete<Medicamento>(
                  displayStringForOption: (option) => option.idMedicamento == -1 
                      ? option.nombre 
                      : "${option.nombre} (${option.concentracion})",
                  optionsBuilder: (textValue) async {
                    if (textValue.text.isEmpty) return const Iterable<Medicamento>.empty();
                    final resultados = await _enfService.getListaMedicamentos(query: textValue.text);
                    if (resultados.isEmpty) {
                      return [Medicamento(
                        idMedicamento: -1, 
                        nombre: "Sin existencias en farmacia", 
                        principioActivo: "", 
                        concentracion: "", 
                        presentacion: "", 
                        cantidadDisponible: 0, 
                        stockMinimo: 0
                      )];
                    }
                    return resultados;
                  },
                  onSelected: (selection) {
                    setDialogState(() {
                      if (selection.idMedicamento == -1) {
                        selectedMedId = null;
                        selectedMedObj = null;
                      } else {
                        selectedMedId = selection.idMedicamento;
                        selectedMedObj = selection;
                      }
                    });
                  },
                  fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: textController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: "Buscar en Inventario", 
                        border: OutlineInputBorder(), 
                        prefixIcon: Icon(Icons.search)
                      ),
                    );
                  },
                ),
                
                if (selectedMedObj != null) 
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Stock actual: ${selectedMedObj!.cantidadDisponible} und. (${selectedMedObj!.presentacion})", 
                      style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)
                    ),
                  ),

                const SizedBox(height: 15),
                TextField(
                  controller: posologiaCtrl, 
                  maxLines: 2, 
                  decoration: const InputDecoration(
                    labelText: "Fármaco y Dosis *", 
                    hintText: "Ej: Ibuprofeno 400mg...", 
                    border: OutlineInputBorder()
                  )
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: indicacionesCtrl, 
                  maxLines: 2, 
                  decoration: const InputDecoration(
                    labelText: "Indicaciones", 
                    border: OutlineInputBorder()
                  )
                ),
              ]
            )
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo), 
              onPressed: () async {
                if (posologiaCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                final res = await widget.service.editarOrden(orden['id_orden'], {
                  'id_medicamento': selectedMedId, 
                  'requerimiento_medicamentos': posologiaCtrl.text, 
                  'indicaciones_inmediatas': indicacionesCtrl.text
                });
                if (res['success']) widget.onUpdate();
              }, 
              child: const Text("Actualizar", style: TextStyle(color: Colors.white))
            )
          ],
        );
      })
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.assignment, color: Colors.indigo),
        title: const Text("Órdenes de esta Visita", style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          if (widget.ordenes.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text("Sin órdenes.")),
          ...widget.ordenes.map((orden) {
            final String estatus = orden['estatus'] ?? 'PENDIENTE';
            final bool esPendiente = estatus == 'PENDIENTE';
            final bool esCancelada = estatus == 'CANCELADA' || estatus == 'NO_REALIZADA';
            final bool esRealizada = estatus == 'REALIZADA' || estatus == 'COMPLETADA';

            final nombreFarma = (orden['medicamento']?['nombre'] ?? 'Suministro Externo').toString().toUpperCase();

            Color bgColor = Colors.grey.withValues(alpha: 0.1);
            Color accentColor = Colors.grey;

            if (esPendiente) {
              bgColor = Colors.orange.withValues(alpha: 0.1);
              accentColor = Colors.orangeAccent;
            } else if (esRealizada) {
              bgColor = Colors.green.withValues(alpha: 0.1);
              accentColor = Colors.green;
            } else if (esCancelada) {
              bgColor = Colors.red.withValues(alpha: 0.1);
              accentColor = Colors.redAccent;
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor, 
                borderRadius: BorderRadius.circular(10), 
                border: Border.all(color: accentColor.withValues(alpha: 0.5)),
              ),
              child: ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(nombreFarma, style: TextStyle(fontWeight: FontWeight.bold, color: accentColor))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(4)),
                      child: Text(estatus, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  RichText(text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 13), children: [const TextSpan(text: "Prescripción: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)), TextSpan(text: "${orden['requerimiento_medicamentos']}")])),
                  Text("Indicaciones: ${orden['indicaciones_inmediatas'] ?? 'Ninguna'}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  if (orden['observaciones_cumplimiento'] != null && orden['observaciones_cumplimiento'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text("Nota Enfermería: ${orden['observaciones_cumplimiento']}", style: const TextStyle(fontSize: 12, color: Colors.brown, fontStyle: FontStyle.italic)),
                    ),
                ]),
                trailing: esPendiente 
                  ? IconButton(icon: const Icon(Icons.edit_note, color: Colors.indigoAccent, size: 30), onPressed: () => _editarOrden(context, orden)) 
                  : Icon(esRealizada ? Icons.check_circle : Icons.cancel, color: accentColor),
              ),
            );
          }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}