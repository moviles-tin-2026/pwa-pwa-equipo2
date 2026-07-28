import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class Sidebar extends StatefulWidget {
  final String currentPage;
  final VoidCallback onDashboardTap;
  final VoidCallback onInventarioTap;
  final VoidCallback onVentasTap;
  final VoidCallback onEstadisticasTap;
  final VoidCallback onEmpleadosTap;
  final VoidCallback onConfiguracionTap;
  final VoidCallback onLogoutTap;
  final bool isMobile;

  const Sidebar({
    super.key,
    required this.currentPage,
    required this.onDashboardTap,
    required this.onInventarioTap,
    required this.onVentasTap,
    required this.onEstadisticasTap,
    required this.onEmpleadosTap,
    required this.onConfiguracionTap,
    required this.onLogoutTap,
    this.isMobile = false,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isExpanded = true;
  final AuthService _authService = AuthService();

  void _toggleSidebar() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    // En móvil, usar Drawer
    if (widget.isMobile) {
      return _buildDrawer();
    }

    // En desktop/tablet, sidebar con animación
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _isExpanded ? 240 : 70,
      color: const Color(0xff362419),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_authService.esAdmin || _authService.esSupervisor)
                    _buildSidebarItem(Icons.dashboard, 'Dashboard', isActive: widget.currentPage == 'dashboard', onTap: widget.onDashboardTap),
                  _buildSidebarItem(Icons.inventory_2, 'Inventario', isActive: widget.currentPage == 'inventario', onTap: widget.onInventarioTap),
                  _buildSidebarItem(Icons.point_of_sale, 'Ventas', isActive: widget.currentPage == 'ventas', onTap: widget.onVentasTap),
                  if (_authService.esSupervisor)
                    _buildSidebarItem(Icons.analytics, 'Estadísticas', isActive: widget.currentPage == 'estadisticas', onTap: widget.onEstadisticasTap),
                  if (_authService.esAdmin)
                    _buildSidebarItem(Icons.people, 'Empleados', isActive: widget.currentPage == 'empleados', onTap: widget.onEmpleadosTap),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Divider(color: Colors.white24, height: 1)),
                  if (_authService.esAdmin)
                    _buildSidebarItem(Icons.settings, 'Configuración', isActive: widget.currentPage == 'configuracion', onTap: widget.onConfiguracionTap),
                ],
              ),
            ),
          ),
          _buildSidebarItem(Icons.logout, 'Cerrar Sesión', isActive: false, onTap: widget.onLogoutTap, isLogout: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Row(
        mainAxisAlignment: _isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
        children: [
          if (_isExpanded)
            Row(
              children: [
                Image.asset('assets/logo1.png', width: 32, height: 32, errorBuilder: (c, e, s) => const Icon(Icons.pets, color: Colors.white, size: 32)),
                const SizedBox(width: 10),
                const Text('Coffee Cat', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            )
          else
            Image.asset('assets/logo1.png', width: 36, height: 36, errorBuilder: (c, e, s) => const Icon(Icons.pets, color: Colors.white, size: 36)),
          if (_isExpanded)
            InkWell(
              onTap: _toggleSidebar,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.chevron_left, color: Color(0xffCFCFCD), size: 22),
              ),
            ),
        ],
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
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Image.asset('assets/logo1.png', width: 40, height: 40, errorBuilder: (c, e, s) => const Icon(Icons.pets, color: Colors.white, size: 40)),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coffee Cat', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Sistema de Gestión', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (_authService.esAdmin || _authService.esSupervisor)
                    _buildDrawerItem(Icons.dashboard, 'Dashboard', isActive: widget.currentPage == 'dashboard', onTap: () {
                      Navigator.pop(context);
                      widget.onDashboardTap();
                    }),
                  _buildDrawerItem(Icons.inventory_2, 'Inventario', isActive: widget.currentPage == 'inventario', onTap: () {
                    Navigator.pop(context);
                    widget.onInventarioTap();
                  }),
                  _buildDrawerItem(Icons.point_of_sale, 'Ventas', isActive: widget.currentPage == 'ventas', onTap: () {
                    Navigator.pop(context);
                    widget.onVentasTap();
                  }),
                  if (_authService.esSupervisor)
                    _buildDrawerItem(Icons.analytics, 'Estadísticas', isActive: widget.currentPage == 'estadisticas', onTap: () {
                      Navigator.pop(context);
                      widget.onEstadisticasTap();
                    }),
                  if (_authService.esAdmin)
                    _buildDrawerItem(Icons.people, 'Empleados', isActive: widget.currentPage == 'empleados', onTap: () {
                      Navigator.pop(context);
                      widget.onEmpleadosTap();
                    }),
                  const Divider(color: Colors.white24),
                  if (_authService.esAdmin)
                    _buildDrawerItem(Icons.settings, 'Configuración', isActive: widget.currentPage == 'configuracion', onTap: () {
                      Navigator.pop(context);
                      widget.onConfiguracionTap();
                    }),
                ],
              ),
            ),
            _buildDrawerItem(Icons.logout, 'Cerrar Sesión', isActive: false, onTap: () {
              Navigator.pop(context);
              widget.onLogoutTap();
            }, isLogout: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {bool isActive = false, VoidCallback? onTap, bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 14 : 0, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xff55453A) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive ? const Border(left: BorderSide(color: Color(0xffCFCFCD), width: 3)) : null,
            ),
            child: _isExpanded
                ? Row(
                    children: [
                      Icon(icon, color: isActive ? Colors.white : (isLogout ? Colors.red[300] : const Color(0xffCFCFCD)), size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isActive ? Colors.white : (isLogout ? Colors.red[300] : const Color(0xffCFCFCD)),
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      icon,
                      color: isActive ? Colors.white : (isLogout ? Colors.red[300] : const Color(0xffCFCFCD)),
                      size: 22,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {bool isActive = false, VoidCallback? onTap, bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isActive ? Colors.white : (isLogout ? Colors.red[300] : const Color(0xffCFCFCD)), size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : (isLogout ? Colors.red[300] : const Color(0xffCFCFCD)),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? const Color(0xff55453A) : Colors.transparent,
      onTap: onTap,
    );
  }
}