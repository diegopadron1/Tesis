import 'package:flutter/material.dart';
// 1. IMPORTANTE: Esta librería es obligatoria para el calendario
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(const TesisApp());
}

class TesisApp extends StatelessWidget {
  const TesisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergencia Razetti',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple.shade900,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey.shade900,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade800,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey.shade400),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
      ),

      // RUTAS
      initialRoute: '/', 
      routes: {
        '/': (context) => const LoginScreen(),
      },

      // --- AQUÍ ESTÁ LA SOLUCIÓN DEL ERROR ---
      // Sin esto, el DatePicker en español hace que la app falle
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // Inglés
        Locale('es', 'ES'), // Español (El que estás pidiendo)
      ],
      // ----------------------------------------
    );
  }
}