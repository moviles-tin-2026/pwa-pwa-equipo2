import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _productosRef = 
      FirebaseFirestore.instance.collection('productos');

  final _nombreController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _descripcionController = TextEditingController();

  // Estados dinámicos de la interfaz
  bool _showFormPanel = false;      
  bool _showSidebar = true;         
  bool _isEditing = false;          
  String? _editingProductId;        

  // Estados nuevos para el panel de Bajo Stock y los Filtros
  bool _showLowStockPanel = false;
  String _selectedFilter = 'Todos';
  String _bajoStockFilter = 'Todos';
  
  // Controlador para el autoscroll del panel de bajo stock
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

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  // LÓGICA DE SCROLL PARA EL PANEL DE BAJO STOCK
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
          // 1. SIDEBAR IZQUIERDO (Categorías del Menú Coffee Cat)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _showSidebar ? 240 : 0,
            child: _showSidebar
                ? Container(
                    color: const Color(0xff362419),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 48,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ¡AQUÍ ESTÁ TU LOGO RESTAURADO!
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/logo1.png', width: 35, height: 35),
                                const SizedBox(width: 8),
                                const Text(
                                  'Coffee Cat',
                                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Center(
                              child: Text('Inventario', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ),
                            const SizedBox(height: 40),
                            _buildSidebarItem(Icons.grid_view, 'Catálogo Completo', isActive: _selectedFilter == 'Todos', onTap: () => setState(() => _selectedFilter = 'Todos')),
                            _buildSidebarItem(Icons.add_box, 'Agregar Producto', onTap: _prepararNuevoProducto),
                            const Divider(color: Colors.white24, height: 32),
                            
                            _buildSidebarItem(Icons.local_cafe, 'Bebidas Calientes', isActive: _selectedFilter == 'Bebidas Calientes', onTap: () => setState(() => _selectedFilter = 'Bebidas Calientes')),
                            _buildSidebarItem(Icons.icecream, 'Bebidas Frías', isActive: _selectedFilter == 'Bebidas Frías', onTap: () => setState(() => _selectedFilter = 'Bebidas Frías')),
                            _buildSidebarItem(Icons.cake, 'Postres', isActive: _selectedFilter == 'Postres', onTap: () => setState(() => _selectedFilter = 'Postres')),
                            const Spacer(),
                            _buildSidebarItem(Icons.logout, 'Cerrar Sesión', onTap: _cerrarSesion),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 2. CONTENIDO CENTRAL RESPONSIVO
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra Superior
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(_showSidebar ? Icons.menu_open : Icons.menu, color: const Color(0xff362419), size: 28),
                            onPressed: () => setState(() => _showSidebar = !_showSidebar),
                            tooltip: 'Alternar menú lateral',
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (_selectedFilter == 'Todos' || _selectedFilter == 'undefined')
                                    ? 'Inventario Completo 🐾' 
                                    : '$_selectedFilter 🐾',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xff362419)),
                              ),
                              const Text('Coffee Cat - Gestión de productos', style: TextStyle(color: Color(0xff55453A))),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff362419), foregroundColor: Colors.white),
                        onPressed: _prepararNuevoProducto, 
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar Producto'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // TARJETAS SUPERIORES CONECTADAS EN TIEMPO REAL A FIREBASE
                  StreamBuilder<QuerySnapshot>(
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

                      return Row(
                        children: [
                          _buildSummaryCard(Icons.inventory_2, '$totalProductos', 'Total Productos'),
                          const SizedBox(width: 16),
                          // TARJETA INTERACTIVA DE BAJO STOCK
                          _buildSummaryCard(
                            Icons.warning_amber, 
                            '$bajoStock', 
                            'Bajo Stock', 
                            isAlert: bajoStock > 0,
                            onTap: () {
                              setState(() {
                                _showLowStockPanel = true;
                                _showFormPanel = false;
                              });
                            }
                          ),
                          const SizedBox(width: 16),
                          _buildSummaryCard(Icons.category, '${categorias.length}', 'Categorías'),
                          const SizedBox(width: 16),
                          _buildSummaryCard(Icons.attach_money, '\$${valorTotal.toStringAsFixed(2)}', 'Valor Total'),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 16),

                  // FILTRO ESTILO PÍLDORA DEL INVENTARIO
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

                  // GRILLA DE PRODUCTOS
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _productosRef.snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No hay productos en el inventario.', style: TextStyle(fontSize: 16, color: Color(0xff55453A))));
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
                          return const Center(child: Text('No hay productos registrados en esta sección.', style: TextStyle(fontSize: 16, color: Color(0xff55453A))));
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 3;
                            double targetAspectRatio = 1.05;

                            if (constraints.maxWidth < 750) {
                              crossAxisCount = 1;
                              targetAspectRatio = 1.3;
                            } else if (constraints.maxWidth < 1150) {
                              crossAxisCount = 2;
                              targetAspectRatio = 1.05;
                            } else if (constraints.maxWidth < 1550) {
                              crossAxisCount = 3;
                              targetAspectRatio = 1.05;
                            } else {
                              crossAxisCount = 4;
                              targetAspectRatio = 1.05;
                            }

                            return GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16, 
                                childAspectRatio: targetAspectRatio, 
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
                                
                                // INYECCIÓN ESTÁTICA DE TUS IMÁGENES
                                String urlImagen = data['url_imagen']?.toString() ?? '';
                                if (nombre == 'Rebanada de Pastel de Zanahoria') {
                                  urlImagen = 'https://i.postimg.cc/VvGcnz49/Whats-App-Image-2026-07-15-at-5-44-43-PM.jpg';
                                } else if (nombre == 'Gato Negro') {
                                  urlImagen = 'https://i.postimg.cc/qqbdypQP/Whats-App-Image-2026-07-15-at-5-44-44-PM.jpg';
                                }

                                return Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  clipBehavior: Clip.antiAlias,
                                  elevation: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              height: double.infinity,
                                              color: const Color(0xffE5E5E3),
                                              child: urlImagen.isNotEmpty
                                                  ? Image.network(
                                                      urlImagen, 
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 50, color: Color(0xff55453A)),
                                                    )
                                                  : const Icon(Icons.local_cafe, size: 50, color: Color(0xff55453A)),
                                            ),
                                            Positioned(
                                              top: 8,
                                              left: 8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(color: const Color(0xff362419), borderRadius: BorderRadius.circular(12)),
                                                child: Text(categoria, style: const TextStyle(color: Colors.white, fontSize: 10)),
                                              ),
                                            ),
                                            if (cantidad <= 5)
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: Colors.red[800], borderRadius: BorderRadius.circular(12)),
                                                  child: const Text('Bajo stock', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff362419)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('$cantidad uds.', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                                                Text('\$${precio.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff362419))),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: const Color(0xff362419),
                                                      side: const BorderSide(color: Color(0xff362419)),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                    onPressed: () => _cargarProductoParaEditar(producto.id, data), 
                                                    icon: const Icon(Icons.edit, size: 14),
                                                    label: const Text('Editar', style: TextStyle(fontSize: 12)),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: const Color(0xffE5E5E3),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
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

          // 3. PANELES LATERALES DERECHOS (FORMULARIO O BAJO STOCK)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: (_showFormPanel || _showLowStockPanel) ? 320 : 0,
            child: _showFormPanel
                ? Container(
                    color: const Color(0xffEAEAEA),
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isEditing ? 'Editar Producto' : 'Agregar Producto',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff362419)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => setState(() => _showFormPanel = false),
                                tooltip: 'Cerrar panel',
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          _buildLabel('NOMBRE DEL PRODUCTO'),
                          _buildTextField(_nombreController, 'Ej. Gato Negro / Michi Mocha'),
                          
                          _buildLabel('CANTIDAD (STOCK)'),
                          _buildTextField(_cantidadController, '0', isNumber: true),
                          
                          _buildLabel('PRECIO (\$)'),
                          _buildTextField(_precioController, '0.00', isNumber: true),
                          
                          _buildLabel('CATEGORÍA'),
                          _buildTextField(_categoriaController, 'Bebidas Calientes / Bebidas Frías / Postres'),
                          
                          _buildLabel('DESCRIPCIÓN / NOTAS'),
                          _buildTextField(_descripcionController, 'Ingredientes o notas adicionales...', maxLines: 3),
                          
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff362419),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _procesarGuardado, 
                              icon: Icon(_isEditing ? Icons.update : Icons.save, size: 18),
                              label: Text(
                                _isEditing ? 'Actualizar Producto' : 'Guardar Producto', 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Text('Bajo Stock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff362419))),
                                    SizedBox(width: 8),
                                    Icon(Icons.warning_amber, color: Colors.red),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => setState(() => _showLowStockPanel = false),
                                  tooltip: 'Cerrar panel',
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            // LA SOLUCIÓN: Usamos "Wrap" en lugar de Row para que los botones bajen a la siguiente línea si no caben
                            Wrap(
                              spacing: 8.0, // espacio horizontal
                              runSpacing: 8.0, // espacio vertical
                              children: ['Todos', 'Bebidas Calientes', 'Bebidas Frías', 'Postres'].map((cat) {
                                bool isSelected = _bajoStockFilter == cat;
                                return InkWell(
                                  onTap: () => _hacerScrollHaciaCategoria(cat),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xff362419) : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isSelected ? const Color(0xff362419) : Colors.grey[300]!)
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xff362419),
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: _productosRef.snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                                  
                                  // Solo cargamos los productos con cantidad <= 5 en esta lista general
                                  var docs = snapshot.data!.docs.where((doc) {
                                    final data = doc.data() as Map<String, dynamic>?;
                                    if (data == null) return false;
                                    int cant = int.tryParse(data['cantidad']?.toString() ?? '0') ?? 0;
                                    return cant <= 5;
                                  }).toList();

                                  _documentosBajoStock = docs; // Guardamos para la lógica del Scroll

                                  if (docs.isEmpty) {
                                    return const Center(
                                      child: Text('No hay productos con bajo stock en este momento.', textAlign: TextAlign.center),
                                    );
                                  }

                                  return ListView.separated(
                                    controller: _bajoStockScrollController, // Controlador de posición
                                    itemCount: docs.length,
                                    separatorBuilder: (context, index) => const Divider(color: Colors.black12),
                                    itemBuilder: (context, index) {
                                      final producto = docs[index];
                                      final data = producto.data() as Map<String, dynamic>;
                                      final String nombre = data['nombre']?.toString() ?? 'Sin nombre';
                                      final String cant = data['cantidad']?.toString() ?? '0';

                                      // INYECCIÓN ESTÁTICA PARA EL PANEL LATERAL TAMBIÉN
                                      String urlImagen = data['url_imagen']?.toString() ?? '';
                                      if (nombre == 'Rebanada de Pastel de Zanahoria') {
                                        urlImagen = 'https://i.postimg.cc/VvGcnz49/Whats-App-Image-2026-07-15-at-5-44-43-PM.jpg';
                                      } else if (nombre == 'Gato Negro') {
                                        urlImagen = 'https://i.postimg.cc/qqbdypQP/Whats-App-Image-2026-07-15-at-5-44-44-PM.jpg';
                                      }

                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Container(
                                          width: 45,
                                          height: 45,
                                          decoration: BoxDecoration(color: const Color(0xffCFCFCD), borderRadius: BorderRadius.circular(8)),
                                          clipBehavior: Clip.antiAlias,
                                          child: urlImagen.isNotEmpty
                                              ? Image.network(urlImagen, fit: BoxFit.cover)
                                              : const Icon(Icons.warning_amber, color: Colors.red),
                                        ),
                                        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff362419))),
                                        subtitle: Text('Stock: $cant uds.', style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold, fontSize: 12)),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.edit, size: 18, color: Color(0xff55453A)),
                                          onPressed: () => _cargarProductoParaEditar(producto.id, data),
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

  // WIDGET: Filtro estilo píldora
  Widget _buildPillFilter(String text, String selectedValue, Function(String) onSelect) {
    bool isSelected = text == selectedValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(text),
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
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.transparent),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {bool isActive = false, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isActive ? Colors.white : const Color(0xffCFCFCD), size: 20),
      title: Text(title, style: TextStyle(color: isActive ? Colors.white : const Color(0xffCFCFCD), fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      dense: true,
      tileColor: isActive ? const Color(0xff55453A) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // TARJETA DE RESUMEN CON INTERACCIÓN CLARA
  Widget _buildSummaryCard(IconData icon, String value, String title, {bool isAlert = false, VoidCallback? onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(12),
              // Añade un pequeño sombreado y borde para destacar si tiene función "onTap"
              border: isAlert && onTap != null ? Border.all(color: Colors.red.shade300, width: 1.5) : null,
              boxShadow: onTap != null ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: isAlert ? Colors.red[100] : const Color(0xffE5E5E3), borderRadius: BorderRadius.circular(8)),
                      child: Icon(icon, color: isAlert ? Colors.red : const Color(0xff362419), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff362419))),
                          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    )
                  ],
                ),
                // Ícono indicador de que la tarjeta se puede presionar
                if (onTap != null)
                  const Positioned(
                    right: -4,
                    top: -4,
                    child: Icon(Icons.touch_app, size: 16, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff55453A))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    );
  }
}