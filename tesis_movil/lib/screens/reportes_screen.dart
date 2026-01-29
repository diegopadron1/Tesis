import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/reporte_service.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final ReporteService _reporteService = ReporteService();
  DateTime _fechaSeleccionada = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _datos;

  @override
  void initState() {
    super.initState();
    _cargarReporte();
  }

  void _cargarReporte() async {
    setState(() => _isLoading = true);
    final fechaStr = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
    final res = await _reporteService.getReportePacientes(fechaStr);
    
    if (mounted) {
      setState(() {
        if (res['success']) {
          _datos = res['data'];
        } else {
          _datos = null; // Limpiar datos si hay error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message']), backgroundColor: Colors.red),
          );
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: 'SELECCIONAR FECHA DE REPORTE',
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() => _fechaSeleccionada = picked);
      _cargarReporte();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte Operativo Diario'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _seleccionarFecha(context)),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarReporte),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderFecha(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _datos == null 
                ? _buildEmptyState()
                : _buildContenidoReporte(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderFecha() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      color: Colors.indigo.withValues(alpha: 0.05),
      child: Row(
        children: [
          const Icon(Icons.insert_chart_outlined, color: Colors.indigo),
          const SizedBox(width: 10),
          Text(
            "Resumen del: ${DateFormat('dd MMMM, yyyy').format(_fechaSeleccionada)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContenidoReporte() {
    final m = _datos!['metricas'];
    final areas = _datos!['distribucion_areas'] as List;

    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _sectionTitle("Gestión de Pacientes"),
        Row(
          children: [
            _buildKPICard("Atendidos", "${m['total_atendidos']}", Colors.blue, Icons.person_search),
            _buildKPICard("Altas", "${m['altas']}", Colors.green, Icons.check_circle_outline),
            _buildKPICard("Fallecidos", "${m['fallecidos']}", Colors.red, Icons.warning_amber),
          ],
        ),
        
        const SizedBox(height: 25),

        _sectionTitle("Estatus de Órdenes"),
        Row(
          children: [
            _buildKPICard("Realizadas", "${m['ordenes_realizadas']}", Colors.teal, Icons.task_alt),
            _buildKPICard("Pendientes", "${m['ordenes_pendientes']}", Colors.amber[800]!, Icons.timer),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildKPICard("Canceladas", "${m['ordenes_canceladas']}", Colors.orange, Icons.block),
            _buildKPICard("No Realiz.", "${m['ordenes_no_realizadas']}", Colors.blueGrey, Icons.auto_delete_outlined),
          ],
        ),

        const SizedBox(height: 20),

        _sectionTitle("Insumos y Farmacia"),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.medication, color: Colors.white, size: 20),
            ),
            title: const Text("Solicitudes Realizadas", style: TextStyle(fontWeight: FontWeight.w500)),
            trailing: Text("${m['total_solicitudes']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
          ),
        ),

        const SizedBox(height: 25),

        _sectionTitle("Carga por Área"),
        const Divider(),
        if (areas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("Sin movimientos en áreas.", textAlign: TextAlign.center),
          )
        else
          ...areas.map((a) => _buildAreaItem(a)),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.indigo),
      ),
    );
  }

  Widget _buildKPICard(String titulo, String valor, Color color, IconData icono) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icono, color: color, size: 24),
              const SizedBox(height: 5),
              Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(titulo, 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MÉTODO CORREGIDO PARA MODO CLARO/OSCURO
  Widget _buildAreaItem(Map<String, dynamic> area) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 1,
      // Se eliminó el color negro fijo para que use el del tema (blanco en modo claro)
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Icon(Icons.location_on, color: Colors.white, size: 18),
        ),
        title: Text(
          area['ubicacion'], 
          style: TextStyle(
            fontSize: 15, 
            fontWeight: FontWeight.bold,
            // El color del texto ahora se adapta al tema
            color: isDark ? Colors.white : Colors.black87,
          )
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${area['cantidad']} pac.",
            style: const TextStyle(
              color: Colors.indigo, 
              fontWeight: FontWeight.bold, 
              fontSize: 12
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.query_stats, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text("Selecciona una fecha para ver el reporte", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}