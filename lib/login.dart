import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard.dart';

// NOTA: Se eliminaron main() y MyApp porque ya están en main.dart

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ingreso exitoso',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color(0xff362419),
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al iniciar sesión';
      if (e.code == 'user-not-found') {
        mensaje = 'Usuario no encontrado';
      } else if (e.code == 'wrong-password') {
        mensaje = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-email') {
        mensaje = 'Correo inválido';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje, textAlign: TextAlign.center),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color inputFillColor = Colors.white.withValues(alpha: 0.4);
    const Color brandColor = Color(0xff55453A);

    return Scaffold(
      body: Stack(
        children: [
          // 1. CAPA TRASERA: Imagen de fondo a pantalla completa
          Positioned.fill(
            child: Image.asset('assets/kitback.jpg', fit: BoxFit.cover),
          ),

          // 2. CAPA DELANTERA: Contenido del Login
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo1.png',
                      width: 130,
                      height: 130,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.pets,
                          size: 100,
                          color: Color(0xff362419),
                        );
                      },
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Bienvenido a Coffee Cat',
                      style: TextStyle(
                        color: Color(0xff362419),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Inventario General',
                      style: TextStyle(
                        color: brandColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Campo 1: Correo electrónico
                          Container(
                            decoration: BoxDecoration(
                              color: inputFillColor,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu correo';
                                }
                                if (!value.contains('@')) {
                                  return 'El correo debe incluir un @';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Correo electrónico',
                                labelStyle: const TextStyle(
                                  color: brandColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email,
                                  color: brandColor,
                                ),
                                filled: false,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                    color: brandColor,
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                    color: brandColor,
                                    width: 2.0,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                errorStyle: TextStyle(
                                  color: Colors.red[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),

                          // Campo 2: Contraseña
                          Container(
                            decoration: BoxDecoration(
                              color: inputFillColor,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              maxLength: 25,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu contraseña';
                                }
                                if (value.length < 6) {
                                  return 'Debe tener mínimo 6 caracteres';
                                }
                                if (value.length > 25) {
                                  return 'Debe tener máximo 25 caracteres';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                labelStyle: const TextStyle(
                                  color: brandColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: brandColor,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: brandColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: false,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                    color: brandColor,
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                    color: brandColor,
                                    width: 2.0,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                counterText: '',
                                errorStyle: TextStyle(
                                  color: Colors.red[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),

                          GestureDetector(
                            onTap: () {
                              // Acción para recuperar contraseña
                            },
                            child: const Text(
                              'Olvidé mi contraseña',
                              style: TextStyle(
                                color: brandColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28.0),

                          SizedBox(
                            width: double.infinity,
                            height: 50.0,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff362419),
                                foregroundColor: const Color(0xffCFCFCD),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                elevation: 4,
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Color(0xffCFCFCD),
                                    )
                                  : const Text(
                                      'Ingresar',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
