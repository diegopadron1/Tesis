import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'auth/forgot_password_screen.dart'; 
import '../theme_notifier.dart'; // IMPORTANTE: Asegúrate de que este archivo exista

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
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final result = await _authService.signIn(
      cedula: _cedulaController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

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
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: 'Cédula de Identidad (Usuario)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                filled: true,
              ),
              keyboardType: TextInputType.text,
            ),
            
            const SizedBox(height: 20),
            
            // --- CAMPO CONTRASEÑA ---
            TextFormField(
              controller: _passwordController,
              enabled: !_isLoading,
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
      
      // --- NUEVO: BOTÓN DE TEMA EN LA PARTE INFERIOR DERECHA ---
      floatingActionButton: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeNotifier.themeMode,
        builder: (context, mode, _) {
          return FloatingActionButton(
            mini: true, // Lo hace un poco más pequeño y sutil
            tooltip: "Cambiar Tema",
            backgroundColor: mode == ThemeMode.dark ? Colors.amber : Colors.indigo,
            child: Icon(
              mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () => ThemeNotifier.toggleTheme(),
          );
        },
      ),
    );
  }
}