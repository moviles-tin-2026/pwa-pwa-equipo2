import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// PANTALLA DE INVENTARIO ULTRA-OPTIMIZADA
// ============================================================================
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final CollectionReference _productosRef = FirebaseFirestore.instance.collection('productos');

  // ✅ OPTIMIZACIÓN: Un solo stream para toda la pantalla
  StreamSubscription<QuerySnapshot>? _productosSub;
  List<QueryDocumentSnapshot> _productos = [];
  bool _isLoading = true;

  final _nombreController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _descripcionController = TextEditingController();

  bool _showFormPanel = false;
  bool _isEditing = false;
  String? _editingProductId;
  bool _showLowStockPanel = false;
  String _selectedFilter = 'Todos';
  String _bajoStockFilter = 'Todos';

  final ScrollController _bajoStockScrollController = ScrollController();
  List<QueryDocumentSnapshot> _documentosBajoStock = [];

  // ✅ OPTIMIZACIÓN: static const evita recrear el mapa en memoria
  static const Map<String, String> _imagenesPorDefecto = {
    'Miau Latte': 'https://i.postimg.cc/VvGcnz49/Whats-App-Image-2026-07-15-at-5-44-43-PM.jpg',
    'Capuchino Bigotes': 'https://i.postimg.cc/qqbdypQP/Whats-App-Image-2026-07-15-at-5-44-44-PM.jpg',
    'Cold Brew Nocturno': 'https://i.postimg.cc/YqYtdDMs/coldbrew.jpg',
    'Purr Croissant': 'https://i.postimg.cc/4dDrtZK2/croissant.jpg',
    'Michi-Muffin': 'https://i.postimg.cc/Hxqf5HJB/muffin.jpg',
  };

  @override
  void initState() {
    super.initState();
    
    // ✅ OPTIMIZACIÓN: Un solo listener para toda la colección
    _productosSub = _productosRef.orderBy('nombre').snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          _productos = snapshot.docs;
          _isLoading = false;
          
          // Actualizamos la lista de bajo stock sincrónicamente desde los mismos datos
          _documentosBajoStock = snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data != null && ((int.tryParse(data['cantidad']?.toString() ?? '0') ?? 0) <= 5);
          }).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _productosSub?.cancel(); // ✅ Importante: cancelar el stream
    _nombreController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _categoriaController.dispose();
    _descripcionController.dispose();
    _bajoStockScrollController.dispose();
    super.dispose();
  }

  void _prepararNuevoProducto() {
    setState(() {
      _isEditing = false;
      _editingProductId = null;
      _nombreController.clear();
      _cantidadController.clear();
      _precioController.clear();
      _categoriaController.clear();
      _descripcionController.clear();
      _showFormPanel = true;
      _showLowStockPanel = false;
    });
  }

  void _cargarProductoParaEditar(String id, Map<String, dynamic> data) {
    setState(() {
      _isEditing = true;
      _editingProductId = id;
      _nombreController.text = data['nombre']?.toString() ?? '';
      _cantidadController.text = (data['cantidad'] ?? 0).toString();
      _precioController.text = (data['precio'] ?? 0.0).toString();
      _categoriaController.text = data['categoria']?.toString() ?? '';
      _descripcionController.text = data['descripcion']?.toString() ?? '';
      _showFormPanel = true;
      _showLowStockPanel = false;
    });
  }

  Future<void> _procesarGuardado() async {
    if (_nombreController.text.isEmpty || _cantidadController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa nombre y cantidad'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final datosProducto = {
      'nombre': _nombreController.text,
      'cantidad': int.tryParse(_cantidadController.text) ?? 0,
      'precio': double.tryParse(_precioController.text) ?? 0.0,
      'categoria': _categoriaController.text.trim(),
      'descripcion': _descripcionController.text,
      'url_imagen': '',
      'fecha_modificacion': FieldValue.serverTimestamp(),
    };

    try {
      if (_isEditing && _editingProductId != null) {
        await _productosRef.doc(_editingProductId).update(datosProducto);
      } else {
        datosProducto['fecha'] = FieldValue.serverTimestamp();
        await _productosRef.add(datosProducto);
      }

      if (!mounted) return;
      setState(() {
        _showFormPanel = false;
        _prepararNuevoProducto();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Producto actualizado' : 'Producto agregado'),
          backgroundColor: const Color(0xff362419),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _eliminarProducto(String id) async {
    try {
      await _productosRef.doc(id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto eliminado'), backgroundColor: Color(0xff362419), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _hacerScrollHaciaCategoria(String categoria) {
    setState(() => _bajoStockFilter = categoria);
    if (categoria == 'Todos') {
      _bajoStockScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }

    int index = _documentosBajoStock.indexWhere((doc) {
      final cat = ((doc.data() as Map<String, dynamic>)['categoria'] ?? '').toString().toLowerCase();
      if (categoria == 'Bebidas Calientes') return cat.contains('caliente');
      if (categoria == 'Bebidas Frías') return cat.contains('fr');
      return cat == categoria.toLowerCase();
    });

    if (index != -1) {
      _bajoStockScrollController.animateTo(
        (index * 72.0).clamp(0.0, _bajoStockScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Pantalla de carga inicial rápida
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xffF5F0EB),
        body: Center(child: CircularProgressIndicator(color: Color(0xff362419))),
      );
    }

    // ✅ OPTIMIZACIÓN: Cálculos sincrónicos desde la única fuente de datos
    int total = 0;
    int bajoStock = 0;
    double valor = 0;
    Set<String> categorias = {};

    for (var doc in _productos) {
      final d = doc.data() as Map<String, dynamic>?;
      if (d == null) continue;
      int cant = int.tryParse(d['cantidad']?.toString() ?? '0') ?? 0;
      double precio = double.tryParse(d['precio']?.toString() ?? '0.0') ?? 0.0;
      valor += (cant * precio);
      if (cant <= 5) bajoStock++;
      if (d['categoria'] != null) categorias.add(d['categoria'].toString());
      total++;
    }

    // Filtrar productos para el grid
    var docs = _productos;
    if (_selectedFilter != 'Todos') {
      docs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;
        final cat = (data['categoria'] ?? '').toString().toLowerCase();
        if (_selectedFilter == 'Bebidas Calientes') return cat.contains('caliente');
        if (_selectedFilter == 'Bebidas Frías') return cat.contains('fr');
        return cat == _selectedFilter.toLowerCase();
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F0EB),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildKPIs(total, bajoStock, categorias.length, valor),
                  const SizedBox(height: 16),
                  _buildFilters(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildGridProductos(docs)),
                ],
              ),
            ),
          ),
          _buildSidePanel(),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGETS EXTRAÍDOS (Máximo rendimiento con 'const')
  // --------------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedFilter == 'Todos' ? 'Inventario Completo' : _selectedFilter,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff362419)),
            ),
            const Text('Coffee Cat - Gestión de productos', style: TextStyle(color: Color(0xff55453A), fontSize: 12)),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff362419),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: _prepararNuevoProducto,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Agregar', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildKPIs(int total, int bajoStock, int totalCategorias, double valor) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildSummaryCard(Icons.inventory_2, '$total', 'Total', Colors.blue),
        _buildSummaryCard(Icons.warning_amber, '$bajoStock', 'Bajo Stock', Colors.red, onTap: () {
          setState(() { _showLowStockPanel = true; _showFormPanel = false; });
        }),
        _buildSummaryCard(Icons.category, '$totalCategorias', 'Categorías', Colors.purple),
        _buildSummaryCard(Icons.attach_money, '\$${valor.toStringAsFixed(0)}', 'Valor', Colors.green),
      ],
    );
  }

  Widget _buildSummaryCard(IconData icon, String value, String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff362419))),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Todos', 'Bebidas Calientes', 'Bebidas Frías', 'Postres'].map((cat) {
          bool isSelected = _selectedFilter == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = cat),
              selectedColor: const Color(0xff362419),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xff362419), fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridProductos(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Center(child: Text('No hay productos en esta categoría', style: TextStyle(color: Color(0xff55453A))));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 600 ? 2 : constraints.maxWidth < 900 ? 3 : constraints.maxWidth < 1200 ? 4 : 5;
        
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final producto = docs[index];
            final data = producto.data() as Map<String, dynamic>;
            return _ProductoCardInventario(
              producto: producto,
              data: data,
              imagenesPorDefecto: _imagenesPorDefecto,
              onEdit: () => _cargarProductoParaEditar(producto.id, data),
              onDelete: () => _eliminarProducto(producto.id),
            );
          },
        );
      },
    );
  }

  Widget _buildSidePanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: (_showFormPanel || _showLowStockPanel) ? 300 : 0,
      child: _showFormPanel ? _buildFormPanel() : _showLowStockPanel ? _buildLowStockPanel() : const SizedBox.shrink(),
    );
  }

  Widget _buildFormPanel() {
    return Container(
      color: const Color(0xffEAEAEA),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isEditing ? 'Editar Producto' : 'Agregar Producto', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff362419))),
                IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 20), onPressed: () => setState(() => _showFormPanel = false)),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('Nombre'),
            TextField(controller: _nombreController, decoration: _inputDecoration('Ej. Capuchino')),
            _buildLabel('Cantidad'),
            TextField(controller: _cantidadController, keyboardType: TextInputType.number, decoration: _inputDecoration('0')),
            _buildLabel('Precio (\$)'),
            TextField(controller: _precioController, keyboardType: TextInputType.number, decoration: _inputDecoration('0.00')),
            _buildLabel('Categoría'),
            TextField(controller: _categoriaController, decoration: _inputDecoration('Bebidas Calientes')),
            _buildLabel('Descripción'),
            TextField(controller: _descripcionController, maxLines: 2, decoration: _inputDecoration('Notas')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff362419), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: _procesarGuardado,
                icon: Icon(_isEditing ? Icons.update : Icons.save, size: 16),
                label: Text(_isEditing ? 'Actualizar' : 'Guardar', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockPanel() {
    return Container(
      color: const Color(0xffEAEAEA),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [Text('Bajo Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff362419))), SizedBox(width: 6), Icon(Icons.warning_amber, color: Colors.red, size: 18)]),
              IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 20), onPressed: () => setState(() => _showLowStockPanel = false)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['Todos', 'Bebidas Calientes', 'Bebidas Frías', 'Postres'].map((cat) {
              bool isSelected = _bajoStockFilter == cat;
              return InkWell(
                onTap: () => _hacerScrollHaciaCategoria(cat),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xff362419) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? const Color(0xff362419) : Colors.grey[300]!),
                  ),
                  child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : const Color(0xff362419), fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Expanded(
            // ✅ OPTIMIZACIÓN: Ya no hay StreamBuilder aquí. Usamos los datos precalculados.
            child: _documentosBajoStock.isEmpty 
              ? const Center(child: Text('Sin productos con bajo stock', style: TextStyle(color: Colors.grey, fontSize: 12)))
              : ListView.separated(
                  controller: _bajoStockScrollController,
                  itemCount: _documentosBajoStock.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = _documentosBajoStock[index].data() as Map<String, dynamic>;
                    return ListTile(
                      dense: true,
                      title: Text(data['nombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      subtitle: Text('Stock: ${data['cantidad']}', style: const TextStyle(color: Colors.red, fontSize: 11)),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, top: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xff362419))),
    );
  }
}

// ============================================================================
// WIDGET DE TARJETA DE PRODUCTO (Extraído para máximo rendimiento)
// ============================================================================
class _ProductoCardInventario extends StatelessWidget {
  final DocumentSnapshot producto;
  final Map<String, dynamic> data;
  final Map<String, String> imagenesPorDefecto;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductoCardInventario({
    required this.producto,
    required this.data,
    required this.imagenesPorDefecto,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String nombre = data['nombre']?.toString() ?? 'Sin nombre';
    final int cantidad = int.tryParse(data['cantidad']?.toString() ?? '0') ?? 0;
    final double precio = double.tryParse(data['precio']?.toString() ?? '0.0') ?? 0.0;
    final String categoria = data['categoria']?.toString() ?? 'General';

    String urlImagen = data['url_imagen']?.toString() ?? '';
    if (urlImagen.isEmpty && imagenesPorDefecto.containsKey(nombre)) {
      urlImagen = imagenesPorDefecto[nombre]!;
    }

    final bool tieneStock = cantidad > 0;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
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
                    cacheWidth: 150,  // ✅ Clave para Lighthouse
                    cacheHeight: 150, // ✅ Clave para Lighthouse
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
                  top: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(color: Color(0xff362419), borderRadius: BorderRadius.all(Radius.circular(6))),
                    child: Text(categoria, style: const TextStyle(color: Colors.white, fontSize: 8)),
                  ),
                ),
                if (!tieneStock)
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red[800], borderRadius: BorderRadius.circular(6)),
                      child: const Text('Agotado', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xff362419)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$cantidad uds.', style: TextStyle(color: Colors.grey[700], fontSize: 10)),
                    Text('\$${precio.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xff362419))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xff362419),
                          side: const BorderSide(color: Color(0xff362419), width: 0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 24),
                        ),
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 12),
                        label: const Text('Editar', style: TextStyle(fontSize: 9)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xffE5E5E3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(24, 24),
                      ),
                      icon: const Icon(Icons.delete, color: Colors.red, size: 14),
                      onPressed: onDelete,
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}