import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final String currentPage;
  final VoidCallback onDashboardTap;
  final VoidCallback onInventarioTap;
  final VoidCallback onVentasTap;
  final VoidCallback onEstadisticasTap;
  final VoidCallback onEmpleadosTap;
  final VoidCallback onConfiguracionTap;
  final VoidCallback onLogoutTap;

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
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isExpanded = true;

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isExpanded ? 240 : 70,
      color: const Color(0xff362419),
      child: Column(
        children: [
          // HEADER CON LOGO Y FLECHA
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Row(
              mainAxisAlignment: _isExpanded 
                  ? MainAxisAlignment.spaceBetween 
                  : MainAxisAlignment.center,
              children: [
                if (_isExpanded)
                  Row(
                    children: [
                      Image.asset(
                        'assets/logo1.png', 
                        width: 32, 
                        height: 32,
                        errorBuilder: (c, e, s) => const Icon(Icons.pets, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Coffee Cat', 
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  Image.asset(
                    'assets/logo1.png', 
                    width: 36, 
                    height: 36,
                    errorBuilder: (c, e, s) => const Icon(Icons.pets, color: Colors.white, size: 36),
                  ),
                if (_isExpanded)
                  InkWell(
                    onTap: _toggleSidebar,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.chevron_left,
                        color: const Color(0xffCFCFCD),
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (_isExpanded)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Sistema de Gestión', 
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          
          // FLECHA CUANDO ESTÁ COLAPSADO
          if (!_isExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: InkWell(
                onTap: _toggleSidebar,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.chevron_right,
                    color: const Color(0xffCFCFCD),
                    size: 22,
                  ),
                ),
              ),
            ),

          // MENÚ DE NAVEGACIÓN
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSidebarItem(
                    Icons.dashboard, 
                    'Dashboard', 
                    isActive: widget.currentPage == 'dashboard', 
                    onTap: widget.onDashboardTap,
                  ),
                  _buildSidebarItem(
                    Icons.inventory_2, 
                    'Inventario', 
                    isActive: widget.currentPage == 'inventario', 
                    onTap: widget.onInventarioTap,
                  ),
                  _buildSidebarItem(
                    Icons.point_of_sale, 
                    'Ventas', 
                    isActive: widget.currentPage == 'ventas', 
                    onTap: widget.onVentasTap,
                  ),
                  _buildSidebarItem(
                    Icons.analytics, 
                    'Estadísticas', 
                    isActive: widget.currentPage == 'estadisticas', 
                    onTap: widget.onEstadisticasTap,
                  ),
                  _buildSidebarItem(
                    Icons.people, 
                    'Empleados', 
                    isActive: widget.currentPage == 'empleados', 
                    onTap: widget.onEmpleadosTap,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Divider(color: Colors.white24, height: 1),
                  ),
                  _buildSidebarItem(
                    Icons.settings, 
                    'Configuración', 
                    isActive: widget.currentPage == 'configuracion', 
                    onTap: widget.onConfiguracionTap,
                  ),
                ],
              ),
            ),
          ),

          // CERRAR SESIÓN
          _buildSidebarItem(
            Icons.logout, 
            'Cerrar Sesión', 
            isActive: false, 
            onTap: widget.onLogoutTap,
            isLogout: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon, 
    String title, {
    bool isActive = false, 
    VoidCallback? onTap,
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Tooltip(
        message: _isExpanded ? '' : title,
        waitDuration: const Duration(milliseconds: 300),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 14 : 0,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isActive 
                  ? const Color(0xff55453A) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive 
                  ? Border(
                      left: BorderSide(
                        color: const Color(0xffCFCFCD),
                        width: 3,
                      ),
                    ) 
                  : null,
            ),
            child: _isExpanded
                ? Row(
                    children: [
                      Icon(
                        icon, 
                        color: isActive 
                            ? Colors.white 
                            : (isLogout 
                                ? Colors.red[300] 
                                : const Color(0xffCFCFCD)),
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title, 
                          style: TextStyle(
                            color: isActive 
                                ? Colors.white 
                                : (isLogout 
                                    ? Colors.red[300] 
                                    : const Color(0xffCFCFCD)),
                            fontWeight: isActive 
                                ? FontWeight.w600 
                                : FontWeight.normal,
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
                      color: isActive 
                          ? Colors.white 
                          : (isLogout 
                              ? Colors.red[300] 
                              : const Color(0xffCFCFCD)),
                      size: 22,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}