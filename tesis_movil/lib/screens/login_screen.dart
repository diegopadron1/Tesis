// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'auth/forgot_password_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _cedulaController = TextEditingController(text: 'V12345678'); 
  final _passwordController = TextEditingController(text: 'admin123'); 
  final _authService = AuthService();
  bool _isLoading = false;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error de Autenticación'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    // 1. Bloqueamos los campos y mostramos el indicador de carga
    setState(() {
      _isLoading = true;
    });

    final result = await _authService.signIn(
      cedula: _cedulaController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    // 2. Quitamos el bloqueo (esto solo será visible si hay error, 
    //    si es éxito cambiamos de pantalla rápido)
    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      _showErrorDialog(result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergencia Razetti - Login'),
        backgroundColor: const Color.fromARGB(255, 62, 2, 129),
        foregroundColor: Colors.white, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Sistema de Emergencia',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            
            // --- CAMPO CÉDULA ---
            TextFormField(
              controller: _cedulaController,
              // AQUÍ ESTÁ EL CAMBIO:
              enabled: !_isLoading, // Se deshabilita si está cargando
              decoration: const InputDecoration(
                labelText: 'Cédula de Identidad (Usuario)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                filled: true, // Opcional: para resaltar el fondo gris
              ),
              keyboardType: TextInputType.text,
            ),
            
            const SizedBox(height: 20),
            
            // --- CAMPO CONTRASEÑA ---
            TextFormField(
              controller: _passwordController,
              // AQUÍ ESTÁ EL CAMBIO:
              enabled: !_isLoading, // Se deshabilita si está cargando
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                filled: true,
              ),
              obscureText: true,
            ),
            
            // --- BOTÓN OLVIDASTE CONTRASEÑA ---
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                // AQUÍ ESTÁ EL CAMBIO: Si carga, el botón no hace nada (null)
                onPressed: _isLoading 
                    ? null 
                    : () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())
                        );
                      },
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: _isLoading ? Colors.grey : const Color.fromARGB(255, 62, 2, 129), 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color.fromARGB(255, 62, 2, 129),
                      foregroundColor: Colors.white, 
                    ),
                    child: const Text('INICIAR SESIÓN', style: TextStyle(fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}