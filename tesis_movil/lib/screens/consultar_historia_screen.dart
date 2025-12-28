import 'package:flutter/material.dart';
import '../../services/historia_service.dart';

class ConsultarHistoriaScreen extends StatefulWidget {
  const ConsultarHistoriaScreen({super.key});

  @override
  State<ConsultarHistoriaScreen> createState() => _ConsultarHistoriaScreenState();
}

class _ConsultarHistoriaScreenState extends State<ConsultarHistoriaScreen> {
  final _cedulaSearchCtrl = TextEditingController();
  final HistoriaService _service = HistoriaService();

  bool _isLoading = false;
  bool _hasSearched = false;
  
  Map<String, dynamic>? _pacienteData; 
  List<Map<String, dynamic>> _listaVisitas = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarPermisos();
    });
  }

  Future<void> _verificarPermisos() async {
    String rolUsuarioLogueado = "ESPECIALISTA"; 
    if (rolUsuarioLogueado != "ESPECIALISTA") {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(children: [Icon(Icons.lock, color: Colors.red), SizedBox(width: 10), Text("Acceso Restringido")]),
          content: const Text("Este módulo es exclusivo para Especialistas."),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text("Entendido", style: TextStyle(color: Colors.red)),
            )
          ],
        ),
      );
    }
  }

  void _buscarHistoriales() async {
    if (_cedulaSearchCtrl.text.isEmpty) return;

    setState(() { _isLoading = true; _hasSearched = false; _pacienteData = null; _listaVisitas = []; });

    try {
      final data = await _service.getHistoriaClinica(_cedulaSearchCtrl.text.trim());
      if (!mounted) return;

      List<Map<String, dynamic>> listaTemporal = [];
      var motivosRaw = data['MotivoConsultas'] ?? [];

      if (motivosRaw is List) {
        for (var item in motivosRaw) {
          listaTemporal.add(Map<String, dynamic>.from(item));
        }
      }

      listaTemporal.sort((a, b) {
        String fechaA = a['createdAt'] ?? a['fecha'] ?? '';
        String fechaB = b['createdAt'] ?? b['fecha'] ?? '';
        return fechaB.compareTo(fechaA);
      });

      setState(() {
        _isLoading = false;
        _hasSearched = true;
        if (data.isNotEmpty) {
          _pacienteData = data;
          _listaVisitas = listaTemporal;
        }
      });

    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _hasSearched = true; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  String _formatearFecha(String? fechaRaw) {
    if (fechaRaw == null || fechaRaw.isEmpty) return "Fecha no registrada";
    try {
      final date = DateTime.parse(fechaRaw);
      return "${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}";
    } catch (e) {
      return fechaRaw; 
    }
  }

  void _verDetalleHistorial(Map<String, dynamic> motivoSeleccionado) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleHistorialReadOnlyScreen(
          pacienteDataFull: _pacienteData!,
          motivoEspecifico: motivoSeleccionado,
          fechaTitulo: _formatearFecha(motivoSeleccionado['createdAt'] ?? motivoSeleccionado['fecha']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listaMostrar = _listaVisitas.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Consultar Historial"),
        backgroundColor: Colors.teal, 
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cedulaSearchCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Cédula del Paciente",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.history_edu),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _buscarHistoriales,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("BUSCAR"),
                )
              ],
            ),
            const SizedBox(height: 20),

            if (_hasSearched && _pacienteData == null)
              const Expanded(child: Center(child: Text("No se encontraron registros.", style: TextStyle(color: Colors.red, fontSize: 16)))),

            if (_hasSearched && _pacienteData != null && _listaVisitas.isEmpty)
               const Expanded(child: Center(child: Text("Paciente sin historial de consultas.", textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontSize: 16)))),

            if (_hasSearched && _listaVisitas.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Historial de Consultas (${_listaVisitas.length}):", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: listaMostrar.length,
                  itemBuilder: (context, index) {
                    final item = listaMostrar[index];
                    final fecha = _formatearFecha(item['createdAt'] ?? item['fecha']);
                    final motivo = item['motivo_consulta'] ?? 'Sin descripción';
                    
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Text("${index + 1}", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                        ),
                        title: Text("Consulta: $fecha", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(motivo, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () => _verDetalleHistorial(item),
                      ),
                    );
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PANTALLA DE DETALLE (LECTURA PROFESIONAL CORREGIDA)
// ---------------------------------------------------------------------------
class DetalleHistorialReadOnlyScreen extends StatelessWidget {
  final Map<String, dynamic> pacienteDataFull;
  final Map<String, dynamic> motivoEspecifico; 
  final String fechaTitulo;

  const DetalleHistorialReadOnlyScreen({
    super.key,
    required this.pacienteDataFull,
    required this.motivoEspecifico,
    required this.fechaTitulo,
  });

  // --- HELPER CORREGIDO: FILTRADO ESTRICTO ---
  Map<String, dynamic> _extraerData(List<String> keysPosibles, {bool esGlobal = false}) {
    dynamic rawData;
    
    for (var key in keysPosibles) {
      if (pacienteDataFull.containsKey(key) && pacienteDataFull[key] != null) {
        rawData = pacienteDataFull[key];
        break;
      }
    }

    if (rawData == null) return {};
    
    // Si es un mapa directo, lo devolvemos
    if (rawData is Map) return Map<String, dynamic>.from(rawData);

    if (rawData is List && rawData.isNotEmpty) {
      // Si es global (como contacto), devolvemos el más reciente
      if (esGlobal) return Map<String, dynamic>.from(rawData.first);

      // Si es de carpeta, buscamos el ID exacto
      final targetId = motivoEspecifico['id_carpeta']; 
      if (targetId != null) {
        var match = rawData.firstWhere(
          (item) => item['id_carpeta'] == targetId,
          orElse: () => null
        );
        if (match != null) return Map<String, dynamic>.from(match);
      }
      
      // ELIMINADO EL FALLBACK QUE MOSTRABA DATOS VIEJOS
      return {}; 
    }

    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detalle: $fechaTitulo"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderResumen(),
          const Divider(height: 30, thickness: 2),

          _SeccionLectura(
            titulo: "Datos Personales",
            icon: Icons.person_outline,
            data: pacienteDataFull, 
            campos: const { 'nombre_apellido': 'Nombre', 'cedula': 'Cédula', 'telefono': 'Teléfono', 'Estado_civil': 'Estado Civil', 'Religion': 'Religión' },
          ),

          _SeccionLectura(
            titulo: "Contacto de Emergencia",
            icon: Icons.contact_phone,
            data: _extraerData(['ContactoEmergencium', 'ContactoEmergencia'], esGlobal: true),
            campos: const {'nombre_apellido': 'Nombre', 'parentesco': 'Parentesco', 'cedula_contacto': 'Cedula', 'telefono': 'Telefono'},
          ),

          _SeccionLectura(
            titulo: "Motivo de Consulta",
            icon: Icons.chat_bubble_outline,
            data: motivoEspecifico, 
            campos: const {'motivo_consulta': 'Motivo'},
            esEspecifico: true,
          ),

          _SeccionLectura(
            titulo: "Diagnóstico",
            icon: Icons.local_hospital,
            data: _extraerData(['Diagnostico', 'Diagnosticos']),
            campos: const {'descripcion': 'Descripción', 'tipo': 'Tipo', 'observaciones': 'Observaciones'},
          ),

          _SeccionLectura(
            titulo: "Examen Físico",
            icon: Icons.accessibility_new,
            data: _extraerData(['ExamenFisico', 'ExamenFisicos']),
            campos: const {'area': 'Área', 'hallazgos': 'Hallazgos'},
          ),

          _SeccionLectura(
            titulo: "Examen Funcional",
            icon: Icons.directions_walk,
            data: _extraerData(['ExamenFuncional', 'ExamenFuncionals']),
            campos: const {'sistema': 'Sistema', 'hallazgos': 'Hallazgos'},
          ),

          _SeccionLectura(
            titulo: "Antecedentes",
            icon: Icons.history,
            data: _extraerData(['AntecedentesPersonales', 'AntecedentesPersonale']),
            campos: const {'tipo': 'Tipo', 'detalle': 'Detalle'},
          ),

          _SeccionLectura(
            titulo: "Antecedentes Familiares",
            icon: Icons.family_restroom,
            data: _extraerData(['AntecedentesFamiliares', 'AntecedentesFamiliare']),
            campos: const {'tipo_familiar': 'Familiar', 'patologias': 'Patologías', 'vivo_muerto': 'Estado'},
          ),

          _SeccionLectura(
            titulo: "Hábitos Psicobiológicos",
            icon: Icons.smoking_rooms,
            data: _extraerData(['HabitosPsicobiologicos', 'HabitosPsicobiologico']),
            campos: const {'cafe': 'Café', 'tabaco': 'Tabaco', 'alcohol': 'Alcohol', 'sueño': 'Sueño'},
          ),

          _OrdenesMedicasLectura(
            ordenes: (pacienteDataFull['OrdenesMedicas'] as List? ?? [])
              .where((o) => o['id_carpeta'] == motivoEspecifico['id_carpeta'])
              .toList()
          ),

          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text("Volver al listado"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700], foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeaderResumen() {
    return Card(
      color: Colors.teal[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.person, size: 40, color: Colors.teal),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pacienteDataFull['nombre_apellido'] ?? 'Sin Nombre', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("C.I: ${pacienteDataFull['cedula']}", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeccionLectura extends StatelessWidget {
  final String titulo;
  final IconData icon;
  final Map<String, dynamic> data;
  final Map<String, String> campos;
  final bool esEspecifico; 

  const _SeccionLectura({required this.titulo, required this.icon, required this.data, required this.campos, this.esEspecifico = false});

  @override
  Widget build(BuildContext context) {
    bool tieneDatos = false;
    for (var key in campos.keys) {
      if (data[key] != null && data[key].toString().isNotEmpty) {
        tieneDatos = true;
        break;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: esEspecifico ? 4 : 2,
      shape: esEspecifico ? RoundedRectangleBorder(side: const BorderSide(color: Colors.teal, width: 2), borderRadius: BorderRadius.circular(12)) : null,
      child: ExpansionTile(
        leading: Icon(icon, color: tieneDatos ? Colors.teal : Colors.grey),
        title: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: tieneDatos ? Colors.black : Colors.grey)),
        initiallyExpanded: tieneDatos || esEspecifico, 
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: tieneDatos
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: campos.entries.map((entry) {
                      final valor = data[entry.key]?.toString();
                      if (valor == null || valor.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${entry.value}: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                            Expanded(child: Text(valor)),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : const Text("Sin información registrada en esta visita.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          )
        ],
      ),
    );
  }
}

class _OrdenesMedicasLectura extends StatelessWidget {
  final List<dynamic> ordenes;
  const _OrdenesMedicasLectura({required this.ordenes});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.assignment, color: Colors.teal),
        title: const Text("Órdenes Médicas", style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          if (ordenes.isEmpty) 
            const Padding(
                padding: EdgeInsets.all(20), 
                child: Text("No se registraron órdenes en esta visita.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
          
          ...ordenes.map((orden) {
            final esPendiente = orden['estatus'] == 'PENDIENTE';
            final medInfo = orden['medicamento'] ?? {}; 
            final nombreFarma = medInfo['nombre'] ?? 'Medicamento no vinculado';
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: esPendiente ? Colors.orange[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: esPendiente ? Colors.orange[200]! : Colors.grey[300]!),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  nombreFarma.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: esPendiente ? Colors.teal[800] : Colors.grey[700],
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
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: esPendiente ? Colors.orange : Colors.green[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        orden['estatus'] ?? 'N/A',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }), 
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}