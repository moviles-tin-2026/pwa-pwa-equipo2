import 'dart:async'; // ✅ IMPORTANTE: Necesario para StreamSubscription
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/auth_service.dart';

// ============================================================================
// MODELO DE DATOS PARA MÉTRICAS
// ============================================================================
class DashboardMetrics {
  final int totalProductos;
  final int bajoStock;
  final double valorInventario;
  final double ventasHoy;
  final double totalVentasAcumuladas;
  final int transaccionesHoy;
  final Map<int, double> ventasPorDia;
  final List<MapEntry<String, int>> top3Productos;
  final List<Map<String, dynamic>> ultimasVentas;
  final List<Map<String, dynamic>> alertasStock;

  DashboardMetrics({
    required this.totalProductos,
    required this.bajoStock,
    required this.valorInventario,
    required this.ventasHoy,
    required this.totalVentasAcumuladas,
    required this.transaccionesHoy,
    required this.ventasPorDia,
    required this.top3Productos,
    required this.ultimasVentas,
    required this.alertasStock,
  });
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();
  
  // ✅ Listeners independientes
  StreamSubscription<QuerySnapshot>? _productosSub;
  StreamSubscription<QuerySnapshot>? _ventasSub;
  
  List<QueryDocumentSnapshot> _productos = [];
  List<QueryDocumentSnapshot> _ventas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (_authService.usuarioActual == null) {
      _authService.cargarUsuarioActual();
    }

    _productosSub = FirebaseFirestore.instance
        .collection('productos')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _productos = snapshot.docs;
          _isLoading = false;
        });
      }
    });

    _ventasSub = FirebaseFirestore.instance
        .collection('ventas')
        .orderBy('fecha', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _ventas = snapshot.docs;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _productosSub?.cancel();
    _ventasSub?.cancel();
    super.dispose();
  }

  // ✅ Cálculo pesado extraído
  DashboardMetrics _calcularMetricas() {
    int totalProductos = 0;
    int bajoStock = 0;
    double valorInventario = 0.0;
    final alertasStock = <Map<String, dynamic>>[];

    for (var doc in _productos) {
      final data = doc.data() as Map<String, dynamic>;
      final cant = int.tryParse(data['cantidad']?.toString() ?? '0') ?? 0;
      final precio = double.tryParse(data['precio']?.toString() ?? '0.0') ?? 0.0;
      
      totalProductos++;
      valorInventario += (cant * precio);
      
      if (cant <= 5) {
        bajoStock++;
        alertasStock.add({'nombre': data['nombre'] ?? 'Producto', 'cantidad': cant});
      }
    }

    double totalVentasAcumuladas = 0.0;
    double ventasHoy = 0.0;
    int transaccionesHoy = 0;
    final ventasPorDia = {0: 0.0, 1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0, 6: 0.0};
    final conteoProductos = <String, int>{};

    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);

    for (var doc in _ventas) {
      final data = doc.data() as Map<String, dynamic>;
      final total = double.tryParse(data['total']?.toString() ?? '0.0') ?? 0.0;
      totalVentasAcumuladas += total;

      final timestamp = data['fecha'] as Timestamp?;
      if (timestamp != null) {
        final fechaVenta = timestamp.toDate();
        if (fechaVenta.isAfter(inicioHoy)) {
          ventasHoy += total;
          transaccionesHoy++;
        }

        final diferenciaDias = ahora.difference(fechaVenta).inDays;
        if (diferenciaDias >= 0 && diferenciaDias < 7) {
          final indice = 6 - diferenciaDias;
          ventasPorDia[indice] = (ventasPorDia[indice] ?? 0) + total;
        }
      }

      final items = data['items'] ?? data['productos'] ?? [];
      for (var item in items) {
        if (item is Map) {
          final nombre = item['nombre']?.toString() ?? 'Desconocido';
          final cant = int.tryParse(item['cantidad']?.toString() ?? '1') ?? 1;
          conteoProductos[nombre] = (conteoProductos[nombre] ?? 0) + cant;
        }
      }
    }

    final top3Productos = conteoProductos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final ultimasVentas = _ventas.take(5).map((doc) => doc.data() as Map<String, dynamic>).toList();

    return DashboardMetrics(
      totalProductos: totalProductos,
      bajoStock: bajoStock,
      valorInventario: valorInventario,
      ventasHoy: ventasHoy,
      totalVentasAcumuladas: totalVentasAcumuladas,
      transaccionesHoy: transaccionesHoy,
      ventasPorDia: ventasPorDia,
      top3Productos: top3Productos.take(3).toList(),
      ultimasVentas: ultimasVentas,
      alertasStock: alertasStock,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xffCFCFCD),
        body: Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(color: Color(0xff362419), strokeWidth: 3),
          ),
        ),
      );
    }

    final metrics = _calcularMetricas();
    final isSmall = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xffCFCFCD),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isSmall),
            SizedBox(height: isSmall ? 16 : 24),
            _buildKPIs(metrics, isSmall),
            SizedBox(height: isSmall ? 20 : 28),
            _buildCharts(metrics, isSmall),
            SizedBox(height: isSmall ? 20 : 28),
            _buildTables(metrics, isSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Hola, ${_authService.usuarioActual?.nombre ?? "Usuario"}! ☕',
          style: TextStyle(
            fontSize: isSmall ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xff362419),
          ),
        ),
        Text(
          'Rol: ${_authService.usuarioActual?.rolLabel ?? "Sin rol"} | Resumen ejecutivo en tiempo real',
          style: const TextStyle(color: Color(0xff55453A), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildKPIs(DashboardMetrics metrics, bool isSmall) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _DashboardCard(
          icon: Icons.attach_money,
          value: '\$${metrics.ventasHoy.toStringAsFixed(2)}',
          label: 'Ventas de Hoy (${metrics.transaccionesHoy} ped.)',
          color: Colors.green,
          width: isSmall ? double.infinity : 220,
        ),
        _DashboardCard(
          icon: Icons.point_of_sale,
          value: '\$${metrics.totalVentasAcumuladas.toStringAsFixed(2)}',
          label: 'Ingresos (últimas 100 ventas)',
          color: Colors.teal,
          width: isSmall ? double.infinity : 220,
        ),
        _DashboardCard(
          icon: Icons.inventory_2,
          value: '${metrics.totalProductos}',
          label: 'Total Productos',
          color: Colors.blue,
          width: isSmall ? double.infinity : 220,
        ),
        _DashboardCard(
          icon: Icons.warning_amber,
          value: '${metrics.bajoStock}',
          label: 'Productos Bajo Stock',
          color: metrics.bajoStock > 0 ? Colors.red : Colors.orange,
          width: isSmall ? double.infinity : 220,
        ),
        _DashboardCard(
          icon: Icons.account_balance_wallet,
          value: '\$${metrics.valorInventario.toStringAsFixed(2)}',
          label: 'Valor del Inventario',
          color: Colors.purple,
          width: isSmall ? double.infinity : 220,
        ),
      ],
    );
  }

  Widget _buildCharts(DashboardMetrics metrics, bool isSmall) {
    final isWide = MediaQuery.of(context).size.width > 850;
    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _GraficaVentasWidget(ventasPorDia: metrics.ventasPorDia)),
              const SizedBox(width: 16),
              Expanded(child: _TopProductosWidget(top3: metrics.top3Productos)),
            ],
          )
        : Column(
            children: [
              _GraficaVentasWidget(ventasPorDia: metrics.ventasPorDia),
              const SizedBox(height: 16),
              _TopProductosWidget(top3: metrics.top3Productos),
            ],
          );
  }

  Widget _buildTables(DashboardMetrics metrics, bool isSmall) {
    final isWide = MediaQuery.of(context).size.width > 850;
    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _UltimasVentasWidget(ventas: metrics.ultimasVentas)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _AlertasStockWidget(alertas: metrics.alertasStock)),
            ],
          )
        : Column(
            children: [
              _UltimasVentasWidget(ventas: metrics.ultimasVentas),
              const SizedBox(height: 16),
              _AlertasStockWidget(alertas: metrics.alertasStock),
            ],
          );
  }
}

