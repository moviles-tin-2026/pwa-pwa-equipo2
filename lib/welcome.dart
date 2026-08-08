import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: _WelcomeContent());
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Stack(
      children: [
        const _OptimizedBackground(),
        const _GradientOverlay(),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _WelcomeCard(isMobile: isMobile),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptimizedBackground extends StatelessWidget {
  const _OptimizedBackground();
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        'assets/welcome.webp',
        fit: BoxFit.cover,
        cacheWidth: 1920,
        cacheHeight: 1080,
        // ✅ CORREGIDO
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}

class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();
  static const LinearGradient _gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x4D000000), Color(0xB3000000)],
  );
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(decoration: const BoxDecoration(gradient: _gradient)),
    );
  }
}

class _WelcomeCard extends StatefulWidget {
  final bool isMobile;
  const _WelcomeCard({required this.isMobile});
  @override
  State<_WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<_WelcomeCard> {
  String? _selectedRole;

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
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LogoWidget(isMobile: isMobile),
          const SizedBox(height: 24),
          const _TitleWidget(),
          const SizedBox(height: 8),
          const _DecorationWidget(),
          const SizedBox(height: 32),
          Text('¿Cómo deseas ingresar?', style: TextStyle(fontSize: isMobile ? 16 : 18, color: const Color(0xff55453A), fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          _RoleSelector(selectedRole: _selectedRole, onRoleSelected: (role) => setState(() => _selectedRole = role)),
          const SizedBox(height: 28),
          _ContinueButton(onPressed: _continuar),
          const SizedBox(height: 16),
          const _FooterText(),
        ],
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  final bool isMobile;
  const _LogoWidget({required this.isMobile});
  @override
  Widget build(BuildContext context) {
    final size = isMobile ? 100.0 : 130.0;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x1A362419), border: Border.all(color: const Color(0xff362419), width: 3)),
      child: ClipOval(
        child: Image.asset(
          'assets/logo1.webp', 
          width: size, height: size, fit: BoxFit.contain, cacheWidth: 260, cacheHeight: 260, 
          // ✅ CORREGIDO
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 70, color: Color(0xff362419))
        ),
      ),
    );
  }
}

class _TitleWidget extends StatelessWidget {
  const _TitleWidget();
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text('¡Bienvenido a', style: TextStyle(fontSize: 22, color: Color(0xff55453A), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        Text('Coffee Cat', style: TextStyle(fontSize: 36, color: Color(0xff362419), fontWeight: FontWeight.bold, letterSpacing: 1), textAlign: TextAlign.center),
      ],
    );
  }
}

class _DecorationWidget extends StatelessWidget {
  const _DecorationWidget();
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 40, height: 1, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xff362419)))),
        SizedBox(width: 12), Icon(Icons.local_cafe, color: Color(0xff362419), size: 24),
        SizedBox(width: 8), Icon(Icons.pets, color: Color(0xff362419), size: 24),
        SizedBox(width: 12), SizedBox(width: 40, height: 1, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xff362419)))),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String? selectedRole;
  final ValueChanged<String?> onRoleSelected;
  const _RoleSelector({required this.selectedRole, required this.onRoleSelected});

  static const List<Map<String, dynamic>> _roles = [
    {'value': 'admin', 'label': 'Administrador', 'icon': Icons.admin_panel_settings, 'color': Color(0xff362419), 'description': 'Acceso total al sistema'},
    {'value': 'supervisor', 'label': 'Supervisor', 'icon': Icons.supervisor_account, 'color': Color(0xff55453A), 'description': 'Gestión de inventario y ventas'},
    {'value': 'vendedor', 'label': 'Vendedor', 'icon': Icons.point_of_sale, 'color': Color(0xff7A6A5E), 'description': 'Registro de ventas'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff362419), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedRole,
        isExpanded: true,
        decoration: const InputDecoration(
          hintText: 'Selecciona tu rol',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.person_outline, color: Color(0xff362419)),
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xff362419)),
        style: const TextStyle(color: Color(0xff362419), fontSize: 16, fontWeight: FontWeight.w500),
        selectedItemBuilder: (BuildContext context) {
          return _roles.map<Widget>((rol) {
            return Text(
              rol['label'] as String,
              style: const TextStyle(color: Color(0xff362419), fontWeight: FontWeight.bold, fontSize: 15),
            );
          }).toList();
        },
        items: _roles.map((rol) {
          return DropdownMenuItem<String>(
            value: rol['value'] as String,
            child: Row(
              children: [
                Icon(rol['icon'] as IconData, color: rol['color'] as Color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(rol['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff362419))),
                      Text(rol['description'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onRoleSelected,
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ContinueButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff362419),
          foregroundColor: const Color(0xffCFCFCD),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          shadowColor: const Color(0x66362419),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_forward, size: 20),
        label: const Text('Continuar al Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  const _FooterText();
  @override
  Widget build(BuildContext context) {
    return const Text('☕ El mejor café con actitud felina ', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic), textAlign: TextAlign.center);
  }
}