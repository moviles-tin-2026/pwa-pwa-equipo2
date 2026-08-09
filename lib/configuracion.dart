import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  final AuthService _authService = AuthService();
  bool _notificaciones = true;
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    if (_authService.usuarioActual == null) {
      await _authService.cargarUsuarioActual();
    }
    if (mounted) {
      setState(() {
        _notificaciones = _authService.usuarioActual?.notificaciones ?? true;
        _cargando = false;
      });
    }
  }

  Future<void> _guardarNotificaciones(bool value) async {
    setState(() {
      _notificaciones = value;
      _guardando = true;
    });
    try {
      await _authService.actualizarPreferencias(notificaciones: value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferencias guardadas'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _notificaciones = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;
    await _authService.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _authService.usuarioActual;
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xff362419)),
      );
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            children: [
              const _PageHeader(),
              const SizedBox(height: 20),
              _ProfileCard(usuario: usuario),
              const SizedBox(height: 16),
              _SettingsCard(
                notificaciones: _notificaciones,
                guardando: _guardando,
                onChanged: _guardarNotificaciones,
              ),
              const SizedBox(height: 16),
              _AboutCard(onLogout: _cerrarSesion),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGETS EXTRAÍDOS
// ============================================================================

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '️ Configuración',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xff362419),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Coffee Cat - Ajustes del sistema',
          style: TextStyle(color: Color(0xff55453A), fontSize: 12),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic usuario;

  const _ProfileCard({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final inicial = (usuario?.nombre?.isNotEmpty ?? false) 
        ? usuario!.nombre[0].toUpperCase() 
        : '?';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0x1A362419),
              child: Text(
                inicial,
                style: const TextStyle(color: Color(0xff362419), fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              usuario?.nombre ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${usuario?.email ?? ''}\nRol: ${usuario?.rolLabel ?? ''}',
            ),
            isThreeLine: true,
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool notificaciones;
  final bool guardando;
  final ValueChanged<bool> onChanged;

  const _SettingsCard({
    required this.notificaciones,
    required this.guardando,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: Color(0xff362419)),
            title: const Text('Notificaciones'),
            subtitle: const Text('Recibir alertas de bajo stock'),
            value: notificaciones,
            activeThumbColor: const Color(0xff362419), // ✅ CORREGIDO: activeThumbColor en lugar de activeColor
            onChanged: guardando ? null : onChanged,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette, color: Color(0xff362419)),
            title: const Text('Tema'),
            subtitle: const Text('Personalizar apariencia'),
            trailing: const Text('Claro'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tema oscuro próximamente'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final VoidCallback onLogout;

  const _AboutCard({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info, color: Color(0xff362419)),
            title: Text('Acerca de'),
            subtitle: Text('Coffee Cat v1.0.0'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}