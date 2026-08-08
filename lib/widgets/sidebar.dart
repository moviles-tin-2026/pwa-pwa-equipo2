import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../utils/optimized_image.dart';

class SimpleSidebar extends StatefulWidget {
  final bool isMobile;

  const SimpleSidebar({
    super.key,
    this.isMobile = false,
  });

  @override
  State<SimpleSidebar> createState() => _SimpleSidebarState();
}

class _SimpleSidebarState extends State<SimpleSidebar> {
  bool _isExpanded = true;
  final AuthService _authService = AuthService();

  void _toggle() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) return _buildDrawer();

    final double width = _isExpanded ? 240 : 72;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      color: const Color(0xff362419),
      child: ClipRect(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _menuItems(isDrawer: false),
              ),
            ),
            _buildLogout(isDrawer: false),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: _isExpanded
            ? Row(
                children: [
                  OptimizedAssetImage(
                    asset: 'assets/logo1.webp',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.pets, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Coffee Cat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Color(0xffCFCFCD)),
                    onPressed: _toggle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              )
            : Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xffCFCFCD)),
                  onPressed: _toggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xff362419),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              // 💡 CORREGIDO: Se eliminó la propiedad duplicada 'paddingHorizontal'
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  OptimizedAssetImage(
                    asset: 'assets/logo1.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.pets, color: Colors.white, size: 40),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Coffee Cat',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text('Sistema de Gestión',
                            style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _menuItems(isDrawer: true),
              ),
            ),
            _buildLogout(isDrawer: true),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool active,
    required VoidCallback onTap,
    required bool isDrawer,
    bool isLogout = false,
  }) {
    final Color itemColor =
        active ? Colors.white : (isLogout ? Colors.red[300]! : const Color(0xffCFCFCD));

    if (isDrawer) {
      return ListTile(
        leading: Icon(icon, color: itemColor),
        title: Text(title,
            style: TextStyle(
                color: itemColor, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
        tileColor: active ? const Color(0xff55453A) : Colors.transparent,
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        dense: true,
      );
    }

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xff55453A) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: (active && _isExpanded)
            ? const Border(left: BorderSide(color: Color(0xffCFCFCD), width: 3))
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: _isExpanded
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(icon, color: itemColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: itemColor,
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Icon(icon, color: itemColor, size: 20),
              ),
      ),
    );
  }

  List<Widget> _menuItems({required bool isDrawer}) {
    final List<Widget> items = [];
    final String currentRoute = GoRouterState.of(context).matchedLocation;

    void add(IconData icon, String title, String routePath, {bool isLogout = false}) {
      final bool isActive = routePath == '/'
          ? currentRoute == '/'
          : currentRoute.startsWith(routePath);

      items.add(_buildMenuItem(
        icon: icon,
        title: title,
        active: isActive,
        onTap: () => context.go(routePath),
        isDrawer: isDrawer,
        isLogout: isLogout,
      ));
    }

    // 1. Dashboard (Solo Admin y Supervisor)
    if (_authService.esAdmin || _authService.esSupervisor) {
      add(Icons.dashboard, 'Dashboard', '/');
    }

    // 2. Inventario y Ventas (Todos los roles)
    add(Icons.inventory_2, 'Inventario', '/inventario');
    add(Icons.point_of_sale, 'Ventas', '/ventas');

    // 3. Estadísticas (Admin y Supervisor)
    if (_authService.esAdmin || _authService.esSupervisor) {
      add(Icons.analytics, 'Estadísticas', '/estadisticas');
    }

    // 4. Empleados y Configuración (Solo Admin)
    if (_authService.esAdmin) {
      items.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Divider(color: Colors.white24),
      ));
      add(Icons.people, 'Empleados', '/empleados');
      add(Icons.settings, 'Configuración', '/configuracion');
    }

    return items;
  }

  Widget _buildLogout({required bool isDrawer}) {
    return _buildMenuItem(
      icon: Icons.logout,
      title: 'Cerrar Sesión',
      active: false,
      onTap: () async {
        await _authService.logout();
        // 💡 CORREGIDO: Verificación limpia de context montado
        if (!mounted) return;
        context.go('/login');
      },
      isDrawer: isDrawer,
      isLogout: true,
    );
  }
}