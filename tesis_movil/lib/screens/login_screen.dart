// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
// IMPORTANTE: Importamos la pantalla de recuperación
import 'auth/forgot_password_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _cedulaController = TextEditingController(text: 'V12345678'); // Default Admin
  final _passwordController = TextEditingController(text: 'admin123'); // Default Admin
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
    setState(() {
      _isLoading = true;
    });

    final result = await _authService.signIn(
      cedula: _cedulaController.text,
      password: _passwordController.text,
    );

    if (!mounted) return; // Si el widget ya no está montado, ¡sal inmediatamente!

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      // Si el login es exitoso, navegamos a la pantalla principal
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
        foregroundColor: Colors.white, // Texto blanco en AppBar
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
            TextFormField(
              controller: _cedulaController,
              decoration: const InputDecoration(
                labelText: 'Cédula de Identidad (Usuario)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            
            // --- NUEVO: BOTÓN DE RECUPERACIÓN DE CONTRASEÑA ---
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Navegar a la pantalla de recuperación
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())
                  );
                },
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: Color.fromARGB(255, 62, 2, 129), 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
            // --------------------------------------------------

            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color.fromARGB(255, 62, 2, 129),
                      foregroundColor: Colors.white, // Texto blanco
                    ),
                    child: const Text('INICIAR SESIÓN', style: TextStyle(fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}