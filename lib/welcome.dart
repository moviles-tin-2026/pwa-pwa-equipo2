import 'package:flutter/material.dart';
import 'login.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  String? _selectedRole;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _roles = [
    {
      'value': 'admin',
      'label': 'Administrador',
      'icon': Icons.admin_panel_settings,
      'color': const Color(0xff362419),
      'description': 'Acceso total al sistema',
    },
    {
      'value': 'supervisor',
      'label': 'Supervisor',
      'icon': Icons.supervisor_account,
      'color': const Color(0xff55453A),
      'description': 'Gestión de inventario y ventas',
    },
    {
      'value': 'vendedor',
      'label': 'Vendedor',
      'icon': Icons.point_of_sale,
      'color': const Color(0xff7A6A5E),
      'description': 'Registro de ventas',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _continuar() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un rol para continuar', textAlign: TextAlign.center),
          backgroundColor: Color(0xff362419),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con imagen
          Positioned.fill(
            child: Image.asset(
              'assets/kitback.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Overlay oscuro para mejorar legibilidad
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: EdgeInsets.all(isMobile ? 24 : 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo animado
                          Container(
                            width: isMobile ? 100 : 130,
                            height: isMobile ? 100 : 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xff362419).withValues(alpha: 0.1),
                              border: Border.all(color: const Color(0xff362419), width: 3),
                            ),
                            child: Image.asset(
                              'assets/logo1.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.pets, size: 70, color: Color(0xff362419));
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Título principal
                          Text(
                            '¡Bienvenido a',
                            style: TextStyle(
                              fontSize: isMobile ? 22 : 28,
                              color: const Color(0xff55453A),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Coffee Cat',
                            style: TextStyle(
                              fontSize: isMobile ? 36 : 48,
                              color: const Color(0xff362419),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Decoración con íconos de café y gato
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 1,
                                color: const Color(0xff362419),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.local_cafe, color: Color(0xff362419), size: 24),
                              const SizedBox(width: 8),
                              const Icon(Icons.pets, color: Color(0xff362419), size: 24),
                              const SizedBox(width: 12),
                              Container(
                                width: 40,
                                height: 1,
                                color: const Color(0xff362419),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Pregunta
                          Text(
                            '¿Cómo deseas ingresar?',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              color: const Color(0xff55453A),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // Menú desplegable de roles
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xff362419), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonFormField<String>(
                              // CORRECCIÓN: initialValue en lugar de value
                              initialValue: _selectedRole,
                              decoration: InputDecoration(
                                hintText: 'Selecciona tu rol',
                                hintStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.person_outline, color: Color(0xff362419)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              dropdownColor: Colors.white,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xff362419)),
                              style: const TextStyle(
                                color: Color(0xff362419),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              items: _roles.map((rol) {
                                return DropdownMenuItem<String>(
                                  value: rol['value'] as String,
                                  child: Row(
                                    children: [
                                      Icon(rol['icon'] as IconData, color: rol['color'] as Color, size: 20),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            rol['label'] as String,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            rol['description'] as String,
                                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Botón continuar
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff362419),
                                foregroundColor: const Color(0xffCFCFCD),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                                shadowColor: const Color(0xff362419).withValues(alpha: 0.4),
                              ),
                              onPressed: _continuar,
                              icon: const Icon(Icons.arrow_forward, size: 20),
                              label: const Text(
                                'Continuar al Login',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Texto decorativo inferior
                          Text(
                            '☕ El mejor café con actitud felina 🐱',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}