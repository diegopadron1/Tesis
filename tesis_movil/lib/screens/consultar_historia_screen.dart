import 'package:flutter/material.dart';
import '../../services/historia_service.dart';
import '../theme_notifier.dart'; // Asegúrate de que la ruta sea correcta

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.themeMode,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;

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
                        // Color del texto que escribes: Negro en claro, Blanco en oscuro
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: "Cédula del Paciente",
                          // Label: Teal brillante en oscuro, Teal oscuro en claro para contraste
                          labelStyle: TextStyle(color: isDark ? Colors.tealAccent : Colors.teal.shade900, fontWeight: FontWeight.bold),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.teal : Colors.grey.shade400)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.tealAccent : Colors.teal, width: 2)),
                          prefixIcon: Icon(Icons.history_edu, color: isDark ? Colors.tealAccent : Colors.teal),
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
                          : const Text("BUSCAR", style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                if (_hasSearched && _pacienteData == null)
                  Expanded(child: Center(child: Text("No se encontraron registros.", style: TextStyle(color: isDark ? Colors.redAccent : Colors.red.shade900, fontSize: 16, fontWeight: FontWeight.bold)))),

                if (_hasSearched && _listaVisitas.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Historial de Consultas (${_listaVisitas.length}):", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.tealAccent : Colors.teal.shade900)),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _listaVisitas.length,
                      itemBuilder: (context, index) {
                        final item = _listaVisitas[index];
                        final fecha = _formatearFecha(item['createdAt'] ?? item['fecha']);
                        final motivo = item['motivo_consulta'] ?? 'Sin descripción';
                        
                        return Card(
                          elevation: 3,
                          // Fondo de la tarjeta: Gris oscuro en dark, Gris muy claro en light
                          color: isDark ? Colors.grey[900] : Colors.grey[100],
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), 
                            side: BorderSide(color: isDark ? Colors.teal : Colors.teal.shade200, width: 1)
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            title: Text("Consulta: $fecha", 
                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                            subtitle: Text(motivo, 
                              maxLines: 2, 
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.tealAccent : Colors.teal),
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
    );
  }
}

// ---------------------------------------------------------------------------
// PANTALLA DE DETALLE (LECTURA PROFESIONAL)
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

  Map<String, dynamic> _extraerData(List<String> keysPosibles, {bool esGlobal = false}) {
    dynamic rawData;
    for (var key in keysPosibles) {
      if (pacienteDataFull.containsKey(key) && pacienteDataFull[key] != null) {
        rawData = pacienteDataFull[key];
        break;
      }
    }
    if (rawData == null) return {};
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    if (rawData is List && rawData.isNotEmpty) {
      if (esGlobal) return Map<String, dynamic>.from(rawData.first);
      final targetId = motivoEspecifico['id_carpeta']; 
      if (targetId != null) {
        var match = rawData.firstWhere(
          (item) => item['id_carpeta'] == targetId,
          orElse: () => null
        );
        if (match != null) return Map<String, dynamic>.from(match);
      }
      return {}; 
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.themeMode,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;

        return Scaffold(
          appBar: AppBar(
            title: Text("Detalle: $fechaTitulo"),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeaderResumen(isDark),
              const Divider(height: 30, thickness: 2, color: Colors.teal),

              _SeccionLectura(
                titulo: "Datos Personales",
                icon: Icons.person_outline,
                data: pacienteDataFull, 
                campos: const { 'nombre_apellido': 'Nombre', 'cedula': 'Cédula', 'telefono': 'Teléfono', 'Estado_civil': 'Estado Civil', 'Religion': 'Religión' },
                isDark: isDark,
              ),

              _SeccionLectura(
                titulo: "Contacto de Emergencia",
                icon: Icons.contact_phone,
                data: _extraerData(['ContactoEmergencium', 'ContactoEmergencia'], esGlobal: true),
                campos: const {'nombre_apellido': 'Nombre', 'parentesco': 'Parentesco', 'cedula_contacto': 'Cedula', 'telefono': 'Telefono'},
                isDark: isDark,
              ),

              _SeccionLectura(
                titulo: "Motivo de Consulta",
                icon: Icons.chat_bubble_outline,
                data: motivoEspecifico, 
                campos: const {'motivo_consulta': 'Motivo'},
                esEspecifico: true,
                isDark: isDark,
              ),

              _SeccionLectura(
                titulo: "Diagnóstico",
                icon: Icons.local_hospital,
                data: _extraerData(['Diagnostico', 'Diagnosticos']),
                campos: const {'descripcion': 'Descripción', 'tipo': 'Tipo', 'observaciones': 'Observaciones'},
                isDark: isDark,
              ),

              _SeccionLectura(
                titulo: "Examen Físico",
                icon: Icons.accessibility_new,
                data: _extraerData(['ExamenFisico', 'ExamenFisicos']),
                campos: const {'area': 'Área', 'hallazgos': 'Hallazgos'},
                isDark: isDark,
              ),

              _SeccionLectura(
                titulo: "Examen Funcional",
                icon: Icons.directions_walk,
                data: _extraerData(['ExamenFuncional', 'ExamenFuncionals']),
                campos: const {'sistema': 'Sistema', 'hallazgos': 'Hallazgos'},
                isDark: isDark,
              ),

              _SeccionLectura(
                titulo: "Antecedentes",
                icon: Icons.history,
                data: _extraerData(['AntecedentesPersonales', 'AntecedentesPersonale']),
                campos: const {'tipo': 'Tipo', 'detalle': 'Detalle'},
                isDark: isDark,
              ),

              _SeccionLectura(
                titulo: "Antecedentes Familiares",
                icon: Icons.family_restroom,
                data: _extraerData(['AntecedentesFamiliares', 'AntecedentesFamiliare']),
                campos: const {'tipo_familiar': 'Familiar', 'patologias': 'Patologías', 'vivo_muerto': 'Estado'},
                isDark: isDark,
              ),

              _SeccionLectura(
                titulo: "Hábitos Psicobiológicos",
                icon: Icons.smoking_rooms,
                data: _extraerData(['HabitosPsicobiologicos', 'HabitosPsicobiologico']),
                campos: const {'cafe': 'Café', 'tabaco': 'Tabaco', 'alcohol': 'Alcohol', 'sueño': 'Sueño'},
                isDark: isDark,
              ),

              _OrdenesMedicasLectura(
                isDark: isDark,
                ordenes: (pacienteDataFull['OrdenesMedicas'] as List? ?? [])
                  .where((o) => o['id_carpeta'] == motivoEspecifico['id_carpeta'])
                  .toList()
              ),

              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("VOLVER AL LISTADO"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }
    );
  }

  Widget _buildHeaderResumen(bool isDark) {
    return Card(
      color: isDark ? Colors.teal.shade900 : Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), 
        side: BorderSide(color: isDark ? Colors.tealAccent : Colors.teal)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isDark ? Colors.tealAccent : Colors.teal,
              radius: 25,
              child: Icon(Icons.person, size: 35, color: isDark ? Colors.black : Colors.white),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pacienteDataFull['nombre_apellido']?.toUpperCase() ?? 'SIN NOMBRE', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                Text("C.I: ${pacienteDataFull['cedula']}", 
                  style: TextStyle(color: isDark ? Colors.tealAccent : Colors.teal.shade900, fontWeight: FontWeight.w700)),
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
  final bool isDark;

  const _SeccionLectura({required this.titulo, required this.icon, required this.data, required this.campos, this.esEspecifico = false, required this.isDark});

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
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tieneDatos ? Colors.teal : Colors.grey.shade400, width: esEspecifico ? 2 : 1)
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: tieneDatos ? (isDark ? Colors.tealAccent : Colors.teal) : Colors.grey),
        title: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: tieneDatos ? (isDark ? Colors.white : Colors.black) : Colors.grey)),
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
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${entry.value}: ", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.tealAccent : Colors.teal.shade900, fontSize: 14)),
                            Expanded(child: Text(valor, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: isDark ? FontWeight.normal : FontWeight.w500))),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : const Text("Sin información registrada.", style: TextStyle(fontStyle: FontStyle.italic)),
          )
        ],
      ),
    );
  }
}

