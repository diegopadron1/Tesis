import 'package:flutter/material.dart';
import '../../services/historia_service.dart';

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

  void _buscarPaciente() async {
    if (_cedulaSearchCtrl.text.isEmpty) return;
    
    setState(() { _isLoading = true; _notFound = false; _pacienteData = null; });
    
    try {
      final data = await _service.getHistoriaClinica(_cedulaSearchCtrl.text.trim());
      
      if (!mounted) return; 

      setState(() {
        if (data.isEmpty) {
          _notFound = true;
        } else {
          _pacienteData = data;
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

    if (res['success']) {
      _buscarPaciente(); 
    }
  }

  Map<String, dynamic> _extraerDataReciente(List<String> keysPosibles) {
    if (_pacienteData == null) return {};

    dynamic rawData;
    for (var key in keysPosibles) {
      if (_pacienteData!.containsKey(key) && _pacienteData![key] != null) {
        rawData = _pacienteData![key];
        break;
      }
    }

    if (rawData == null) return {};

    if (rawData is List) {
      if (rawData.isEmpty) return {};
      return Map<String, dynamic>.from(rawData.first);
    }

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial Clínico Integral"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cedulaSearchCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Buscar por Cédula",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: Icon(Icons.person_search, color: Colors.indigo)
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _buscarPaciente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("BUSCAR"),
                )
              ],
            ),
          ),
          
          if (_notFound)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Paciente no encontrado. Intente con otra cédula.", style: TextStyle(color: Colors.red, fontSize: 16)),
            ),

          if (_pacienteData != null)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  _buildHeaderPaciente(),
                  const Divider(height: 30, thickness: 2),
                  
                  _SeccionDatosPersonales(
                    data: _pacienteData!,
                    onSave: (d) => _guardarSeccion('datos_personales', d),
                  ),

                  _SeccionGenerica(
                    titulo: "Contacto de Emergencia",
                    icon: Icons.contact_phone,
                    data: _extraerDataReciente(['ContactoEmergencia', 'ContactoEmergencium', 'ContactoEmergencias']), 
                    campos: const ['nombre_apellido', 'parentesco', 'cedula_contacto', 'telefono'],
                    seccionKey: 'contacto_emergencia', 
                    onSave: _guardarSeccion,
                  ),

                  _SeccionGenerica(
                    titulo: "Motivo de Consulta",
                    icon: Icons.chat_bubble_outline,
                    data: _extraerDataReciente(['MotivoConsulta', 'MotivoConsultas', 'MotivoConsultum']), 
                    campos: const ['motivo_consulta'], 
                    seccionKey: 'motivo',
                    onSave: _guardarSeccion,
                  ),

                  _SeccionGenerica(
                    titulo: "Diagnóstico",
                    icon: Icons.local_hospital,
                    data: _extraerDataReciente(['Diagnostico', 'Diagnosticos']),
                    campos: const ['descripcion', 'tipo', 'observaciones'],
                    seccionKey: 'diagnostico',
                    onSave: _guardarSeccion,
                  ),

                  _SeccionGenerica(
                    titulo: "Examen Físico",
                    icon: Icons.accessibility_new,
                    data: _extraerDataReciente(['ExamenFisico', 'ExamenFisicos']),
                    campos: const ['area', 'hallazgos'], 
                    seccionKey: 'fisico',
                    onSave: _guardarSeccion,
                  ),

                  _SeccionGenerica(
                    titulo: "Examen Funcional",
                    icon: Icons.directions_walk,
                    data: _extraerDataReciente(['ExamenFuncional', 'ExamenFuncionals', 'ExamenFuncionales']),
                    campos: const ['sistema', 'hallazgos'], 
                    seccionKey: 'funcional',
                    onSave: _guardarSeccion,
                  ),

                  _SeccionGenerica(
                    titulo: "Antecedentes Personales",
                    icon: Icons.history,
                    data: _extraerDataReciente(['AntecedentesPersonales', 'AntecedentesPersonale']), 
                    campos: const ['tipo', 'detalle'], 
                    seccionKey: 'ant_pers',
                    onSave: _guardarSeccion,
                  ),

                   _SeccionGenerica(
                    titulo: "Antecedentes Familiares",
                    icon: Icons.family_restroom,
                    data: _extraerDataReciente(['AntecedentesFamiliares', 'AntecedentesFamiliare']), 
                    campos: const ['tipo_familiar', 'vivo_muerto', 'edad', 'patologias'], 
                    seccionKey: 'ant_fam',
                    onSave: _guardarSeccion,
                  ),

                  _SeccionGenerica(
                    titulo: "Hábitos Psicobiológicos",
                    icon: Icons.smoking_rooms,
                    data: _extraerDataReciente(['HabitosPsicobiologicos', 'HabitosPsicobiologico']), 
                    campos: const ['cafe', 'tabaco', 'alcohol', 'drogas_ilicitas', 'ocupacion', 'sueño', 'vivienda'], 
                    seccionKey: 'ant_hab',
                    onSave: _guardarSeccion,
                  ),

                  _SeccionOrdenesMedicas(
                    ordenes: _pacienteData!['OrdenesMedicas'] ?? [],
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

  Widget _buildHeaderPaciente() {
    final p = _pacienteData!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.indigo[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.indigo,
              child: Icon(Icons.person, color: Colors.white, size: 35),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${p['nombre_apellido'] ?? 'Sin Nombre'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.indigo)),
                  const SizedBox(height: 5),
                  Text("C.I: ${p['cedula']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text("Edad: ${_calcularEdad(p['fecha_nacimiento'])} años", style: const TextStyle(color: Colors.grey)),
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
      if (hoy.month < nac.month || (hoy.month == nac.month && hoy.day < nac.day)) {
        edad--;
      }
      return edad.toString();
    } catch (e) {
      return "?";
    }
  }
}

