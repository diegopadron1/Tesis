import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import necesario para FilteringTextInputFormatter
// Corregimos las rutas: Retrocedemos 2 niveles (../../) para llegar a lib/
import '../../services/historia_service.dart';
// Estas están en la misma carpeta, así que no llevan ruta, solo el nombre
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
    // Si está vacía O tiene una longitud inválida (menos de 4 o más de 15)
    if (cedula.isEmpty || cedula.length < 4 || cedula.length > 15) {
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error, cedula no valida"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Borrar la cédula escrita anteriormente
      _cedulaController.clear();
      return; // Detener la ejecución aquí
    }

    setState(() => _isLoading = true);
    
    try {
      // Usamos el servicio para ver si el paciente existe
      final data = await _historiaService.getHistoriaClinica(cedula);
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Verificamos si la data no está vacía y tiene una cédula válida
      if (data.isNotEmpty && data['cedula'] != null) {
        // CASO 1: EXISTE -> Vamos al menú de módulos
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResidentHomeScreen(pacienteData: data),
          ),
        );
      } else {
        // CASO 2: RESPUESTA VACÍA -> Sugerimos registrar
        _irARegistro();
      }
    } catch (e) {
      // Si ocurre un error (ej. 404), asumimos que no existe
      setState(() => _isLoading = false);
      _mostrarDialogoNoEncontrado();
    }
  }

  void _irARegistro() {
    // Guardamos el texto antes de navegar por si quieres pasarlo, 
    // aunque si falló la validación estricta arriba, aquí pasará una cédula válida.
    String cedulaAPasar = _cedulaController.text;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        // Enviamos la cédula que el usuario escribió para que no tenga que repetirla
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
              // --- NUEVA RESTRICCIÓN AGREGADA ---
              // Esto asegura que el usuario SOLO pueda escribir dígitos (0-9)
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
              // ----------------------------------
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