import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // --- LÓGICA DE ALERTA DE VENCIMIENTO ---
  Widget? _buildVencimientoAlerta(String? fechaVenc) {
    if (fechaVenc == null || fechaVenc.isEmpty) return null;

    try {
      final fechaExp = DateTime.parse(fechaVenc);
      final ahora = DateTime.now();
      final diferencia = fechaExp.difference(ahora).inDays;

      // Si falta una semana o menos (pero no ha vencido aún)
      if (diferencia <= 7 && diferencia >= 0) {
        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.orange),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                "Expira en $diferencia días",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange[900]),
              ),
            ],
          ),
        );
      } else if (diferencia < 0) {
        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Text(
            "MEDICAMENTO VENCIDO",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // --- ACCIÓN RÁPIDA AL BUSCAR ---
  void _mostrarAccionesRapidas(Medicamento med) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text("Agregar Stock"),
              onTap: () { Navigator.pop(ctx); _showAddStockDialog(med); },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text("Retirar Stock"),
              onTap: () { Navigator.pop(ctx); _showRemoveStockDialog(med); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Eliminar Registro Completo", style: TextStyle(color: Colors.red)),
              subtitle: const Text("Elimina toda la información del sistema"),
              onTap: () { Navigator.pop(ctx); _confirmarEliminacion(med); },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminacion(Medicamento med) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text("¿Eliminar registro?"),
          ],
        ),
        content: Text("Esta acción eliminará a '${med.nombre}' de forma permanente del inventario. Esta operación no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await _service.eliminarMedicamento(med.idMedicamento);
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                   content: Text(res['message']), 
                   backgroundColor: res['success'] ? Colors.green : Colors.red
                 ));
                 if (res['success']) _refreshList();
              }
            },
            child: const Text("ELIMINAR TODO"),
          ),
        ],
      ),
    );
  }

  // --- DIÁLOGOS CREAR, SUMAR Y RESTAR SE MANTIENEN IGUAL QUE TU CÓDIGO ---
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
                TextFormField(
                  controller: nombreCtrl, 
                  decoration: const InputDecoration(labelText: "Nombre Comercial *"), 
                  validator: (v) => v == null || v.trim().isEmpty ? "El nombre es requerido" : null
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: principioCtrl, 
                  decoration: const InputDecoration(labelText: "Principio Activo *"),
                  validator: (v) => v == null || v.trim().isEmpty ? "Requerido" : null
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: concentracionCtrl, 
                  decoration: const InputDecoration(labelText: "Concentración *"),
                  validator: (v) => v == null || v.trim().isEmpty ? "Requerido (ej: 500mg)" : null
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: presentacionCtrl, 
                  decoration: const InputDecoration(labelText: "Presentación *"),
                  validator: (v) => v == null || v.trim().isEmpty ? "Requerido (ej: Tabletas)" : null
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: fechaCtrl,
                  decoration: const InputDecoration(labelText: "Fecha Vencimiento *", suffixIcon: Icon(Icons.calendar_today)),
                  readOnly: true,
                  validator: (v) => v == null || v.isEmpty ? "Seleccione una fecha" : null,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context, 
                      initialDate: DateTime.now().add(const Duration(days: 365)), 
                      firstDate: DateTime.now(), 
                      lastDate: DateTime(2100)
                    );
                    if (pickedDate != null) fechaCtrl.text = DateFormat('yyyy-MM-dd').format(pickedDate);
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
                'fecha_vencimiento': fechaCtrl.text
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red));
                 if (res['success']) _refreshList();
              }
            },
            child: const Text("Crear"),
          )
        ],
      ),
    );
  }

  void _showAddStockDialog(Medicamento med) {
    final cantidadCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Entrada: ${med.nombre}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Text("Stock Actual: ${med.cantidadDisponible}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20), 
              TextField(
                controller: cantidadCtrl, 
                keyboardType: TextInputType.number, 
                decoration: const InputDecoration(labelText: "Cantidad a sumar", border: OutlineInputBorder())
              ),
              const SizedBox(height: 15), 
              TextField(
                controller: motivoCtrl, 
                decoration: const InputDecoration(labelText: "Motivo (Opcional)", border: OutlineInputBorder())
              ),
            ]
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final cant = int.tryParse(cantidadCtrl.text);
              if (cant == null || cant <= 0) return;
              final res = await _service.addStock(med.idMedicamento, cant, motivoCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red));
                 if (res['success']) _refreshList();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Sumar Stock"),
          )
        ],
      ),
    );
  }

  void _showRemoveStockDialog(Medicamento med) {
    final formKey = GlobalKey<FormState>(); 
    final cantidadCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Salida: ${med.nombre}", style: const TextStyle(color: Colors.red)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                Text("Stock Actual: ${med.cantidadDisponible}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                TextFormField( 
                  controller: cantidadCtrl, 
                  keyboardType: TextInputType.number, 
                  decoration: const InputDecoration(labelText: "Cantidad a restar", border: OutlineInputBorder()),
                  validator: (v) => (v == null || int.tryParse(v) == null || int.parse(v) <= 0) ? 'Inválido' : null,
                ),
                const SizedBox(height: 15),
                TextFormField( 
                  controller: motivoCtrl, 
                  decoration: const InputDecoration(labelText: "Motivo (Obligatorio)", border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ]
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final cant = int.parse(cantidadCtrl.text);
              final res = await _service.removeStock(med.idMedicamento, cant, motivoCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red));
                 if (res['success']) _refreshList();
              }
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
        title: const Text("Inventario Farmacia"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // --- BUSCADOR ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Autocomplete<Medicamento>(
              displayStringForOption: (Medicamento m) => m.nombre,
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) return const Iterable<Medicamento>.empty();
                return await _service.searchMedicamentos(textEditingValue.text);
              },
              onSelected: _mostrarAccionesRapidas,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: "Buscar medicamento...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                    filled: true,
                    fillColor: Colors.grey[200], 
                    contentPadding: EdgeInsets.zero,
                  ),
                );
              },
            ),
          ),
          
          // --- LISTA ---
          Expanded(
            child: FutureBuilder<List<Medicamento>>(
              future: _inventarioFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Inventario vacío."));
                
                final lista = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: lista.length,
                  itemBuilder: (ctx, i) {
                    final med = lista[i];
                    final alertaVencimiento = _buildVencimientoAlerta(med.fechaVencimiento);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        onLongPress: () => _mostrarAccionesRapidas(med), // Acciones al dejar presionado
                        leading: CircleAvatar(
                          backgroundColor: med.cantidadDisponible <= med.stockMinimo ? Colors.red[100] : Colors.green[100],
                          child: Icon(Icons.medication, color: med.cantidadDisponible <= med.stockMinimo ? Colors.red : Colors.green[800]),
                        ),
                        title: Text("${med.nombre} ${med.concentracion ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${med.presentacion ?? 'Unidad'} • Stock: ${med.cantidadDisponible}"),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(med.fechaVencimiento != null ? "Vence: ${med.fechaVencimiento}" : "Sin vencimiento", style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                            if (alertaVencimiento != null) alertaVencimiento,
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _showRemoveStockDialog(med)),
                             IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: () => _showAddStockDialog(med)),
                             IconButton(
                               icon: const Icon(Icons.delete_sweep, color: Colors.grey), 
                               onPressed: () => _confirmarEliminacion(med),
                               tooltip: "Eliminar registro completo",
                             ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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