// ============================================================================
// WIDGETS EXTRAÍDOS
// ============================================================================

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final double width;

  const _DashboardCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(18),
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
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff362419)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraficaVentasWidget extends StatelessWidget {
  final Map<int, double> ventasPorDia;

  const _GraficaVentasWidget({required this.ventasPorDia});

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final spots = ventasPorDia.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    const dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas de los Últimos 7 Días',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff362419)),
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final diaIndice = val.toInt().clamp(0, 6);
                          final d = ahora.subtract(Duration(days: 6 - diaIndice));
                          return Text(
                            dias[d.weekday % 7],
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xff362419),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xff362419).withValues(alpha: 0.15),
                      ),
                      dotData: const FlDotData(show: true),
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

class _TopProductosWidget extends StatelessWidget {
  final List<MapEntry<String, int>> top3;

  const _TopProductosWidget({required this.top3});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Productos Vendidos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff362419)),
          ),
          const SizedBox(height: 16),
          if (top3.isEmpty)
            const SizedBox(
              height: 220,
              child: Center(child: Text('Sin datos de ventas registrados aún', style: TextStyle(color: Colors.grey))),
            )
          else
            SizedBox(
              height: 220,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: top3.asMap().entries.map((entry) {
                  final index = entry.key;
                  final producto = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.coffee, color: Color(0xff362419)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(producto.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text('${producto.value} unidades vendidas', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xff55453A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff362419)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _UltimasVentasWidget extends StatelessWidget {
  final List<Map<String, dynamic>> ventas;

  const _UltimasVentasWidget({required this.ventas});

  String _metodoPagoLabel(Map<String, dynamic> data) {
    final metodo = (data['metodoPago'] ?? data['metodo_pago'] ?? 'efectivo').toString().toLowerCase();
    if (metodo == 'tarjeta') return 'Tarjeta';
    if (metodo == 'efectivo') return 'Efectivo';
    return metodo;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimas Transacciones',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff362419)),
          ),
          const SizedBox(height: 12),
          if (ventas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No hay ventas registradas', style: TextStyle(color: Colors.grey))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ventas.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final data = ventas[index];
                final total = double.tryParse(data['total']?.toString() ?? '0') ?? 0;
                final cliente = data['cliente'] ?? data['usuario'] ?? 'Cliente General';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xffCFCFCD),
                    child: Icon(Icons.receipt_long, color: Color(0xff362419)),
                  ),
                  title: Text(cliente.toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(_metodoPagoLabel(data), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AlertasStockWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alertas;

  const _AlertasStockWidget({required this.alertas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Alertas de Reabastecimiento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff362419)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (alertas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text('✅ Todo el stock está en niveles óptimos', style: TextStyle(color: Colors.green, fontSize: 13)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alertas.length,
              itemBuilder: (context, index) {
                final item = alertas[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['nombre'],
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Chip(
                        label: Text('Quedan: ${item['cantidad']}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}