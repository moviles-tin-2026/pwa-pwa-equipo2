import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- Reemplázalo con ':'
import 'package:fl_chart/fl_chart.dart';
=======
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
>>>>>>> 5dd61200ce585f5b0e1deba5cecc46bbe67b7457

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  final String _rangoSeleccionado = 'Histórico';
  final List<String> _rangos = ['Hoy', 'Esta Semana', 'Este Mes', 'Histórico'];

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return ColoredBox(
      color: Colors.grey[50]!,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ENCABEZADO Y BOTÓN DE EXPORTAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                ),
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
                        color: isSelected
                            ? Colors.white
                            : const Color(0xff362419),
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
                stream: FirebaseFirestore.instance
                    .collection('ventas')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final todasLasVentas = snapshot.data!.docs;
                  final ahora = DateTime.now();

                  // FILTRADO LOCAL
                  final ventasFiltradas = todasLasVentas.where((venta) {
                    final data = venta.data() as Map<String, dynamic>;
                    if (!data.containsKey('fecha') || data['fecha'] == null) {
                      return true;
                    }

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
                  Map<int, double> ingresosPorDia = {
                    1: 0,
                    2: 0,
                    3: 0,
                    4: 0,
                    5: 0,
                    6: 0,
                    7: 0,
                  };

                  for (var venta in ventasFiltradas) {
                    final data = venta.data() as Map<String, dynamic>;
                    double ingresoVenta = (data['total'] ?? 0).toDouble();
                    totalIngresos += ingresoVenta;

                    if (data.containsKey('fecha') && data['fecha'] != null) {
                      DateTime fecha = (data['fecha'] as Timestamp).toDate();
                      horasVenta[fecha.hour] =
                          (horasVenta[fecha.hour] ?? 0) + 1;

                      // Sumar ingresos al día correspondiente
                      ingresosPorDia[fecha.weekday] =
                          (ingresosPorDia[fecha.weekday] ?? 0) + ingresoVenta;
                    }

                    final productos = data['productos'] as List<dynamic>? ?? [];
                    for (var p in productos) {
                      String nombre = p['nombre'] ?? 'Desconocido';
                      int cantidad = (p['cantidad'] ?? 1) as int;
                      productosVendidos += cantidad;
                      conteoProductos[nombre] =
                          (conteoProductos[nombre] ?? 0) + cantidad;
                    }
                  }

                  // INSIGHTS
                  double ticketPromedio = totalVentas > 0
                      ? totalIngresos / totalVentas
                      : 0;
                  String horaPico = 'N/A';
                  if (horasVenta.isNotEmpty) {
                    int horaMasFrecuente = horasVenta.entries
                        .reduce((a, b) => a.value > b.value ? a : b)
                        .key;
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
                      var fechaA =
                          (a.data() as Map<String, dynamic>)['fecha']
                              as Timestamp?;
                      var fechaB =
                          (b.data() as Map<String, dynamic>)['fecha']
                              as Timestamp?;
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
                            _buildStatCard(
                              Icons.shopping_cart,
                              '$totalVentas',
                              'Total Ventas',
                              Colors.blue,
                            ),
                            _buildStatCard(
                              Icons.attach_money,
                              '\$${totalIngresos.toStringAsFixed(2)}',
                              'Ingresos',
                              Colors.green,
                            ),
                            _buildStatCard(
                              Icons.inventory,
                              '$productosVendidos',
                              'Artículos',
                              Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // GRÁFICA DE BARRAS
                        const Text(
                          'Ingresos por Día de la Semana',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                        const Text(
                          'Insights Clave',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildInsightCard(
                              Icons.access_time,
                              'Hora Pico',
                              horaPico,
                              'Mayor volumen de transacciones',
                            ),
                            _buildInsightCard(
                              Icons.receipt_long,
                              'Ticket Promedio',
                              '\$${ticketPromedio.toStringAsFixed(2)}',
                              'Gasto promedio por transacción',
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // RANKINGS
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildRankingList(
                                'Más Vendidos',
                                top5,
                                Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildRankingList(
                                'Menos Vendidos',
                                bottom5,
                                Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // REGISTRO DE ACTIVIDAD RECIENTE
                        const Text(
                          'Últimas Transacciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final venta =
                                  historialReciente[index].data()
                                      as Map<String, dynamic>;
                              final total = (venta['total'] ?? 0).toDouble();
                              String fechaStr = 'Sin fecha';
                              if (venta.containsKey('fecha') &&
                                  venta['fecha'] != null) {
                                final date = (venta['fecha'] as Timestamp)
                                    .toDate();
                                fechaStr =
                                    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                              }
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                ),
                                title: const Text(
                                  'Venta completada',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text('Hora: $fechaStr'),
                                trailing: Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              );
                            },
=======
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        // Envolvemos todo en los StreamBuilders para que el botón "Exportar" tenga acceso a los datos
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('ventas').snapshots(),
          builder: (context, snapshotVentas) {
            if (!snapshotVentas.hasData) return const Center(child: CircularProgressIndicator());

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('gastos').snapshots(),
              builder: (context, snapshotGastos) {
                if (!snapshotGastos.hasData) return const Center(child: CircularProgressIndicator());

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
                    conteoProductos[nombre] = (conteoProductos[nombre] ?? 0) + cantidad;
                  }
                }

                // 2. PROCESAR GASTOS Y PAGOS A PROVEEDORES
                double totalGastosPagados = 0;
                double cuentasPorPagar = 0;
                String nombreProximoProveedor = 'Ninguno';
                String fechaProximoPagoStr = 'Al día';
                DateTime? fechaMasProxima;
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

                    pagosPendientes.add({'proveedor': proveedor, 'monto': monto, 'fecha': fecha, 'fechaStr': fechaStr});

                    if (fecha != null && (fechaMasProxima == null || fecha.isBefore(fechaMasProxima))) {
                      fechaMasProxima = fecha;
                      nombreProximoProveedor = proveedor;
                      fechaProximoPagoStr = fechaStr;
                    }
                  }
                }

                pagosPendientes.sort((a, b) {
                  if (a['fecha'] == null) return 1;
                  if (b['fecha'] == null) return -1;
                  return (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime);
                });

                double gananciaNeta = totalIngresos - totalGastosPagados;
                var productosOrdenados = conteoProductos.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                var top5 = productosOrdenados.take(5).toList();
                var bottom5 = productosOrdenados.length > 5 ? productosOrdenados.skip(5).toList().reversed.take(5).toList() : <MapEntry<String, int>>[];

                return Column(
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
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xff362419), letterSpacing: -0.5),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Resumen operativo y cuentas por pagar',
                              style: TextStyle(color: Color(0xff55453A), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _generarYMostrarPDF(
                            rango: _rangoSeleccionado,
                            totalIngresos: totalIngresos,
                            gananciaNeta: gananciaNeta,
                            totalVentas: totalVentas,
                            cuentasPorPagar: cuentasPorPagar,
                            top5: top5,
                          ),
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: const Text('Exportar PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff362419),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
>>>>>>> 5dd61200ce585f5b0e1deba5cecc46bbe67b7457
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
                                side: BorderSide(color: isSelected ? const Color(0xff362419) : Colors.grey.shade300),
                              ),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xff55453A),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                if (selected) setState(() => _rangoSeleccionado = rango);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- CUERPO DE DATOS ---
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                  onTap: () => _mostrarModalPagosPendientes(context: context, pagosPendientes: pagosPendientes, proximaFecha: fechaProximoPagoStr, totalDeuda: cuentasPorPagar),
                                ),
                                _buildInsightCard(
                                  icon: Icons.local_shipping_rounded,
                                  title: 'Próximo Pago',
                                  value: nombreProximoProveedor,
                                  subtitle: 'Vence: $fechaProximoPagoStr',
                                  color: Colors.deepPurple,
                                  onTap: () => _mostrarModalPagosPendientes(context: context, pagosPendientes: pagosPendientes, proximaFecha: fechaProximoPagoStr, totalDeuda: cuentasPorPagar),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            const Text('Ingresos por Día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff362419))),
                            const SizedBox(height: 16),
                            Container(
                              height: 300,
                              padding: const EdgeInsets.only(top: 30, right: 20, left: 10, bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: _buildModernBarChart(ingresosPorDia),
                            ),
                            const SizedBox(height: 32),

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
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

<<<<<<< HEAD
  // WIDGET: Gráfica de Barras
  Widget _buildBarChart(Map<int, double> ingresosPorDia) {
    // Calculamos el valor máximo de forma segura
    double maxIngreso = ingresosPorDia.values.isEmpty
        ? 0
        : ingresosPorDia.values.reduce((a, b) => a > b ? a : b);
    double maxY = maxIngreso == 0 ? 100 : maxIngreso * 1.2;
=======
  // --- NUEVA FUNCIONALIDAD: GENERAR Y MOSTRAR PDF ---
  Future<void> _generarYMostrarPDF({
    required String rango,
    required double totalIngresos,
    required double gananciaNeta,
    required int totalVentas,
    required double cuentasPorPagar,
    required List<MapEntry<String, int>> top5,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Reporte Financiero', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Text('Filtro aplicado: $rango', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              pw.SizedBox(height: 24),
              
              pw.Text('Resumen General', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Ingresos Brutos:'),
                  pw.Text('\$${totalIngresos.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Ganancia Neta:'),
                  pw.Text('\$${gananciaNeta.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total de Ventas Realizadas:'),
                  pw.Text('$totalVentas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cuentas por Pagar (Deuda):'),
                  pw.Text('\$${cuentasPorPagar.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.red800, fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.SizedBox(height: 32),

              pw.Text('Top 5 Productos Más Vendidos', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              ...top5.map((producto) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(producto.key),
                    pw.Text('${producto.value} unds.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              )),
              
              pw.Spacer(),
              pw.Center(
                child: pw.Text('Reporte generado automáticamente el ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500))
              )
            ],
          );
        },
      ),
    );

    // Esto abrirá el cuadro de diálogo nativo para previsualizar, imprimir o guardar el PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Financiero_$rango.pdf',
    );
  }

  // --- GRÁFICA DE BARRAS MODERNIZADA ---
  Widget _buildModernBarChart(Map<int, double> ingresosPorDia) {
    double maxY = ingresosPorDia.values.isEmpty ? 1 : ingresosPorDia.values.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 100;
    double chartMaxY = maxY * 1.2;
>>>>>>> 5dd61200ce585f5b0e1deba5cecc46bbe67b7457

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
<<<<<<< HEAD
        maxY: maxY,
        barTouchData: BarTouchData(enabled: true),
=======
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
>>>>>>> 5dd61200ce585f5b0e1deba5cecc46bbe67b7457
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
<<<<<<< HEAD
                const style = TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                String text;
                switch (value.toInt()) {
                  case 1:
                    text = 'Lun';
                    break;
                  case 2:
                    text = 'Mar';
                    break;
                  case 3:
                    text = 'Mié';
                    break;
                  case 4:
                    text = 'Jue';
                    break;
                  case 5:
                    text = 'Vie';
                    break;
                  case 6:
                    text = 'Sáb';
                    break;
                  case 7:
                    text = 'Dom';
                    break;
                  default:
                    text = '';
                    break;
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(text, style: style),
                );
=======
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
>>>>>>> 5dd61200ce585f5b0e1deba5cecc46bbe67b7457
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
<<<<<<< HEAD
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '\$${value.toInt()}',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
=======
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == chartMaxY) return const SizedBox.shrink();
                return Text('\$${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500));
>>>>>>> 5dd61200ce585f5b0e1deba5cecc46bbe67b7457
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
<<<<<<< HEAD
          horizontalInterval: (maxY / 4) > 0 ? (maxY / 4) : 1,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
=======
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1, dashArray: [5, 5]),
>>>>>>> 5dd61200ce585f5b0e1deba5cecc46bbe67b7457
        ),
        borderData: FlBorderData(show: false),
        barGroups: ingresosPorDia.entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
<<<<<<< HEAD
                color: const Color(0xff362419),
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
=======
                width: 26, // Barras ligeramente más anchas para un look moderno
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff362419), // Color base
                    Color(0xff755845), // Tono más claro para el degradado
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)), // Base plana, borde superior curvo
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: chartMaxY,
                  color: Colors.grey.shade100, // Track de fondo más limpio
>>>>>>> 5dd61200ce585f5b0e1deba5cecc46bbe67b7457
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

<<<<<<< HEAD
  // WIDGET: Tarjeta de estadísticas
  Widget _buildStatCard(
    IconData icon,
    String value,
    String title,
    Color color,
  ) {
    return SizedBox(
=======
  // EL RESTO DE TUS MÉTODOS SE MANTIENEN IGUAL...
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

  Widget _buildStatCard(IconData icon, String value, String title, Color color) {
    return Container(
>>>>>>> 5dd61200ce585f5b0e1deba5cecc46bbe67b7457
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xff362419), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({required IconData icon, required String title, required String value, required String subtitle, required Color color, VoidCallback? onTap}) {
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
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
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

<<<<<<< HEAD
  // WIDGET: Tarjeta para Insights
  Widget _buildInsightCard(
    IconData icon,
    String title,
    String value,
    String subtitle,
  ) {
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
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  // WIDGET: Lista para el Ranking
  Widget _buildRankingList(
    String titulo,
    List<MapEntry<String, int>> datos,
    Color iconoColor,
  ) {
=======
  Widget _buildRankingList(String titulo, List<MapEntry<String, int>> datos, Color iconoColor) {
>>>>>>> 5dd61200ce585f5b0e1deba5cecc46bbe67b7457
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
          Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (datos.isEmpty)
            const Text(
              'No hay datos suficientes',
              style: TextStyle(color: Colors.grey),
            ),
=======
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xff362419))),
          const SizedBox(height: 16),
          if (datos.isEmpty) 
            Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('No hay datos suficientes', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic))),
>>>>>>> 5dd61200ce585f5b0e1deba5cecc46bbe67b7457
          ...datos.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
<<<<<<< HEAD
                        Icon(Icons.circle, size: 8, color: iconoColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${entry.value} un.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
=======
                        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: iconoColor)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Text('${entry.value} un.', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xff55453A))),
>>>>>>> 5dd61200ce585f5b0e1deba5cecc46bbe67b7457
                ],
              ),
            );
          }),
        ],
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
}