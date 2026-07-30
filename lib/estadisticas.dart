import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // Nueva importación para la gráfica

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
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ENCABEZADO Y BOTÓN DE EXPORTAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Estadísticas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff362419),
                      ),
                    ),
                    Text(
                      'Coffee Cat - Reportes y análisis',
                      style: TextStyle(color: Color(0xff55453A), fontSize: 12),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generando reporte PDF...')),
                    );
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Exportar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff362419),
                    foregroundColor: Colors.white,
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            // FILTROS DE RANGO DE TIEMPO
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _rangos.map((rango) {
                  final isSelected = _rangoSeleccionado == rango;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(rango),
                      selected: isSelected,
                      selectedColor: const Color(0xff362419),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xff362419),
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
            const SizedBox(height: 20),

            // CUERPO DE DATOS
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // La conexión a Firebase permanece igual al archivo original
                stream: FirebaseFirestore.instance.collection('ventas').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final todasLasVentas = snapshot.data!.docs;
                  final ahora = DateTime.now();

                  // FILTRADO LOCAL
                  final ventasFiltradas = todasLasVentas.where((venta) {
                    final data = venta.data() as Map<String, dynamic>;
                    if (!data.containsKey('fecha')) return true;

                    final fechaVenta = (data['fecha'] as Timestamp).toDate();

                    if (_rangoSeleccionado == 'Hoy') {
                      return fechaVenta.day == ahora.day && 
                             fechaVenta.month == ahora.month && 
                             fechaVenta.year == ahora.year;
                    } else if (_rangoSeleccionado == 'Esta Semana') {
                      return ahora.difference(fechaVenta).inDays <= 7;
                    } else if (_rangoSeleccionado == 'Este Mes') {
                      return fechaVenta.month == ahora.month && 
                             fechaVenta.year == ahora.year;
                    }
                    return true;
                  }).toList();

                  // VARIABLES PARA MÉTRICAS Y GRÁFICAS
                  int totalVentas = ventasFiltradas.length;
                  double totalIngresos = 0;
                  int productosVendidos = 0;
                  Map<String, int> conteoProductos = {};
                  Map<int, int> horasVenta = {}; 
                  
                  // Inicializamos los días de la semana (1 = Lunes, 7 = Domingo)
                  Map<int, double> ingresosPorDia = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

                  for (var venta in ventasFiltradas) {
                    final data = venta.data() as Map<String, dynamic>;
                    double ingresoVenta = (data['total'] ?? 0).toDouble();
                    totalIngresos += ingresoVenta;
                    
                    if (data.containsKey('fecha')) {
                      DateTime fecha = (data['fecha'] as Timestamp).toDate();
                      horasVenta[fecha.hour] = (horasVenta[fecha.hour] ?? 0) + 1;
                      
                      // Sumar ingresos al día correspondiente para la gráfica de barras
                      ingresosPorDia[fecha.weekday] = (ingresosPorDia[fecha.weekday] ?? 0) + ingresoVenta;
                    }

                    final productos = data['productos'] as List<dynamic>? ?? [];
                    for (var p in productos) {
                      String nombre = p['nombre'] ?? 'Desconocido';
                      int cantidad = p['cantidad'] ?? 1;
                      productosVendidos += cantidad;
                      conteoProductos[nombre] = (conteoProductos[nombre] ?? 0) + cantidad;
                    }
                  }

                  // INSIGHTS
                  double ticketPromedio = totalVentas > 0 ? totalIngresos / totalVentas : 0;
                  String horaPico = 'N/A';
                  if (horasVenta.isNotEmpty) {
                    int horaMasFrecuente = horasVenta.entries.reduce((a, b) => a.value > b.value ? a : b).key;
                    horaPico = '$horaMasFrecuente:00';
                  }

                  // RANKINGS
                  var productosOrdenados = conteoProductos.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  var top5 = productosOrdenados.take(5).toList();
                  var bottom5 = productosOrdenados.reversed.take(5).toList();

                  // HISTORIAL RECIENTE
                  var ultimasVentas = List.from(ventasFiltradas)
                    ..sort((a, b) {
                      var fechaA = (a.data() as Map<String, dynamic>)['fecha'] as Timestamp?;
                      var fechaB = (b.data() as Map<String, dynamic>)['fecha'] as Timestamp?;
                      if (fechaA == null || fechaB == null) return 0;
                      return fechaB.compareTo(fechaA);
                    });
                  var historialReciente = ultimasVentas.take(5).toList();

                  // RENDERIZADO DE LA INTERFAZ
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TARJETAS PRINCIPALES
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildStatCard(Icons.shopping_cart, '$totalVentas', 'Total Ventas', Colors.blue),
                            _buildStatCard(Icons.attach_money, '\$${totalIngresos.toStringAsFixed(2)}', 'Ingresos', Colors.green),
                            _buildStatCard(Icons.inventory, '$productosVendidos', 'Artículos', Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // NUEVA SECCIÓN: GRÁFICA DE BARRAS
                        const Text('Ingresos por Día de la Semana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Container(
                          height: 250,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: _buildBarChart(ingresosPorDia),
                        ),
                        const SizedBox(height: 30),

                        // INSIGHTS
                        const Text('Insights Clave', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildInsightCard(Icons.access_time, 'Hora Pico', horaPico, 'Mayor volumen de transacciones'),
                            _buildInsightCard(Icons.receipt_long, 'Ticket Promedio', '\$${ticketPromedio.toStringAsFixed(2)}', 'Gasto promedio por transacción'),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // RANKINGS
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildRankingList('Más Vendidos', top5, Colors.amber)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildRankingList('Menos Vendidos', bottom5, Colors.redAccent)),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // REGISTRO DE ACTIVIDAD RECIENTE
                        const Text('Últimas Transacciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: historialReciente.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final venta = historialReciente[index].data() as Map<String, dynamic>;
                              final total = (venta['total'] ?? 0).toDouble();
                              String fechaStr = 'Sin fecha';
                              if (venta.containsKey('fecha')) {
                                final date = (venta['fecha'] as Timestamp).toDate();
                                fechaStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                              }
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                                  child: const Icon(Icons.check, color: Colors.green, size: 18),
                                ),
                                title: const Text('Venta completada', style: TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('Hora: $fechaStr'),
                                trailing: Text('\$${total.toStringAsFixed(2)}', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET: Gráfica de Barras
  Widget _buildBarChart(Map<int, double> ingresosPorDia) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: ingresosPorDia.values.reduce((a, b) => a > b ? a : b) * 1.2, // Dar margen superior
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12);
                String text;
                switch (value.toInt()) {
                  case 1: text = 'Lun'; break;
                  case 2: text = 'Mar'; break;
                  case 3: text = 'Mié'; break;
                  case 4: text = 'Jue'; break;
                  case 5: text = 'Vie'; break;
                  case 6: text = 'Sáb'; break;
                  case 7: text = 'Dom'; break;
                  default: text = ''; break;
                }
                return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(text, style: style));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text('\$${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500, // Ajustar según el volumen de ventas general
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: ingresosPorDia.entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: const Color(0xff362419),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // WIDGET: Tarjeta de estadísticas
  Widget _buildStatCard(IconData icon, String value, String title, Color color) {
    return SizedBox(
      width: 220,
      child: Card(
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff362419),
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET: Tarjeta para Insights
  Widget _buildInsightCard(IconData icon, String title, String value, String subtitle) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.purple, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.purple)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  // WIDGET: Lista para el Ranking
  Widget _buildRankingList(String titulo, List<MapEntry<String, int>> datos, Color iconoColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (datos.isEmpty) const Text('No hay datos suficientes', style: TextStyle(color: Colors.grey)),
          ...datos.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: iconoColor),
                        const SizedBox(width: 8),
                        Expanded(child: Text(entry.key, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Text('${entry.value} un.', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}