// --- WIDGET GENÉRICO INTELIGENTE ---
class _SeccionGenerica extends StatefulWidget {
  final String titulo;
  final IconData icon;
  final Map<String, dynamic> data;
  final List<String> campos;
  final String seccionKey;
  final Function(String, Map<String, dynamic>) onSave;

  const _SeccionGenerica({
    required this.titulo, required this.icon, required this.data, required this.campos, required this.seccionKey, required this.onSave
  });

  @override
  State<_SeccionGenerica> createState() => _SeccionGenericaState();
}

class _SeccionGenericaState extends State<_SeccionGenerica> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (var campo in widget.campos) {
      _controllers[campo] = TextEditingController(text: widget.data[campo]?.toString() ?? '');
    }
  }

  @override
  void didUpdateWidget(covariant _SeccionGenerica oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data && !_isEditing) {
       _initControllers();
    }
  }

  bool _hasData() {
    for (var campo in widget.campos) {
      if (widget.data[campo] != null && widget.data[campo].toString().isNotEmpty) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tieneDatos = _hasData();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(widget.icon, color: tieneDatos ? Colors.indigo : Colors.grey),
        title: Text(widget.titulo, style: TextStyle(fontWeight: FontWeight.bold, color: tieneDatos ? Colors.black : Colors.grey[600])),
        trailing: IconButton(
          icon: Icon(_isEditing ? Icons.close : (tieneDatos ? Icons.edit : Icons.add_circle_outline)),
          color: _isEditing ? Colors.red : (tieneDatos ? Colors.indigo : Colors.green),
          tooltip: _isEditing ? "Cancelar" : (tieneDatos ? "Editar" : "Agregar"),
          onPressed: () {
            setState(() {
              if (_isEditing) _initControllers(); 
              _isEditing = !_isEditing;
            });
          },
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
    if (!tieneDatos) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text("No hay información registrada en esta sección.\nPresione + para agregar.", 
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.campos.map((campo) {
        final valor = widget.data[campo]?.toString();
        if (valor == null || valor.isEmpty) return const SizedBox.shrink(); 

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${campo.replaceAll('_', ' ').toUpperCase()}: ",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo),
              ),
              Expanded(child: Text(valor, style: const TextStyle(fontSize: 14))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormulario() {
    return Column(
      children: [
        const Divider(),
        ...widget.campos.map((campo) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _controllers[campo],
            decoration: InputDecoration(
              labelText: campo.replaceAll('_', ' ').toUpperCase(),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50]
            ),
            maxLines: campo.contains('hallazgos') || campo.contains('detalle') || campo.contains('motivo') ? 3 : 1,
          ),
        )),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() { _isEditing = false; _initControllers(); }),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () {
                final Map<String, dynamic> datosEnviar = {};
                _controllers.forEach((key, ctrl) {
                  datosEnviar[key] = ctrl.text;
                });
                widget.onSave(widget.seccionKey, datosEnviar);
                setState(() => _isEditing = false); 
              },
              icon: const Icon(Icons.save),
              label: const Text("Guardar"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            )
          ],
        )
      ],
    );
  }
}

class _SeccionDatosPersonales extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onSave;

  const _SeccionDatosPersonales({required this.data, required this.onSave});

  @override
  State<_SeccionDatosPersonales> createState() => _SeccionDatosPersonalesState();
}

