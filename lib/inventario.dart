import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final CollectionReference _productosRef = 
      FirebaseFirestore.instance.collection('productos');

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

  @override
  void dispose() {
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

  void _procesarGuardado() async {
    if (_nombreController.text.isEmpty || _cantidadController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos obligatorios')),
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

      _prepararNuevoProducto();
      setState(() {
        _showFormPanel = false; 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Producto actualizado exitosamente' : 'Producto agregado exitosamente'),
            backgroundColor: const Color(0xff362419),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  void _eliminarProducto(String id) async {
    try {
      await _productosRef.doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado'),
            backgroundColor: Color(0xff362419),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
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
      if (categoria == 'Bebidas Calientes') return cat == 'bebidas calientes' || cat == 'bebida caliente';
      if (categoria == 'Bebidas Frías') return cat == 'bebidas frías' || cat == 'bebida fría' || cat == 'bebidas frias' || cat == 'bebida fria';
      return cat == categoria.toLowerCase();
    });

    if (index != -1) {
      double posicionOffset = index * 72.0; 
      _bajoStockScrollController.animateTo(
        posicionOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffCFCFCD),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_selectedFilter == 'Todos')
                                ? 'Inventario Completo ' 
                                : '$_selectedFilter ',
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
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Agregar', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: _productosRef.snapshots(),
                        builder: (context, snapshot) {
                          int totalProductos = 0;
                          double valorTotal = 0;
                          int bajoStock = 0;
                          Set<String> categorias = {};

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
                              
                              if (d['categoria'] != null && d['categoria'].toString().isNotEmpty) {
                                categorias.add(d['categoria'].toString());
                              }
                            }
                          }

                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildSummaryCard(Icons.inventory_2, '$totalProductos', 'Total Productos', Colors.blue),
                              _buildSummaryCard(
                                Icons.warning_amber, 
                                '$bajoStock', 
                                'Bajo Stock', 
                                Colors.red,
                                onTap: () {
                                  setState(() {
                                    _showLowStockPanel = true;
                                    _showFormPanel = false;
                                  });
                                }
                              ),
                              _buildSummaryCard(Icons.category, '${categorias.length}', 'Categorías', Colors.purple),
                              _buildSummaryCard(Icons.attach_money, '\$${valorTotal.toStringAsFixed(2)}', 'Valor Total', Colors.green),
                            ],
                          );
                        }
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPillFilter('Todos', _selectedFilter, (val) => setState(() => _selectedFilter = val)),
                        _buildPillFilter('Bebidas Calientes', _selectedFilter, (val) => setState(() => _selectedFilter = val)),
                        _buildPillFilter('Bebidas Frías', _selectedFilter, (val) => setState(() => _selectedFilter = val)),
                        _buildPillFilter('Postres', _selectedFilter, (val) => setState(() => _selectedFilter = val)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _productosRef.orderBy('nombre').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No hay productos en el inventario.', style: TextStyle(fontSize: 14, color: Color(0xff55453A))));
                        }

                        var docs = snapshot.data!.docs;
                        
                        if (_selectedFilter != 'Todos') {
                          docs = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>?;
                            if (data == null) return false;
                            final cat = (data['categoria'] ?? '').toString().toLowerCase();
                            
                            if (_selectedFilter == 'Bebidas Calientes') {
                              return cat == 'bebidas calientes' || cat == 'bebida caliente';
                            } else if (_selectedFilter == 'Bebidas Frías') {
                              return cat == 'bebidas frías' || cat == 'bebida fría' || cat == 'bebidas frias' || cat == 'bebida fria';
                            }
                            return cat == _selectedFilter.toLowerCase();
                          }).toList();
                        }

                        if (docs.isEmpty) {
                          return const Center(child: Text('No hay productos registrados en esta sección.', style: TextStyle(fontSize: 14, color: Color(0xff55453A))));
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount;
                            double childAspectRatio;

                            if (constraints.maxWidth < 600) {
                              crossAxisCount = 2;
                              childAspectRatio = 0.75;
                            } else if (constraints.maxWidth < 900) {
                              crossAxisCount = 3;
                              childAspectRatio = 0.80;
                            } else if (constraints.maxWidth < 1200) {
                              crossAxisCount = 4;
                              childAspectRatio = 0.85;
                            } else {
                              crossAxisCount = 5;
                              childAspectRatio = 0.90;
                            }

                            return GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10, 
                                childAspectRatio: childAspectRatio, 
                              ),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final producto = docs[index];
                                final data = producto.data() as Map<String, dynamic>?;

                                if (data == null) return const SizedBox.shrink();

                                final String nombre = data['nombre']?.toString() ?? 'Sin nombre';
                                final int cantidad = int.tryParse(data['cantidad']?.toString() ?? '0') ?? 0;
                                final double precio = double.tryParse(data['precio']?.toString() ?? '0.0') ?? 0.0;
                                final String categoria = data['categoria']?.toString() ?? 'Bebidas Calientes';
                                
                                String urlImagen = data['url_imagen']?.toString() ?? '';

                                final Map<String, String> imagenesPorDefecto = {
                                  'Miau Latte': 'https://i.postimg.cc/VvGcnz49/Whats-App-Image-2026-07-15-at-5-44-43-PM.jpg',
                                  'Capuchino Bigotes': 'https://i.postimg.cc/qqbdypQP/Whats-App-Image-2026-07-15-at-5-44-44-PM.jpg',
                                  'Cold Brew Nocturno': 'https://i.postimg.cc/YqYtdDMs/coldbrew.jpg',
                                  'Purr Croissant': 'https://i.postimg.cc/4dDrtZK2/croissant.jpg',
                                  'Michi-Muffin': 'https://i.postimg.cc/Hxqf5HJB/muffin.jpg',
                                };

                                if (imagenesPorDefecto.containsKey(nombre)) {
                                  urlImagen = imagenesPorDefecto[nombre]!;
                                }

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
                                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_cafe, size: 30, color: Color(0xff55453A)),
                                              )
                                            else
                                              const Icon(Icons.local_cafe, size: 30, color: Color(0xff55453A)),
                                            Positioned(
                                              top: 6,
                                              left: 6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                decoration: BoxDecoration(color: const Color(0xff362419), borderRadius: BorderRadius.circular(6)),
                                                child: Text(categoria, style: const TextStyle(color: Colors.white, fontSize: 8)),
                                              ),
                                            ),
                                            if (cantidad <= 5)
                                              Positioned(
                                                top: 6,
                                                right: 6,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.red[800], borderRadius: BorderRadius.circular(6)),
                                                  child: const Text('Bajo', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nombre, 
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xff362419)), 
                                              maxLines: 1, 
                                              overflow: TextOverflow.ellipsis,
                                            ),
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
                                                    onPressed: () => _cargarProductoParaEditar(producto.id, data), 
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
                                                  onPressed: () => _eliminarProducto(producto.id),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      )
                                    ],
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
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: (_showFormPanel || _showLowStockPanel) ? 300 : 0,
            child: _showFormPanel
                ? Container(
                    color: const Color(0xffEAEAEA),
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isEditing ? 'Editar Producto' : 'Agregar Producto',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff362419)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                onPressed: () => setState(() => _showFormPanel = false),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Nombre del producto'),
                          _buildTextField(_nombreController, 'Ej. Capuchino'),
                          _buildLabel('Cantidad (stock)'),
                          _buildTextField(_cantidadController, '0', isNumber: true),
                          _buildLabel('Precio (\$)'),
                          _buildTextField(_precioController, '0.00', isNumber: true),
                          _buildLabel('Categoría'),
                          _buildTextField(_categoriaController, 'Bebidas Calientes'),
                          _buildLabel('Descripción'),
                          _buildTextField(_descripcionController, 'Notas adicionales', maxLines: 2),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff362419),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _procesarGuardado, 
                              icon: Icon(_isEditing ? Icons.update : Icons.save, size: 16),
                              label: Text(
                                _isEditing ? 'Actualizar' : 'Guardar', 
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : _showLowStockPanel 
                    ? Container(
                        color: const Color(0xffEAEAEA),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Text('Bajo Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff362419))),
                                    SizedBox(width: 6),
                                    Icon(Icons.warning_amber, color: Colors.red, size: 18),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                  onPressed: () => setState(() => _showLowStockPanel = false),
                                )
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
                                      border: Border.all(color: isSelected ? const Color(0xff362419) : Colors.grey[300]!)
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xff362419),
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: _productosRef.snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                                  
                                  var docs = snapshot.data!.docs.where((doc) {
                                    final data = doc.data() as Map<String, dynamic>?;
                                    if (data == null) return false;
                                    int cant = int.tryParse(data['cantidad']?.toString() ?? '0') ?? 0;
                                    return cant <= 5;
                                  }).toList();

                                  _documentosBajoStock = docs;

                                  if (docs.isEmpty) {
                                    return const Center(
                                      child: Text('Sin productos con bajo stock', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    );
                                  }

                                  return ListView.separated(
                                    controller: _bajoStockScrollController,
                                    itemCount: docs.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final producto = docs[index];
                                      final data = producto.data() as Map<String, dynamic>;
                                      final String nombre = data['nombre']?.toString() ?? 'Sin nombre';
                                      final String cant = data['cantidad']?.toString() ?? '0';

                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(color: const Color(0xffCFCFCD), borderRadius: BorderRadius.circular(6)),
                                          child: const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                                        ),
                                        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xff362419))),
                                        subtitle: Text('Stock: $cant uds.', style: TextStyle(color: Colors.red[800], fontSize: 10)),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.edit, size: 16, color: Color(0xff55453A)),
                                          onPressed: () => _cargarProductoParaEditar(producto.id, data),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      );
                                    },
                                  );
                                }
                              ),
                            )
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }

  Widget _buildPillFilter(String text, String selectedValue, Function(String) onSelect) {
    bool isSelected = text == selectedValue;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(text, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) onSelect(text);
        },
        selectedColor: const Color(0xff362419),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xff362419),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.transparent),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildSummaryCard(IconData icon, String value, String title, Color color, {VoidCallback? onTap}) {
    return SizedBox(
      width: 180,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff362419))),
                      Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xff55453A))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    );
  }
}