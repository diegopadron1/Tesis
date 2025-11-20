import 'package:flutter/material.dart';
// Importa la pantalla de registro que ya creamos
import 'register_patient_screen.dart'; 
import 'motivo_consulta_screen.dart'; 
import 'diagnostico_screen.dart';
// Importa el servicio de autenticación si necesitas el botón de cerrar sesión
import '../../services/auth_service.dart'; 
import '../login_screen.dart'; 

class ResidentHomeScreen extends StatelessWidget {
  const ResidentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos el AuthService para cerrar sesión
    final AuthService authService = AuthService();

    return DefaultTabController(
      length: 4, // cuatro pestañas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Módulo Residente'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 5,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar Sesión',
              onPressed: () async {
                await authService.signOut();
                // Navegar de vuelta a la pantalla de login
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
          // Pestañas de navegación
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_add), text: "Registrar Paciente"),
              Tab(icon: Icon(Icons.note_add), text: "Motivo"),
              Tab(icon: Icon(Icons.assignment_turned_in), text: "Diagnóstico"),
              Tab(icon: Icon(Icons.monitor_heart), text: "Triaje (Pendiente)"),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: const TabBarView(
          children: [
            // **AQUÍ SE MUESTRA LA INTERFAZ DE REGISTRO**
            RegisterPatientScreen(),
            MotivoConsultaScreen(), 
            DiagnosticoScreen(),
            
            // Placeholder para la futura pantalla de Triaje
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_heart, size: 80, color: Colors.blueGrey),
                  SizedBox(height: 10),
                  Text(
                    'Aquí irá el Módulo de Triaje',
                    style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                  ),
                  Text('Necesitamos crear el backend y frontend para esto.', textAlign: TextAlign.center,),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}