class _SeccionDatosPersonalesState extends State<_SeccionDatosPersonales> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _estadoCivilCtrl; 
  late TextEditingController _religionCtrl;    
  late TextEditingController _fechaNacCtrl;
  late TextEditingController _lugarNacCtrl;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initCtrls();
  }

  void _initCtrls() {
    _nombreCtrl = TextEditingController(text: widget.data['nombre_apellido']?.toString() ?? '');
    _telefonoCtrl = TextEditingController(text: widget.data['telefono']?.toString() ?? '');
    _direccionCtrl = TextEditingController(text: widget.data['direccion_actual']?.toString() ?? '');
    _estadoCivilCtrl = TextEditingController(text: widget.data['Estado_civil']?.toString() ?? '');
    _religionCtrl = TextEditingController(text: widget.data['Religion']?.toString() ?? '');
    _fechaNacCtrl = TextEditingController(text: widget.data['fecha_nacimiento']?.toString() ?? '');
    _lugarNacCtrl = TextEditingController(text: widget.data['lugar_nacimiento']?.toString() ?? '');
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_fechaNacCtrl.text) ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      String formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _fechaNacCtrl.text = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.person_outline, color: Colors.indigo),
        title: const Text("Datos Personales", style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: IconButton(
          icon: Icon(_isEditing ? Icons.close : Icons.edit),
          color: _isEditing ? Colors.red : Colors.indigo,
          onPressed: () => setState(() {
            if (_isEditing) _initCtrls();
            _isEditing = !_isEditing;
          }),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _isEditing 
              ? Column(
                  children: [
                    _buildTextField(_nombreCtrl, "Nombre y Apellido"),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_telefonoCtrl, "Teléfono", isNumber: true)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextField(
                              controller: _fechaNacCtrl,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: "Fecha Nacimiento", 
                                border: OutlineInputBorder(), 
                                isDense: true,
                                suffixIcon: Icon(Icons.calendar_today, size: 18)
                              ),
                              onTap: () => _selectDate(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(_lugarNacCtrl, "Lugar de Nacimiento"),
                    _buildTextField(_direccionCtrl, "Dirección Actual"),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_estadoCivilCtrl, "Estado Civil")),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTextField(_religionCtrl, "Religión")),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: () {
                          widget.onSave({ 
                           'nombre_apellido': _nombreCtrl.text, 
                           'telefono': _telefonoCtrl.text,
                           'fecha_nacimiento': _fechaNacCtrl.text,
                           'lugar_nacimiento': _lugarNacCtrl.text,
                           'direccion_actual': _direccionCtrl.text,
                           'Estado_civil': _estadoCivilCtrl.text,
                           'Religion': _religionCtrl.text,
                          });
                          setState(() => _isEditing = false);
                       },
                      icon: const Icon(Icons.save),
                      label: const Text("Actualizar Datos"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    )
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("Nombre", _nombreCtrl.text),
                    _buildInfoRow("F. Nacimiento", _fechaNacCtrl.text),
                    _buildInfoRow("Lugar Nac.", _lugarNacCtrl.text),
                    _buildInfoRow("Teléfono", _telefonoCtrl.text),
                    _buildInfoRow("Dirección", _direccionCtrl.text),
                    _buildInfoRow("Estado Civil", _estadoCivilCtrl.text),
                    _buildInfoRow("Religión", _religionCtrl.text),
                  ],
                ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value == 'null' || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(width: 5),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// --- TAB: ÓRDENES MÉDICAS (DISEÑO MEJORADO) ---
class _SeccionOrdenesMedicas extends StatelessWidget {
  final List<dynamic> ordenes;
  final HistoriaService service;
  final VoidCallback onUpdate;

  const _SeccionOrdenesMedicas({required this.ordenes, required this.service, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.assignment, color: Colors.indigo),
        title: const Text("Órdenes Médicas Registradas", style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          if (ordenes.isEmpty)
            const Padding(
                padding: EdgeInsets.all(20), 
                child: Text("No hay órdenes en el historial.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
          
          ...ordenes.map((orden) {
            final esPendiente = orden['estatus'] == 'PENDIENTE';
            final medInfo = orden['medicamento'] ?? {}; 
            final nombreFarma = medInfo['nombre'] ?? 'Medicamento no vinculado';
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: esPendiente ? Colors.orange[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: esPendiente ? Colors.orange[200]! : Colors.grey[300]!),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  nombreFarma.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: esPendiente ? Colors.blue[800] : Colors.grey[700],
                    fontSize: 15
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                        children: [
                          const TextSpan(text: "Dosis: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                          TextSpan(text: "${orden['requerimiento_medicamentos']}"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text("Indicaciones: ${orden['indicaciones_inmediatas'] ?? 'Ninguna'}",
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: esPendiente ? Colors.orange : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        orden['estatus'],
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                trailing: esPendiente
                    ? IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.indigo, size: 30),
                        onPressed: () => _editarOrden(context, orden),
                      )
                    : const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _editarOrden(BuildContext context, Map<String, dynamic> orden) {
    final indicacionesCtrl = TextEditingController(text: orden['indicaciones_inmediatas']);
    final medicamentosCtrl = TextEditingController(text: orden['requerimiento_medicamentos']);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Prescripción"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: medicamentosCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Fármaco y Dosis", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: indicacionesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Indicaciones del Médico", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await service.editarOrden(orden['id_orden'], {
                'indicaciones_inmediatas': indicacionesCtrl.text,
                'requerimiento_medicamentos': medicamentosCtrl.text
              });
              if (res['success']) onUpdate();
            },
            child: const Text("Actualizar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}