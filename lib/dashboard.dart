import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/sidebar.dart';
import 'login.dart';
import 'inventario.dart';
import 'ventas.dart';
import 'estadisticas.dart';
import 'empleados.dart';
import 'configuracion.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _currentPage = 'dashboard';

  void _navigateToPage(String page) {
    setState(() => _currentPage = page);
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case 'dashboard': return _buildDashboardContent();
      case 'inventario': return const InventarioPage();
      case 'ventas': return const VentasPage();
      case 'estadisticas': return const EstadisticasPage();
      case 'empleados': return const EmpleadosPage();
      case 'configuracion': return const ConfiguracionPage();
      default: return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard ',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff362419)),
          ),
          const Text(
            'Coffee Cat - Resumen General',
            style: TextStyle(color: Color(0xff55453A), fontSize: 12),
          ),
          const SizedBox(height: 20),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('productos').snapshots(),
            builder: (context, snapshot) {
              int totalProductos = 0;
              int bajoStock = 0;
              double valorTotal = 0;

              if (snapshot.hasData) {
                var todosLosDocs = snapshot.data!.docs;
                totalProductos = todosLosDocs.length;
                for (var doc in todosLosDocs) {
                  final d = doc.data() as Map<String, dynamic>?;
                  if (d == null) continue;
                  int cant = int.tryParse(d['cantidad']?.toString() ?? '0') ?? 0;
                  double precio = double.tryParse(d['precio']?.toString() ?? '0.0') ?? 0.0;
                  valorTotal += (cant * precio);
                  if (cant <= 5) bajoStock++;
                }
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSummaryCard(Icons.inventory_2, '$totalProductos', 'Total Productos', Colors.blue, onTap: () => _navigateToPage('inventario')),
                  _buildSummaryCard(Icons.warning_amber, '$bajoStock', 'Bajo Stock', Colors.red, onTap: () => _navigateToPage('inventario')),
                  _buildSummaryCard(Icons.point_of_sale, '0', 'Ventas Hoy', Colors.green, onTap: () => _navigateToPage('ventas')),
                  _buildSummaryCard(Icons.attach_money, '\$${valorTotal.toStringAsFixed(2)}', 'Valor Inventario', Colors.orange),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.coffee, size: 80, color: const Color(0xff362419)),
                    const SizedBox(height: 16),
                    const Text(
                      '¡Bienvenido a Coffee Cat!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff362419)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecciona una opción del menú lateral',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
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

  Widget _buildSummaryCard(IconData icon, String value, String title, Color color, {VoidCallback? onTap}) {
    return SizedBox(
      width: 200,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff362419)),
                      ),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffCFCFCD),
      body: Row(
        children: [
          Sidebar(
            currentPage: _currentPage,
            onDashboardTap: () => _navigateToPage('dashboard'),
            onInventarioTap: () => _navigateToPage('inventario'),
            onVentasTap: () => _navigateToPage('ventas'),
            onEstadisticasTap: () => _navigateToPage('estadisticas'),
            onEmpleadosTap: () => _navigateToPage('empleados'),
            onConfiguracionTap: () => _navigateToPage('configuracion'),
            onLogoutTap: _cerrarSesion,
          ),
          Expanded(child: _buildCurrentPage()),
        ],
      ),
    );
  }
}