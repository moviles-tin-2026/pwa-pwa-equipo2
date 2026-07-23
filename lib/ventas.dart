import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final CollectionReference _productosRef = FirebaseFirestore.instance.collection('productos');
  final CollectionReference _ventasRef = FirebaseFirestore.instance.collection('ventas');

  final List<Map<String, dynamic>> _carrito = [];
  String? _metodoPago;
  final TextEditingController _efectivoController = TextEditingController();

  double get _totalVenta {
    return _carrito.fold(0, (total, item) => total + ((item['precio'] as num).toDouble() * (item['cantidad'] as int)));
  }

  void _agregarAlCarrito(DocumentSnapshot producto) {
    final data = producto.data() as Map<String, dynamic>;
    final int stockDisponible = int.tryParse((data['cantidad'] ?? 0).toString()) ?? 0;

    if (stockDisponible <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto sin stock'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      final index = _carrito.indexWhere((item) => item['id'] == producto.id);
      if (index != -1) {
        final cantidadActual = _carrito[index]['cantidad'] as int;
        if (cantidadActual < stockDisponible) {
          _carrito[index]['cantidad'] = cantidadActual + 1;
        }
      } else {
        _carrito.add({
          'id': producto.id,
          'nombre': data['nombre'] ?? 'Sin nombre',
          'precio': double.tryParse((data['precio'] ?? 0).toString()) ?? 0.0,
          'cantidad': 1,
          'stockMaximo': stockDisponible,
        });
      }
    });
  }

  void _eliminarDelCarrito(String id) {
    setState(() {
      _carrito.removeWhere((item) => item['id'] == id);
    });
  }

  void _actualizarCantidad(String id, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      _eliminarDelCarrito(id);
      return;
    }
    setState(() {
      final index = _carrito.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        final item = _carrito[index];
        final stockMax = item['stockMaximo'] as int;
        if (nuevaCantidad <= stockMax) {
          item['cantidad'] = nuevaCantidad;
        }
      }
    });
  }

  Future<void> _procesarVenta() async {
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega productos al carrito'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_metodoPago == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona método de pago'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      for (var item in _carrito) {
        final productoRef = _productosRef.doc(item['id']);
        final productoDoc = await productoRef.get();
        final productoData = productoDoc.data() as Map<String, dynamic>;
        final stockActual = int.tryParse((productoData['cantidad'] ?? 0).toString()) ?? 0;

        await productoRef.update({
          'cantidad': stockActual - (item['cantidad'] as int),
        });
      }

      await _ventasRef.add({
        'productos': _carrito.map((item) => {
          'id': item['id'],
          'nombre': item['nombre'],
          'precio': item['precio'],
          'cantidad': item['cantidad'],
        }).toList(),
        'total': _totalVenta,
        'metodo_pago': _metodoPago,
        'fecha': FieldValue.serverTimestamp(),
        'usuario': FirebaseAuth.instance.currentUser?.email ?? 'desconocido',
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Venta Exitosa', style: TextStyle(color: Color(0xff362419))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total: \$${_totalVenta.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                if (_metodoPago == 'efectivo') ...[
                  const SizedBox(height: 8),
                  Text('Efectivo: \$${double.parse(_efectivoController.text).toStringAsFixed(2)}'),
                  Text('Cambio: \$${(double.parse(_efectivoController.text) - _totalVenta).toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _carrito.clear();
                    _metodoPago = null;
                    _efectivoController.clear();
                  });
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ventas 💰', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff362419))),
          const Text('Coffee Cat - Punto de venta', style: TextStyle(color: Color(0xff55453A), fontSize: 12)),
          const SizedBox(height: 20),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return Column(
                    children: [
                      Expanded(child: _buildCatalogo()),
                      const SizedBox(height: 16),
                      SizedBox(height: 400, child: _buildCarrito()),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(flex: 2, child: _buildCatalogo()),
                      const SizedBox(width: 20),
                      Expanded(flex: 1, child: _buildCarrito()),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📦 Catálogo de Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff362419))),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _productosRef.orderBy('nombre').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No hay productos', style: TextStyle(color: Color(0xff55453A))));
                  }

                  final productos = snapshot.data!.docs;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 600 ? 3 : constraints.maxWidth > 400 ? 2 : 1;
                      
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: productos.length,
                        itemBuilder: (context, index) {
                          final producto = productos[index];
                          final data = producto.data() as Map<String, dynamic>;
                          final String nombre = (data['nombre'] ?? 'Sin nombre').toString();
                          final double precio = double.tryParse((data['precio'] ?? 0).toString()) ?? 0.0;
                          final int cantidad = int.tryParse((data['cantidad'] ?? 0).toString()) ?? 0;

                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 1,
                            child: InkWell(
                              onTap: cantidad > 0 ? () => _agregarAlCarrito(producto) : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xffE5E5E3),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Center(child: Icon(Icons.local_cafe, size: 30, color: const Color(0xff55453A))),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xff362419)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('\$${precio.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff362419))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: cantidad > 0 ? Colors.green[100] : Colors.red[100],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('$cantidad disp.', style: TextStyle(fontSize: 10, color: cantidad > 0 ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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

  Widget _buildCarrito() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🛒 Orden de Venta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff362419))),
            const Divider(),
            if (_carrito.isEmpty)
              const Expanded(child: Center(child: Text('Carrito vacío', style: TextStyle(color: Colors.grey))))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _carrito.length,
                  itemBuilder: (context, index) {
                    final item = _carrito[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        dense: true,
                        title: Text(item['nombre'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('\$${(item['precio'] as num).toStringAsFixed(2)} c/u', style: const TextStyle(fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () => _actualizarCantidad(item['id'].toString(), (item['cantidad'] as int) - 1)),
                            Text('${item['cantidad']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _actualizarCantidad(item['id'].toString(), (item['cantidad'] as int) + 1)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: () => _eliminarDelCarrito(item['id'].toString())),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('\$${_totalVenta.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff362419))),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Método de Pago:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(label: const Text('Efectivo', style: TextStyle(fontSize: 11)), selected: _metodoPago == 'efectivo', onSelected: (s) => setState(() => _metodoPago = s ? 'efectivo' : null), selectedColor: const Color(0xff362419)),
                ChoiceChip(label: const Text('Tarjeta', style: TextStyle(fontSize: 11)), selected: _metodoPago == 'tarjeta', onSelected: (s) => setState(() => _metodoPago = s ? 'tarjeta' : null), selectedColor: const Color(0xff362419)),
              ],
            ),
            if (_metodoPago == 'efectivo') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _efectivoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Efectivo recibido', prefixText: '\$ ', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff362419), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: _carrito.isEmpty ? null : _procesarVenta,
                child: const Text('PROCESAR VENTA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _efectivoController.dispose();
    super.dispose();
  }
}