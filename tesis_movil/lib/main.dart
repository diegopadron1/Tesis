import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  // Asegura que las dependencias de Flutter puedan ser usadas antes de runApp
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(const TesisApp());
}

class TesisApp extends StatelessWidget {
  const TesisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergencia Razetti',
      theme: ThemeData(
        // 1. Color de acento primario (Morado)
        primarySwatch: Colors.deepPurple,
        // 2. Fondo oscuro (Tema Dark)
        brightness: Brightness.dark,
        // 3. Color del fondo de la AppBar (ej. un morado más oscuro)
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple.shade900,
          foregroundColor: Colors.white, // Letras blancas en el AppBar
      ),
      // 4. Color de fondo general (oscuro)
        scaffoldBackgroundColor: Colors.grey.shade900,
      // 5. Tema de texto por defecto (será blanco en el tema oscuro)
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white, // Color del texto del cuerpo
          displayColor: Colors.white,
      ),
      ),
      home: const LoginScreen(),
    );
  }
}