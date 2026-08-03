import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  String _rangoSeleccionado = 'Histórico';
  final List<String> _rangos = ['Hoy', 'Esta Semana', 'Este Mes', 'Histórico'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Fondo ligeramente más gris para contrastar las tarjetas blancas
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ENCABEZADO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Estadísticas y Finanzas',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff362419),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Resumen operativo y cuentas por pagar',
                      style: TextStyle(color: Color(0xff55453A), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generando reporte PDF...')),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Exportar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff362419),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),

            // --- FILTROS DE TIEMPO ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _rangos.map((rango) {
                  final isSelected = _rangoSeleccionado == rango;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ChoiceChip(
                      label: Text(rango),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: const Color(0xff362419),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? const Color(0xff362419) : Colors.grey.shade300,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xff55453A),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _rangoSeleccionado = rango;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // --- CUERPO DE DATOS ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('ventas').snapshots(),
                builder: (context, snapshotVentas) {
                  if (!snapshotVentas.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('gastos').snapshots(),
                    builder: (context, snapshotGastos) {
                      if (!snapshotGastos.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final todasLasVentas = snapshotVentas.data!.docs;
                      final todosLosGastos = snapshotGastos.data!.docs;
                      final ahora = DateTime.now();

                      // 1. PROCESAR VENTAS
                      final ventasFiltradas = todasLasVentas.where((venta) {
                        final data = venta.data() as Map<String, dynamic>;
                        if (!data.containsKey('fecha')) return true;
                        return _entraEnFiltro((data['fecha'] as Timestamp).toDate().toLocal(), ahora);
                      }).toList();

                      int totalVentas = ventasFiltradas.length;
                      double totalIngresos = 0;
                      int productosVendidos = 0;
                      Map<String, int> conteoProductos = {};
                      Map<int, double> ingresosPorDia = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

                      for (var venta in ventasFiltradas) {
                        final data = venta.data() as Map<String, dynamic>;
                        double ingresoVenta = (data['total'] ?? 0).toDouble();
                        totalIngresos += ingresoVenta;
                        
                        if (data.containsKey('fecha')) {
                          DateTime fecha = (data['fecha'] as Timestamp).toDate().toLocal();
                          ingresosPorDia[fecha.weekday] = (ingresosPorDia[fecha.weekday] ?? 0) + ingresoVenta;
                        }

                        final productos = data['productos'] as List<dynamic>? ?? [];
                        for (var p in productos) {
                          String nombre = p['nombre'] ?? 'Desconocido';
                          int cantidad = (p['cantidad'] ?? 1) as int;
                          productosVendidos += cantidad;
                          conteoProductos[nombre] = (conteoProductos[nombre] ?? 0) + cantidad;
                        }
                      }

                      // 2. PROCESAR GASTOS Y PAGOS A PROVEEDORES
                      double totalGastosPagados = 0;
                      double cuentasPorPagar = 0;
                      String nombreProximoProveedor = 'Ninguno';
                      String fechaProximoPagoStr = 'Al día';
                      DateTime? fechaMasProxima;
                      
                      // Estructura para almacenar la lista detallada de pagos pendientes
                      List<Map<String, dynamic>> pagosPendientes = [];

                      for (var gasto in todosLosGastos) {
                        final data = gasto.data() as Map<String, dynamic>;
                        final monto = (data['monto'] ?? 0).toDouble();
                        final estado = data['estado'] ?? 'pendiente';
                        final fecha = data.containsKey('fecha') ? (data['fecha'] as Timestamp).toDate().toLocal() : null;
                        final proveedor = data['proveedor'] ?? 'Proveedor Desconocido';

                        if (estado == 'pagado' && fecha != null && _entraEnFiltro(fecha, ahora)) {
                          totalGastosPagados += monto;
                        }

                        if (estado == 'pendiente') {
                          cuentasPorPagar += monto;
                          
                          String fechaStr = fecha != null 
                              ? '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}' 
                              : 'Sin fecha registrada';

                          pagosPendientes.add({
                            'proveedor': proveedor,
                            'monto': monto,
                            'fecha': fecha,
                            'fechaStr': fechaStr,
                          });

                          if (fecha != null && fecha.isAfter(ahora)) {
                            if (fechaMasProxima == null || fecha.isBefore(fechaMasProxima)) {
                              fechaMasProxima = fecha;
                              nombreProximoProveedor = proveedor;
                              fechaProximoPagoStr = fechaStr;
                            }
                          }
                        }
                      }

                      // Ordenar la lista de pendientes por la fecha de vencimiento más cercana
                      pagosPendientes.sort((a, b) {
                        if (a['fecha'] == null) return 1;
                        if (b['fecha'] == null) return -1;
                        return (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime);
                      });

                      double gananciaNeta = totalIngresos - totalGastosPagados;

                      // 3. LOGICA DE RANKINGS
                      var productosOrdenados = conteoProductos.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                      var top5 = productosOrdenados.take(5).toList();
                      
                      var bottom5 = productosOrdenados.length > 5 
                          ? productosOrdenados.skip(5).toList().reversed.take(5).toList() 
                          : <MapEntry<String, int>>[];

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- TARJETAS PRINCIPALES ---
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _buildStatCard(Icons.attach_money_rounded, '\$${totalIngresos.toStringAsFixed(2)}', 'Ingresos Brutos', Colors.green),
                                _buildStatCard(Icons.account_balance_wallet_rounded, '\$${gananciaNeta.toStringAsFixed(2)}', 'Ganancia Neta', gananciaNeta >= 0 ? Colors.blue : Colors.red),
                                _buildStatCard(Icons.shopping_bag_rounded, '$totalVentas', 'Total Ventas', Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // --- PROVEEDORES (TARJETAS BOTÓN) ---
                            Row(
                              children: const [
                                Text('Cuentas por Pagar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff362419))),
                                SizedBox(width: 8),
                                Text('(Haz clic para ver el desglose)', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _buildInsightCard(
                                  icon: Icons.money_off_rounded, 
                                  title: 'Deuda Acumulada', 
                                  value: '\$${cuentasPorPagar.toStringAsFixed(2)}', 
                                  subtitle: 'Total pendiente', 
                                  color: Colors.redAccent,
                                  onTap: () => _mostrarModalPagosPendientes(
                                    context: context,
                                    pagosPendientes: pagosPendientes,
                                    proximaFecha: fechaProximoPagoStr,
                                    totalDeuda: cuentasPorPagar,
                                  ),
                                ),
                                _buildInsightCard(
                                  icon: Icons.local_shipping_rounded, 
                                  title: 'Próximo Pago', 
                                  value: nombreProximoProveedor, 
                                  subtitle: 'Vence: $fechaProximoPagoStr', 
                                  color: Colors.deepPurple,
                                  onTap: () => _mostrarModalPagosPendientes(
                                    context: context,
                                    pagosPendientes: pagosPendientes,
                                    proximaFecha: fechaProximoPagoStr,
                                    totalDeuda: cuentasPorPagar,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // --- GRÁFICA DE BARRAS MODERNIZADA ---
                            const Text('Ingresos por Día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff362419))),
                            const SizedBox(height: 16),
                            Container(
                              height: 300,
                              padding: const EdgeInsets.only(top: 30, right: 20, left: 10, bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: _buildModernBarChart(ingresosPorDia),
                            ),
                            const SizedBox(height: 32),

                            // --- RANKINGS ---
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildRankingList('Más Vendidos', top5, Colors.amber)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildRankingList('Menos Vendidos', bottom5, Colors.redAccent)),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // VENTANA MODAL CENTRADA PARA PAGOS A PROVEEDORES
  void _mostrarModalPagosPendientes({
    required BuildContext context,
    required List<Map<String, dynamic>> pagosPendientes,
    required String proximaFecha,
    required double totalDeuda,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado del Modal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xff362419).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xff362419), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Pagos a Proveedores',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff362419),
                              ),
                            ),
                            Text(
                              'Cuentas por pagar pendientes de liquidación',
                              style: TextStyle(fontSize: 12, color: Color(0xff55453A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.grey.shade600,
                      hoverColor: Colors.grey.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Resumen superior rápido
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Deuda Total', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            '\$${totalDeuda.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.grey.shade300),
                      Column(
                        children: [
                          const Text('Próximo Vencimiento', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            proximaFecha,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff362419)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Detalle de Pagos Pendientes',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff362419)),
                ),
                const SizedBox(height: 12),

                // Lista scrollable de pagos
                Expanded(
                  child: pagosPendientes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green.shade300),
                              const SizedBox(height: 8),
                              const Text('¡Excelente! No tienes pagos pendientes.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: pagosPendientes.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final pago = pagosPendientes[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pago['proveedor'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xff362419),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade600),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Fecha de pago: ${pago['fechaStr']}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Pago pendiente de \$${(pago['monto'] as double).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),

                // Pie del Modal
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xff362419),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _entraEnFiltro(DateTime fecha, DateTime ahora) {
    if (_rangoSeleccionado == 'Hoy') {
      return fecha.day == ahora.day && fecha.month == ahora.month && fecha.year == ahora.year;
    } else if (_rangoSeleccionado == 'Esta Semana') {
      return ahora.difference(fecha).inDays <= 7;
    } else if (_rangoSeleccionado == 'Este Mes') {
      return fecha.month == ahora.month && fecha.year == ahora.year;
    }
    return true;
  }

  // TARJETA DE ESTADÍSTICAS MODERNIZADA
  Widget _buildStatCard(IconData icon, String value, String title, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value, 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xff362419), letterSpacing: -0.5)
                ),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TARJETA DE INSIGHTS CONVERTIDA EN BOTÓN
  Widget _buildInsightCard({
    required IconData icon, 
    required String title, 
    required String value, 
    required String subtitle, 
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 220,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 8),
                      Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color.withValues(alpha: 0.6)),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  // GRÁFICA DE BARRAS MODERNIZADA
  Widget _buildModernBarChart(Map<int, double> ingresosPorDia) {
    double maxY = ingresosPorDia.values.isEmpty ? 1 : ingresosPorDia.values.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 100;
    double chartMaxY = maxY * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMaxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: const Color(0xff362419),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '\$${rod.toY.toStringAsFixed(0)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12);
                String text = '';
                switch (value.toInt()) {
                  case 1: text = 'Lun'; break;
                  case 2: text = 'Mar'; break;
                  case 3: text = 'Mié'; break;
                  case 4: text = 'Jue'; break;
                  case 5: text = 'Vie'; break;
                  case 6: text = 'Sáb'; break;
                  case 7: text = 'Dom'; break;
                }
                return SideTitleWidget(axisSide: meta.axisSide, space: 8, child: Text(text, style: style));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == chartMaxY) return const SizedBox.shrink();
                return Text('\$${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1, dashArray: [5, 5]),
        ),
        borderData: FlBorderData(show: false),
        barGroups: ingresosPorDia.entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: const Color(0xff362419),
                width: 22,
                borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: chartMaxY,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // RANKING LIST MODERNIZADA
  Widget _buildRankingList(String titulo, List<MapEntry<String, int>> datos, Color iconoColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xff362419))),
          const SizedBox(height: 16),
          if (datos.isEmpty) 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('No hay datos suficientes', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
            ),
          ...datos.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: iconoColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Text('${entry.value} un.', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xff55453A))),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}