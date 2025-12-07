import 'package:flutter/material.dart';
import '../../services/password_recovery_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // 1. Agregamos el controlador para el correo
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _service = PasswordRecoveryService();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _cambiarPassword() async {
    // Validamos que los 3 campos tengan datos
    if (_emailController.text.isEmpty || 
        _codeController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Todos los campos son obligatorios"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await _service.resetPassword(
      _codeController.text.trim(), 
      _passwordController.text.trim()
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success']) {
      // Éxito: Volver al Login
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("¡Éxito!"),
          content: const Text("Tu contraseña ha sido actualizada correctamente."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Cerrar diálogo
                // Volver al Login
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              child: const Text("Ir al Login"),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Confirma tu correo, ingresa el código recibido y tu nueva contraseña.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            
            // --- NUEVO CAMPO: CORREO ELECTRÓNICO ---
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Correo Electrónico",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),
            // ----------------------------------------

            // Campo Código
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "Código de Recuperación",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 20),

            // Campo Nueva Contraseña
            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: "Nueva Contraseña",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _cambiarPassword,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Actualizar Contraseña"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}