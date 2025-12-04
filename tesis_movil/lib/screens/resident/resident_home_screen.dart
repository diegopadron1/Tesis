// resident_home_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

// Importamos tus pantallas de módulos (Las modificaremos en el Paso 3)
import 'motivo_consulta_screen.dart'; 
import 'examen_screen.dart';
import 'antecedentes_screen.dart';
import 'diagnostico_screen.dart';
// import 'register_patient_screen.dart'; // YA NO NECESITAMOS LA PESTAÑA DE REGISTRO AQUÍ

class ResidentHomeScreen extends StatelessWidget {
  // Aceptamos los datos del paciente
  final Map<String, dynamic> pacienteData;

  const ResidentHomeScreen({super.key, required this.pacienteData});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final String cedula = pacienteData['cedula'].toString();

    return DefaultTabController(
      length: 5, // Quitamos "Registrar", quedan 5 módulos
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Módulo Residente'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true, // Importante si hay muchas pestañas
            tabs: [
              Tab(icon: Icon(Icons.note_add), text: "Motivo"),
              Tab(icon: Icon(Icons.accessibility_new), text: "Exámenes"),
              Tab(icon: Icon(Icons.history_edu), text: "Antecedentes"),
              Tab(icon: Icon(Icons.assignment_turned_in), text: "Diagnóstico"),
              Tab(icon: Icon(Icons.monitor_heart), text: "Triaje"),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: Column(
          children: [
            // --- HEADER CON DATOS DEL PACIENTE ---
            _buildPatientHeader(),
            
            // --- PESTAÑAS ---
            Expanded(
              child: TabBarView(
                children: [
                  // Pasamos la cédula a cada módulo
                  MotivoConsultaScreen(cedulaPaciente: cedula), 
                  ExamenScreen(cedulaPaciente: cedula),
                  AntecedentesScreen(cedulaPaciente: cedula),
                  DiagnosticoScreen(cedulaPaciente: cedula),
                  // Placeholder Triaje
                  const Center(child: Text("Módulo de Triaje en construcción")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue[50],
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${pacienteData['nombre'] ?? pacienteData['nombre_apellido']}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
              ),
              Text(
                "C.I: ${pacienteData['cedula']} | Edad: ${pacienteData['edad'] ?? '?'} años",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          )
        ],
      ),
    );
  }
}