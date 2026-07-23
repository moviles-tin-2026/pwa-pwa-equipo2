import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EstadisticasPage extends StatelessWidget {
  const EstadisticasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📈 Estadísticas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff362419))),
          const Text('Coffee Cat - Reportes y análisis', style: TextStyle(color: Color(0xff55453A), fontSize: 12)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ventas').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ventas = snapshot.data!.docs;
                int totalVentas = ventas.length;
                double totalIngresos = 0;
                int productosVendidos = 0;

                for (var venta in ventas) {
                  final data = venta.data() as Map<String, dynamic>;
                  totalIngresos += (data['total'] ?? 0).toDouble();
                  final productos = data['productos'] as List<dynamic>? ?? [];
                  productosVendidos += productos.length;
                }

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatCard(Icons.shopping_cart, '$totalVentas', 'Total Ventas', Colors.blue),
                    _buildStatCard(Icons.attach_money, '\$${totalIngresos.toStringAsFixed(2)}', 'Ingresos Totales', Colors.green),
                    _buildStatCard(Icons.inventory, '$productosVendidos', 'Productos Vendidos', Colors.orange),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String title, Color color) {
    return SizedBox(
      width: 220,
      child: Card(
        elevation: 1,
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
                    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff362419))),
                    Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}