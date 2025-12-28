import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'screens/login_screen.dart';
import 'theme_notifier.dart'; // Importa el notifier

void main() {
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(const TesisApp());
}

class TesisApp extends StatelessWidget {
  const TesisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.themeMode,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Emergencia Razetti',
          debugShowCheckedModeBanner: false,
          themeMode: mode, // Escucha el cambio aquí

          // --- TEMA CLARO ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: Colors.indigo,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),

          // --- TEMA OSCURO (Tu diseño actual) ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primarySwatch: Colors.deepPurple,
            scaffoldBackgroundColor: Colors.grey.shade900,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.deepPurple.shade900,
              foregroundColor: Colors.white,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey.shade800,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              labelStyle: const TextStyle(color: Colors.white70),
            ),
          ),

          initialRoute: '/', 
          routes: {'/': (context) => const LoginScreen()},
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('es', 'ES'),
          ],
        );
      },
    );
  }
}