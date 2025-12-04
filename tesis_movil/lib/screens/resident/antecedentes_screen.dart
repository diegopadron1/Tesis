import 'package:flutter/material.dart';
import '../../services/antecedentes_service.dart';

class AntecedentesScreen extends StatefulWidget {
  final String cedulaPaciente;
  const AntecedentesScreen({super.key, required this.cedulaPaciente});

  @override
  State<AntecedentesScreen> createState() => _AntecedentesScreenState();
}

class _AntecedentesScreenState extends State<AntecedentesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.teal[800],
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: "Personales"),
              Tab(text: "Familiares"),
              Tab(text: "Hábitos"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FormPersonal(cedula: widget.cedulaPaciente),
              _FormFamiliar(cedula: widget.cedulaPaciente),
              _FormHabitos(cedula: widget.cedulaPaciente),
            ],
          ),
        ),
      ],
    );
  }
}

// --- PERSONALES ---
class _FormPersonal extends StatefulWidget {
  final String cedula;
  const _FormPersonal({required this.cedula});
  @override
  State<_FormPersonal> createState() => _FormPersonalState();
}
class _FormPersonalState extends State<_FormPersonal> {
  final _service = AntecedentesService();
  final _tipoCtrl = TextEditingController();
  final _detalleCtrl = TextEditingController();
  
  void _guardar() async {
      if(_tipoCtrl.text.isEmpty) return;
      final res = await _service.createPersonal(widget.cedula, _tipoCtrl.text, _detalleCtrl.text);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(controller: _tipoCtrl, decoration: const InputDecoration(labelText: "Tipo (Alergia, etc)")),
        const SizedBox(height: 10),
        TextField(controller: _detalleCtrl, decoration: const InputDecoration(labelText: "Detalle")),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _guardar, child: const Text("Guardar Personal"))
      ],
    );
  }
}

// --- FAMILIARES ---
class _FormFamiliar extends StatefulWidget {
  final String cedula;
  const _FormFamiliar({required this.cedula});
  @override
  State<_FormFamiliar> createState() => _FormFamiliarState();
}

class _FormFamiliarState extends State<_FormFamiliar> {
  final _service = AntecedentesService();
  
  // Controladores
  final _tipoCtrl = TextEditingController();
  final _edadCtrl = TextEditingController(); // CAMPO RESTAURADO
  final _patologiasCtrl = TextEditingController();
  
  String _vivo = 'Vivo'; // Valor inicial

  void _guardar() async {
    if (_tipoCtrl.text.isEmpty) return;
    
    // Enviamos _edadCtrl.text en lugar de null
    final res = await _service.createFamiliar(
        widget.cedula, 
        _tipoCtrl.text, 
        _vivo, 
        _edadCtrl.text, // Aquí va la edad
        _patologiasCtrl.text
    );

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res['message'])));
      
      if (res['success']) {
        _tipoCtrl.clear();
        _edadCtrl.clear();
        _patologiasCtrl.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // CAMPO PARENTESCO
        TextField(
          controller: _tipoCtrl,
          decoration: const InputDecoration(
            labelText: "Parentesco (Ej: Madre)",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
        ),
        const SizedBox(height: 20),

        // CAMPO ESTADO
        DropdownButtonFormField<String>(
          initialValue: _vivo,
          decoration: const InputDecoration(
            labelText: "Estado",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
          items: ['Vivo', 'Muerto']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _vivo = v!),
        ),
        const SizedBox(height: 20),

        // CAMPO EDAD (RESTAURADO)
        TextField(
          controller: _edadCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Edad (Opcional)",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
        ),
        const SizedBox(height: 20),

        // CAMPO PATOLOGÍAS
        TextField(
          controller: _patologiasCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: "Patologías (Opcional)",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
        ),
        const SizedBox(height: 30),

        // BOTÓN GUARDAR
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: const Text("Guardar Familiar"),
        )
      ],
    );
  }
}

// --- HÁBITOS ---
class _FormHabitos extends StatefulWidget {
  final String cedula;
  const _FormHabitos({required this.cedula});
  @override
  State<_FormHabitos> createState() => _FormHabitosState();
}

class _FormHabitosState extends State<_FormHabitos> {
  final _service = AntecedentesService();
  
  // 1. Controladores de Consumo
  final _cafe = TextEditingController(text: "Niega");
  final _tabaco = TextEditingController(text: "Niega");
  final _alcohol = TextEditingController(text: "Niega");
  final _drogas = TextEditingController(text: "Niega"); // Restaurado

  // 2. Controladores de Estilo de Vida (Restaurados)
  final _ocupacion = TextEditingController();
  final _sueno = TextEditingController();
  final _vivienda = TextEditingController();

  void _guardar() async {
    // Actualizamos la llamada para enviar los datos reales de los controladores
    final res = await _service.createHabitos(
        widget.cedula, 
        _cafe.text, 
        _tabaco.text, 
        _alcohol.text, 
        _drogas.text,     // Valor real
        _ocupacion.text,  // Valor real
        _sueno.text,      // Valor real
        _vivienda.text    // Valor real
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // --- SECCIÓN CONSUMOS ---
        const Text("Consumos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 15),

        _buildField(_cafe, "Café"),
        const SizedBox(height: 15),
        
        _buildField(_tabaco, "Tabaco"),
        const SizedBox(height: 15),
        
        _buildField(_alcohol, "Alcohol"),
        const SizedBox(height: 15),

        _buildField(_drogas, "Drogas"),
        
        const SizedBox(height: 30),

        // --- SECCIÓN ESTILO DE VIDA ---
        const Text("Estilo de Vida", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 15),

        _buildField(_ocupacion, "Ocupación"),
        const SizedBox(height: 15),

        _buildField(_sueno, "Sueño (Ej: 8 horas, reparador)"),
        const SizedBox(height: 15),

        _buildField(_vivienda, "Vivienda (Ej: Casa, Apartamento)"),

        const SizedBox(height: 30),

        ElevatedButton(
          onPressed: _guardar, 
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: const Text("Guardar Hábitos")
        )
      ],
    );
  }

  // Método auxiliar para no repetir tanto código visual
  Widget _buildField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(), // Estilo de caja
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
    );
  }
}