import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../services/historia_service.dart';

import 'resident_home_screen.dart'; 
import 'register_patient_screen.dart';

class PatientSearchScreen extends StatefulWidget {
  const PatientSearchScreen({super.key});

  @override
  State<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends State<PatientSearchScreen> {
  final _cedulaController = TextEditingController();
  final _historiaService = HistoriaService();
  bool _isLoading = false;

  void _buscarPaciente() async {
    final cedula = _cedulaController.text.trim();

    // 1. VALIDACIÓN DE CÉDULA
    if (cedula.isEmpty || cedula.length < 4 || cedula.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error, cédula no válida"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      _cedulaController.clear();
      return; 
    }

    setState(() => _isLoading = true);
    
    try {
      final data = await _historiaService.getHistoriaClinica(cedula);
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (data.isNotEmpty && (data['cedula'] != null || data['cedula_paciente'] != null)) {
        
        // --- VALIDACIÓN DE ESTATUS ---
        String estatus = data['estatus_carpeta'] ?? data['estatus'] ?? 'ABIERTA'; 
        
        // Verificación profunda por si viene anidado
        if (data['carpeta'] != null && data['carpeta']['estatus'] != null) {
           estatus = data['carpeta']['estatus'];
        }

        // SI ESTÁ FALLECIDO -> BLOQUEO TOTAL
        if (estatus.toLowerCase() == 'fallecido') {
          _mostrarErrorBloqueo(data);
        } else {
          // Si está vivo, pasamos al Home
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResidentHomeScreen(pacienteData: data),
            ),
          );
        }

      } else {
        // NO EXISTE -> REGISTRAR
        _irARegistro();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarDialogoNoEncontrado();
    }
  }

  // --- NUEVA ALERTA DE BLOQUEO (ERROR) ---
  void _mostrarErrorBloqueo(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.block, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text("ACCESO DENEGADO", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "El paciente ${data['nombre_apellido'] ?? 'seleccionado'} se encuentra registrado como FALLECIDO.",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),
            const Text(
              "No se pueden realizar nuevas acciones sobre este expediente.",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800], 
                foregroundColor: Colors.white
              ),
              onPressed: () {
                Navigator.pop(ctx); // Cierra el diálogo
                _cedulaController.clear(); // Limpia el campo para pedir otra cédula
              },
              child: const Text("Entendido"),
            ),
          ),
        ],
      ),
    );
  }

  void _irARegistro() {
    String cedulaAPasar = _cedulaController.text;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPatientScreen(cedulaPrevia: cedulaAPasar),
      ),
    );
  }

  void _mostrarDialogoNoEncontrado() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Paciente no encontrado"),
        content: Text("La cédula ${_cedulaController.text} no está registrada. ¿Desea registrar al paciente?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _irARegistro();
            },
            child: const Text("Registrar Nuevo"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Pacientes")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_search, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 20),
            const Text(
              "Ingrese la Cédula del Paciente para acceder a su Historia, Diagnósticos y Exámenes", 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 16)
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _cedulaController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
              decoration: const InputDecoration(
                labelText: "Cédula de Identidad",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _buscarPaciente,
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                  : const Icon(Icons.search),
                label: Text(_isLoading ? "Buscando..." : "Gestionar Paciente"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800], 
                  foregroundColor: Colors.white
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}