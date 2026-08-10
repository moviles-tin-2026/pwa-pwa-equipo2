import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItemCarrito {
  final String id;
  final String nombre;
  final double precio;
  int cantidad;
  final int stockMaximo;
  final String? urlImagen;

  ItemCarrito({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.stockMaximo,
    this.urlImagen,
  });

  double get subtotal => precio * cantidad;
}

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final CollectionReference _productosRef = FirebaseFirestore.instance.collection('productos');
  final CollectionReference _ventasRef = FirebaseFirestore.instance.collection('ventas');

  final List<ItemCarrito> _carrito = [];
  String? _metodoPago;
  final TextEditingController _efectivoController = TextEditingController();
  bool _procesando = false;

  double get _totalVenta => _carrito.fold(0.0, (total, item) => total + item.subtotal);

  static const Map<String, String> _imagenesPorDefecto = {
    'Miau Latte': 'https://i.postimg.cc/VvGcnz49/Whats-App-Image-2026-07-15-at-5-44-43-PM.jpg',
    'Capuchino Bigotes': 'https://i.postimg.cc/qqbdypQP/Whats-App-Image-2026-07-15-at-5-44-44-PM.jpg',
    'Cold Brew Nocturno': 'https://i.postimg.cc/YqYtdDMs/coldbrew.jpg',
    'Purr Croissant': 'https://i.postimg.cc/4dDrtZK2/croissant.jpg',
    'Michi-Muffin': 'https://i.postimg.cc/Hxqf5HJB/muffin.jpg',
    'Gato Negro': 'https://i.postimg.cc/ry0cWXtf/Gato-Negro.jpg',
    'Persa Blanco': 'https://i.postimg.cc/xjJYHDbR/Persa-Blanco.jpg',
    'Ronroneo de Caramelo': 'https://i.postimg.cc/tRKbNShN/Ronroneo-de-Caramelo.jpg',
    'Zarpazo Espresso': 'https://i.postimg.cc/sfkz46pc/Zarpazo-Espresso.jpg',
    'Chocolate Purrfecto': 'https://i.postimg.cc/3rshFSg1/Chocolate-Purrfecto.jpg',
    'Michi Iced Latte': 'https://i.postimg.cc/447ZtkhQ/Michi-Iced-Latte.jpg',
    'Matcha Gato Relax': 'https://i.postimg.cc/qBh0nVC2/Matcha-Gato-Relax.jpg',
    'Limonada del Gato con Botas': 'https://i.postimg.cc/ry0cWXtS/Limonada-del-Gato-con-Botas.jpg',
    'Affogato "Cozy Murr"': 'https://i.postimg.cc/pVhx8bn0/Affogato-Cozy-Murr.jpg',
    'Boba Kat': 'https://i.postimg.cc/FFdmc5JG/Boba-Kat.jpg',
    'Cat-shake': 'https://i.postimg.cc/dQbFjH8n/Cat-shake.jpg',
    'Galletas "Huellitas de Amor"': 'https://i.postimg.cc/c1gZYy8R/Galletas-Huellitas-de-Amor.jpg',
    'Cheesecake "Tres Colores"': 'https://i.postimg.cc/jqwKN0Jg/Cheesecake-Tres-Colores.jpg',
    'Brownie "Dormilón"': 'https://i.postimg.cc/G38rYwsG/Brownie-Dormilon.jpg',
    'Michi Donut': 'https://i.postimg.cc/J7DmJVBx/Michi-Donut.jpg',
    'Pastel "Choco-Meow"': 'https://i.postimg.cc/KckFLSgs/Pastel-Choco-Meow.jpg',
  };

  void _agregarAlCarrito(DocumentSnapshot producto) {
    final data = producto.data() as Map<String, dynamic>;
    final int stockDisponible = (data['cantidad'] as num?)?.toInt() ?? 0;

    if (stockDisponible <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto sin stock'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() {
      final index = _carrito.indexWhere((item) => item.id == producto.id);
      if (index != -1) {
        if (_carrito[index].cantidad < stockDisponible) {
          _carrito[index].cantidad++;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Stock máximo alcanzado'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
            );
          }
        }
      } else {
        String urlImg = (data['url_imagen'] as String?)?.trim() ?? '';
        final String nombre = (data['nombre'] as String?) ?? 'Sin nombre';
        
        if (urlImg.isEmpty && _imagenesPorDefecto.containsKey(nombre)) {
          urlImg = _imagenesPorDefecto[nombre]!;
        }

        _carrito.add(ItemCarrito(
          id: producto.id,
          nombre: nombre,
          precio: (data['precio'] as num?)?.toDouble() ?? 0.0,
          cantidad: 1,
          stockMaximo: stockDisponible,
          urlImagen: urlImg,
        ));
      }
    });
  }

  void _eliminarDelCarrito(String id) {
    setState(() {
      _carrito.removeWhere((item) => item.id == id);
    });
  }

  void _actualizarCantidad(String id, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      _eliminarDelCarrito(id);
      return;
    }
    setState(() {
      final index = _carrito.indexWhere((item) => item.id == id);
      if (index != -1 && nuevaCantidad <= _carrito[index].stockMaximo) {
        _carrito[index].cantidad = nuevaCantidad;
      }
    });
  }

  // ============================================================================
  // ✅ PROCESAR VENTA OPTIMIZADO Y SIN BLOQUEOS
  // ============================================================================
  Future<void> _procesarVenta() async {
    if (_carrito.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega productos al carrito'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_metodoPago == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona método de pago'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_metodoPago == 'efectivo') {
      final efectivo = double.tryParse(_efectivoController.text) ?? 0.0;
      if (efectivo < _totalVenta) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El efectivo ingresado es insuficiente'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() => _procesando = true);
    
    // Captura preventiva de valores antes de reiniciar el carrito
    final double totalFinalVenta = _totalVenta;
    final double efectivoRecibido = double.tryParse(_efectivoController.text) ?? 0.0;

    // Mostrar loading en el Root Navigator
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true, 
      builder: (dialogCtx) => const Center(
        child: CircularProgressIndicator(color: Color(0xff362419)),
      ),
    );

    try {
      final usuarioEmail = FirebaseAuth.instance.currentUser?.email ?? 'desconocido';
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        for (var item in _carrito) {
          final productoRef = _productosRef.doc(item.id);
          final productoDoc = await transaction.get(productoRef);
          
          if (!productoDoc.exists) {
            throw Exception('El producto "${item.nombre}" fue eliminado o no existe.');
          }
          
          final data = productoDoc.data() as Map<String, dynamic>?;
          int stockActual = 0;
          if (data != null && data['cantidad'] != null) {
            if (data['cantidad'] is num) {
              stockActual = (data['cantidad'] as num).toInt();
            } else if (data['cantidad'] is String) {
              stockActual = int.tryParse(data['cantidad'] as String) ?? 0;
            }
          }

          if (stockActual < item.cantidad) {
            throw Exception('Stock insuficiente para "${item.nombre}". Disponible: $stockActual');
          }

          transaction.update(productoRef, {
            'cantidad': stockActual - item.cantidad,
            'fecha_modificacion': FieldValue.serverTimestamp(),
          });
        }

        final itemsParaGuardar = _carrito.map((item) => {
          'id': item.id,
          'nombre': item.nombre,
          'precio': item.precio.toDouble(),
          'cantidad': item.cantidad,
        }).toList();

        final nuevaVentaRef = _ventasRef.doc();
        transaction.set(nuevaVentaRef, {
          'productos': itemsParaGuardar,
          'total': totalFinalVenta.toDouble(),
          'metodo_pago': _metodoPago,
          'fecha': FieldValue.serverTimestamp(),
          'usuario': usuarioEmail,
        });
      });

      // ✅ Cierra el diálogo de carga correctamente desde la raíz
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        setState(() => _procesando = false);
        _mostrarExito(totalFinalVenta, efectivoRecibido);
      }
      
    } catch (e) {
      // ✅ Cierra el diálogo de carga en caso de error inesperado
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'), 
            backgroundColor: Colors.red, 
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ============================================================================
  // ✅ TICKET DE ÉXITO FIJO Y CORREGIDO
  // ============================================================================
  void _mostrarExito(double totalCobrado, double efectivoRecibido) {
    if (!mounted) return;
    
    final cambio = efectivoRecibido - totalCobrado;
    
    setState(() {
      _carrito.clear();
      _metodoPago = null;
      _efectivoController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                SizedBox(width: 12),
                Text('¡Venta Procesada con Éxito!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            Text('Total cobrado: \$${totalCobrado.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
            if (efectivoRecibido > 0) ...[
              const SizedBox(height: 4),
              Text('Efectivo recibido: \$${efectivoRecibido.toStringAsFixed(2)}'),
              Text('Cambio a entregar: \$${cambio.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ],
        ),
        backgroundColor: const Color(0xff362419),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final bool isMobile = outerConstraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ventas 💰', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff362419))),
                const Text('Coffee Cat - Punto de venta', style: TextStyle(color: Color(0xff55453A), fontSize: 12)),
                const SizedBox(height: 20),
                Expanded(
                  child: isMobile
                      ? SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(height: 400, child: _buildCatalogo()),
                              const SizedBox(height: 16),
                              SizedBox(height: 400, child: _buildCarrito()),
                            ],
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildCatalogo()),
                            const SizedBox(width: 20),
                            Expanded(flex: 1, child: _buildCarrito()),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xff362419)));
                  }
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
                          childAspectRatio: 0.9,
                        ),
                        itemCount: productos.length,
                        itemBuilder: (context, index) {
                          final producto = productos[index];
                          final data = producto.data() as Map<String, dynamic>;
                          
                          return _ProductoCard(
                            producto: producto,
                            data: data,
                            imagenesPorDefecto: _imagenesPorDefecto,
                            onTap: () => _agregarAlCarrito(producto),
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
                    return _CartItemWidget(
                      item: item,
                      onDecrement: () => _actualizarCantidad(item.id, item.cantidad - 1),
                      onIncrement: () => _actualizarCantidad(item.id, item.cantidad + 1),
                      onRemove: () => _eliminarDelCarrito(item.id),
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
                ChoiceChip(
                  label: const Text('Efectivo', style: TextStyle(fontSize: 11)),
                  selected: _metodoPago == 'efectivo',
                  onSelected: (s) => setState(() => _metodoPago = s ? 'efectivo' : null),
                  selectedColor: const Color(0xff362419),
                  labelStyle: TextStyle(color: _metodoPago == 'efectivo' ? Colors.white : Colors.black87),
                ),
                ChoiceChip(
                  label: const Text('Tarjeta', style: TextStyle(fontSize: 11)),
                  selected: _metodoPago == 'tarjeta',
                  onSelected: (s) => setState(() => _metodoPago = s ? 'tarjeta' : null),
                  selectedColor: const Color(0xff362419),
                  labelStyle: TextStyle(color: _metodoPago == 'tarjeta' ? Colors.white : Colors.black87),
                ),
              ],
            ),
            if (_metodoPago == 'efectivo') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _efectivoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                decoration: const InputDecoration(
                  labelText: 'Efectivo recibido', 
                  prefixText: '\$ ', 
                  border: OutlineInputBorder(), 
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff362419), 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                onPressed: _procesando || _carrito.isEmpty ? null : _procesarVenta,
                child: _procesando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('PROCESAR VENTA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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

class _ProductoCard extends StatelessWidget {
  final DocumentSnapshot producto;
  final Map<String, dynamic> data;
  final Map<String, String> imagenesPorDefecto;
  final VoidCallback onTap;

  const _ProductoCard({
    required this.producto,
    required this.data,
    required this.imagenesPorDefecto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String nombre = (data['nombre'] as String?) ?? 'Sin nombre';
    final double precio = (data['precio'] as num?)?.toDouble() ?? 0.0;
    final int cantidad = (data['cantidad'] as num?)?.toInt() ?? 0;
    final String categoria = (data['categoria'] as String?) ?? 'Bebidas Calientes';

    String urlImagen = (data['url_imagen'] as String?)?.trim() ?? '';
    if (urlImagen.isEmpty && imagenesPorDefecto.containsKey(nombre)) {
      urlImagen = imagenesPorDefecto[nombre]!;
    }

    final bool tieneStock = cantidad > 0;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tieneStock ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: const Color(0xffE5E5E3)),
                    if (urlImagen.isNotEmpty)
                      Image.network(
                        urlImagen,
                        fit: BoxFit.cover,
                        cacheWidth: 150,
                        cacheHeight: 150,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xff362419)));
                        },
                        errorBuilder: (context, error, stackTrace) => 
                            const Center(child: Icon(Icons.local_cafe, size: 30, color: Color(0xff55453A))),
                      )
                    else
                      const Center(child: Icon(Icons.local_cafe, size: 30, color: Color(0xff55453A))),
                    
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xff362419),
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        child: Text(categoria, style: const TextStyle(color: Colors.white, fontSize: 8)),
                      ),
                    ),
                    if (!tieneStock)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Agotado', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xff362419)), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${precio.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff362419))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tieneStock ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tieneStock ? '$cantidad disp.' : '0 disp.', 
                      style: TextStyle(fontSize: 10, color: tieneStock ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemWidget extends StatelessWidget {
  final ItemCarrito item;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;

  const _CartItemWidget({
    required this.item,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: Colors.grey[100],
      child: ListTile(
        dense: true,
        leading: item.urlImagen != null && item.urlImagen!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  item.urlImagen!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  cacheWidth: 80,
                  cacheHeight: 80,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_cafe, size: 24),
                ),
              )
            : const Icon(Icons.local_cafe, size: 24),
        title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('\$${item.precio.toStringAsFixed(2)} c/u'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 18), 
              onPressed: onDecrement,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            SizedBox(
              width: 30,
              child: Text('${item.cantidad}', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 18), 
              onPressed: onIncrement,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18), 
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}