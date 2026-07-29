import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/sidebar.dart';
import 'inventario.dart';
import 'ventas.dart';
import 'empleados.dart';
import 'configuracion.dart';
import 'estadisticas.dart';
import 'services/auth_service.dart';
import 'login.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _currentPage = 'dashboard';
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _redirigirSegunRol();
  }

  void _redirigirSegunRol() {
    // Vendedor va directo a Ventas
    if (_authService.esVendedor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentPage = 'ventas');
      });
    }
  }

  void _navigateTo(String page) {
    setState(() => _currentPage = page);
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? SimpleSidebar(
              currentPage: _currentPage,
              onDashboardTap: () => _navigateTo('dashboard'),
              onInventarioTap: () => _navigateTo('inventario'),
              onVentasTap: () => _navigateTo('ventas'),
              onEstadisticasTap: () => _navigateTo('estadisticas'),
              onEmpleadosTap: () => _navigateTo('empleados'),
              onConfiguracionTap: () => _navigateTo('configuracion'),
              onLogoutTap: _logout,
              isMobile: true,
            )
          : null,
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xff362419),
              foregroundColor: Colors.white,
              title: const Text('Coffee Cat'),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            SimpleSidebar(
              currentPage: _currentPage,
              onDashboardTap: () => _navigateTo('dashboard'),
              onInventarioTap: () => _navigateTo('inventario'),
              onVentasTap: () => _navigateTo('ventas'),
              onEstadisticasTap: () => _navigateTo('estadisticas'),
              onEmpleadosTap: () => _navigateTo('empleados'),
              onConfiguracionTap: () => _navigateTo('configuracion'),
              onLogoutTap: _logout,
              isMobile: false,
            ),
          Expanded(
            child: _buildPageContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_currentPage) {
      case 'inventario':
        // ✅ CORREGIDO: Se cambió InventarioPage por InventarioScreen
        return const InventarioScreen();
      case 'ventas':
        return const VentasPage();
      case 'empleados':
        return const EmpleadosPage();
      case 'configuracion':
        return const ConfiguracionPage();
      case 'estadisticas':
        return const EstadisticasPage();
      case 'dashboard':
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Scaffold(
      backgroundColor: const Color(0xffCFCFCD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isSmall = constraints.maxWidth < 600;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: isSmall ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff362419),
                  ),
                ),
                const Text(
                  'Coffee Cat - Resumen General',
                  style: TextStyle(color: Color(0xff55453A), fontSize: 14),
                ),
                SizedBox(height: isSmall ? 16 : 24),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('productos').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    int totalProductos = snapshot.data!.docs.length;
                    int bajoStock = 0;
                    double valorInventario = 0;

                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      int cant = int.tryParse(data['cantidad']?.toString() ?? '0') ?? 0;
                      double precio = double.tryParse(data['precio']?.toString() ?? '0.0') ?? 0.0;

                      if (cant <= 5) bajoStock++;
                      valorInventario += (cant * precio);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildCard(
                              Icons.inventory_2,
                              '$totalProductos',
                              'Total Productos',
                              Colors.blue,
                              width: isSmall ? double.infinity : 220,
                            ),
                            _buildCard(
                              Icons.warning_amber,
                              '$bajoStock',
                              'Bajo Stock',
                              Colors.red,
                              width: isSmall ? double.infinity : 220,
                            ),
                            _buildCard(
                              Icons.attach_money,
                              '\$${valorInventario.toStringAsFixed(2)}',
                              'Valor Inventario',
                              Colors.green,
                              width: isSmall ? double.infinity : 220,
                            ),
                          ],
                        ),
                        SizedBox(height: isSmall ? 24 : 32),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: isSmall ? 32 : 48,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_cafe,
                                size: isSmall ? 60 : 80,
                                color: const Color(0xff362419),
                              ),
                              SizedBox(height: isSmall ? 12 : 16),
                              Text(
                                '¡Hola, ${_authService.usuarioActual?.nombre ?? 'Usuario'}!',
                                style: TextStyle(
                                  fontSize: isSmall ? 18 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xff362419),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rol: ${_authService.rolActual ?? "Sin rol"}',
                                style: TextStyle(
                                  fontSize: isSmall ? 12 : 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(IconData icon, String value, String label, Color color, {double width = 220}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff362419),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}