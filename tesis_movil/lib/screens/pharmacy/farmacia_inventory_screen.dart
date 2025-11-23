import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml
import '../../models/medicamento.dart';
import '../../services/farmacia_service.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class FarmaciaInventoryScreen extends StatefulWidget {
  const FarmaciaInventoryScreen({super.key});

  @override
  State<FarmaciaInventoryScreen> createState() => _FarmaciaInventoryScreenState();
}

class _FarmaciaInventoryScreenState extends State<FarmaciaInventoryScreen> {
  final FarmaciaService _service = FarmaciaService();
  final AuthService _authService = AuthService();
  late Future<List<Medicamento>> _inventarioFuture;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _inventarioFuture = _service.getInventario();
    });
  }

  // --- DIÁLOGO: Crear Nuevo Medicamento ---
  void _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final principioCtrl = TextEditingController();
    final concentracionCtrl = TextEditingController();
    final presentacionCtrl = TextEditingController();
    final fechaCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nuevo Medicamento"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre Comercial *"), validator: (v) => v!.isEmpty ? "Requerido" : null),
                TextFormField(controller: principioCtrl, decoration: const InputDecoration(labelText: "Principio Activo")),
                TextFormField(controller: concentracionCtrl, decoration: const InputDecoration(labelText: "Concentración (Ej: 500mg)")),
                TextFormField(controller: presentacionCtrl, decoration: const InputDecoration(labelText: "Presentación (Ej: Tableta)")),
                
                // NUEVO CAMPO: FECHA DE VENCIMIENTO
                TextFormField(
                  controller: fechaCtrl,
                  decoration: const InputDecoration(
                    labelText: "Fecha Vencimiento (YYYY-MM-DD)",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 365)), // Por defecto 1 año adelante
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      // Usamos DateFormat de intl para formatear
                      // Si no tienes intl, puedes usar: "${pickedDate.toLocal()}".split(' ')[0]
                      fechaCtrl.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              final res = await _service.createMedicamento({
                'nombre': nombreCtrl.text,
                'principio_activo': principioCtrl.text,
                'concentracion': concentracionCtrl.text,
                'presentacion': presentacionCtrl.text,
                'stock_minimo': 10,
                'fecha_vencimiento': fechaCtrl.text // Enviamos la fecha
              });
              
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red));
              if (res['success']) _refreshList();
            },
            child: const Text("Crear"),
          )
        ],
      ),
    );
  }

  // --- DIÁLOGO: Agregar Stock (ENTRADA) ---
  void _showAddStockDialog(Medicamento med) {
    final cantidadCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Entrada: ${med.nombre}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Stock Actual: ${med.cantidadDisponible}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: cantidadCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Cantidad a sumar", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: motivoCtrl, decoration: const InputDecoration(labelText: "Motivo (Opcional)", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final cant = int.tryParse(cantidadCtrl.text);
              if (cant == null || cant <= 0) return;
              
              final res = await _service.addStock(med.idMedicamento, cant, motivoCtrl.text);
              
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red));
              if (res['success']) _refreshList();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Sumar Stock"),
          )
        ],
      ),
    );
  }

  // --- DIÁLOGO: Quitar Stock (SALIDA) ---
  void _showRemoveStockDialog(Medicamento med) {
    final cantidadCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Salida: ${med.nombre}", style: const TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Stock Actual: ${med.cantidadDisponible}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: cantidadCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Cantidad a restar", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: motivoCtrl, decoration: const InputDecoration(labelText: "Motivo (Ej: Vencido)", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final cant = int.tryParse(cantidadCtrl.text);
              if (cant == null || cant <= 0) return;
              
              final res = await _service.removeStock(med.idMedicamento, cant, motivoCtrl.text);
              
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red));
              if (res['success']) _refreshList();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Restar Stock"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Farmacia"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
              }
            },
          )
        ],
      ),
      body: FutureBuilder<List<Medicamento>>(
        future: _inventarioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Inventario vacío. Agregue medicamentos."));

          final lista = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: lista.length,
            itemBuilder: (ctx, i) {
              final med = lista[i];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: med.cantidadDisponible <= med.stockMinimo ? Colors.red[100] : Colors.green[100],
                    child: Icon(Icons.medication, color: med.cantidadDisponible <= med.stockMinimo ? Colors.red : Colors.green[800]),
                  ),
                  title: Text("${med.nombre} ${med.concentracion ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${med.presentacion ?? 'Unidad'} • Stock: ${med.cantidadDisponible}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // BOTÓN RESTAR
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        tooltip: "Restar Stock",
                        onPressed: () => _showRemoveStockDialog(med),
                      ),
                      // BOTÓN SUMAR
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        tooltip: "Agregar Stock",
                        onPressed: () => _showAddStockDialog(med),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        label: const Text("Nuevo Medicamento"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green[700],
      ),
    );
  }
}