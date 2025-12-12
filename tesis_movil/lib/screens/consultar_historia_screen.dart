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

      // Extraemos la lista plana de Motivos que generó el backend
      var motivosRaw = data['MotivoConsultas'] ?? [];

      if (motivosRaw is List) {
        for (var item in motivosRaw) {
          listaTemporal.add(Map<String, dynamic>.from(item));
        }
      }

      // Ordenar por fecha descendente
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
    // Aquí es donde ocurre la magia: Pasamos el motivo que TIENE el id_carpeta
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
// PANTALLA DE DETALLE (LÓGICA EXACTA POR ID_CARPETA)
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

  // HELPER MAESTRO: Busca por coincidencia exacta de 'id_carpeta'
  Map<String, dynamic> _extraerDataPorCarpeta(List<String> keysPosibles) {
    dynamic rawData;
    
    // 1. Obtener la lista cruda
    for (var key in keysPosibles) {
      if (pacienteDataFull.containsKey(key) && pacienteDataFull[key] != null) {
        rawData = pacienteDataFull[key];
        break;
      }
    }

    if (rawData == null) return {};
    
    // 2. Si es mapa (datos únicos como datos personales), devolverlo directo
    if (rawData is Map) return Map<String, dynamic>.from(rawData);

    // 3. Lógica de "CARPETA EXACTA"
    // Buscamos el registro que tenga el MISMO id_carpeta que el motivo seleccionado
    if (rawData is List && rawData.isNotEmpty) {
      final targetId = motivoEspecifico['id_carpeta']; // El ID mágico que une todo

      if (targetId != null) {
        var coincidencia = rawData.firstWhere(
          (item) => item['id_carpeta'] == targetId,
          orElse: () => null
        );

        if (coincidencia != null) {
          return Map<String, dynamic>.from(coincidencia);
        }
      }
      
      // NOTA: Para Antecedentes, si no hay uno específico en esta carpeta (porque quizás no se editaron ese día),
      // es seguro mostrar el último registrado para que el médico tenga contexto.
      if (keysPosibles.first.contains('Antecedentes') || keysPosibles.first.contains('Habitos')) {
         // Tomamos el primero porque la lista viene ordenada DESC (el más reciente)
         return Map<String, dynamic>.from(rawData.first);
      }

      // Para Diagnósticos o Exámenes, si no es de esta carpeta, mejor devolver vacío
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
            data: _extraerDataPorCarpeta(['ContactoEmergencia', 'ContactoEmergencias']),
            campos: const {'nombre_apellido': 'Nombre', 'parentesco': 'Parentesco', 'telefono': 'Teléfono'},
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
            data: _extraerDataPorCarpeta(['Diagnostico', 'Diagnosticos']),
            campos: const {'descripcion': 'Descripción', 'tipo': 'Tipo', 'observaciones': 'Observaciones'},
          ),

          _SeccionLectura(
            titulo: "Examen Físico",
            icon: Icons.accessibility_new,
            data: _extraerDataPorCarpeta(['ExamenFisico', 'ExamenFisicos']),
            campos: const {'area': 'Área', 'hallazgos': 'Hallazgos'},
          ),

          _SeccionLectura(
            titulo: "Examen Funcional",
            icon: Icons.directions_walk,
            data: _extraerDataPorCarpeta(['ExamenFuncional', 'ExamenFuncionals']),
            campos: const {'sistema': 'Sistema', 'hallazgos': 'Hallazgos'},
          ),

          _SeccionLectura(
            titulo: "Antecedentes Personales",
            icon: Icons.history,
            data: _extraerDataPorCarpeta(['AntecedentesPersonales', 'AntecedentesPersonale']),
            campos: const {'tipo': 'Tipo', 'detalle': 'Detalle'},
          ),

          _SeccionLectura(
            titulo: "Antecedentes Familiares",
            icon: Icons.family_restroom,
            data: _extraerDataPorCarpeta(['AntecedentesFamiliares', 'AntecedentesFamiliare']),
            campos: const {'tipo_familiar': 'Familiar', 'patologias': 'Patologías', 'vivo_muerto': 'Estado'},
          ),

          _SeccionLectura(
            titulo: "Hábitos Psicobiológicos",
            icon: Icons.smoking_rooms,
            data: _extraerDataPorCarpeta(['HabitosPsicobiologicos', 'HabitosPsicobiologico']),
            campos: const {'cafe': 'Café', 'tabaco': 'Tabaco', 'alcohol': 'Alcohol', 'sueño': 'Sueño'},
          ),

          // Órdenes Médicas: Filtrar por id_carpeta también
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
                : const Text("Sin información.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
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
      child: ExpansionTile(
        leading: const Icon(Icons.assignment, color: Colors.teal),
        title: const Text("Órdenes Médicas", style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          if (ordenes.isEmpty) const Padding(padding: EdgeInsets.all(15), child: Text("No hubo órdenes.")),
          ...ordenes.map((orden) {
            return Column(
              children: [
                ListTile(
                  title: Text("Orden #${orden['id_orden']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Med: ${orden['requerimiento_medicamentos']}\nInd: ${orden['indicaciones_inmediatas'] ?? 'Ninguna'}"),
                  trailing: Chip(label: Text(orden['estatus'] ?? 'N/A', style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: (orden['estatus'] == 'PENDIENTE') ? Colors.orange : Colors.green),
                ),
                const Divider(),
              ],
            );
          })
        ],
      ),
    );
  }
}