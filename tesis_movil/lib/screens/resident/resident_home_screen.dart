import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

// Importamos tus pantallas de módulos
import 'motivo_consulta_screen.dart'; 
import 'examen_screen.dart';
import 'antecedentes_screen.dart';
import 'diagnostico_screen.dart';

class ResidentHomeScreen extends StatelessWidget {
  final Map<String, dynamic> pacienteData;

  const ResidentHomeScreen({super.key, required this.pacienteData});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final String cedula = pacienteData['cedula'].toString();
    
    // --- LÓGICA DE BLOQUEO ---
    // Detectamos el rol que viene desde HomeScreen
    final String rol = pacienteData['rol'] ?? 'Residente';
    final bool esSoloLectura = rol == 'Especialista';

    return DefaultTabController(
      length: 4, 
      child: Scaffold(
        appBar: AppBar(
          // Título dinámico según el rol
          title: Text(esSoloLectura ? 'Consulta de Especialista' : 'Módulo Residente'),
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
            isScrollable: false,
            labelPadding: EdgeInsets.zero,
            labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.note_add), text: "Motivo y Triaje"),
              Tab(icon: Icon(Icons.accessibility_new), text: "Exámenes"),
              Tab(icon: Icon(Icons.history_edu), text: "Antecedentes"),
              Tab(icon: Icon(Icons.assignment_turned_in), text: "Diagnóstico"),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: Column(
          children: [
            _buildPatientHeader(),
            Expanded(
              child: TabBarView(
                children: [
                  // PASAMOS readOnly A CADA SCREEN PARA OCULTAR BOTONES
                  MotivoConsultaScreen(cedulaPaciente: cedula, readOnly: esSoloLectura), 
                  ExamenScreen(cedulaPaciente: cedula, readOnly: esSoloLectura),
                  AntecedentesScreen(cedulaPaciente: cedula, readOnly: esSoloLectura),
                  DiagnosticoScreen(cedulaPaciente: cedula, readOnly: esSoloLectura),
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