class _OrdenesMedicasLectura extends StatelessWidget {
  final List<dynamic> ordenes;
  final bool isDark;
  const _OrdenesMedicasLectura({required this.ordenes, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.teal)),
      child: ExpansionTile(
        leading: Icon(Icons.assignment, color: isDark ? Colors.tealAccent : Colors.teal),
        title: Text("Órdenes Médicas", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        children: [
          if (ordenes.isEmpty) 
            const Padding(padding: EdgeInsets.all(20), child: Text("No se registraron órdenes.")),
          
          ...ordenes.map((orden) {
            final esPendiente = orden['estatus'] == 'PENDIENTE';
            final medInfo = orden['medicamento'] ?? {}; 
            final nombreFarma = medInfo['nombre'] ?? 'Medicamento no vinculado';
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: esPendiente ? (isDark ? Colors.orange.withValues(alpha: 0.1) : Colors.orange.shade50) : (isDark ? Colors.blueGrey.withValues(alpha: 0.1) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: esPendiente ? Colors.orangeAccent : Colors.teal),
              ),
              child: ListTile(
                title: Text(nombreFarma.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.tealAccent : Colors.teal.shade900)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        children: [
                          TextSpan(text: "Dosis: ", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.pinkAccent : Colors.red.shade900)),
                          TextSpan(text: "${orden['requerimiento_medicamentos']}"),
                        ],
                      ),
                    ),
                    Text("Indicaciones: ${orden['indicaciones_inmediatas'] ?? 'Ninguna'}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
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