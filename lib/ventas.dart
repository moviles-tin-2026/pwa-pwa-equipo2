import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/auth_service.dart';

// ============================================================================
// MODELO DE DATOS PARA EL CARRITO
// ============================================================================
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

// ============================================================================
// PÁGINA PRINCIPAL DE VENTAS
// ============================================================================
class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final CollectionReference _productosRef = FirebaseFirestore.instance.collection('productos');
  final CollectionReference _ventasRef = FirebaseFirestore.instance.collection('ventas');
  final AuthService _authService = AuthService();
  late final Stream<QuerySnapshot> _productosStream;

  final List<ItemCarrito> _carrito = [];
  String? _metodoPago;
  bool _procesandoVenta = false;
  final TextEditingController _efectivoController = TextEditingController();

  double get _totalVenta => _carrito.fold(0.0, (total, item) => total + item.subtotal);
  bool get _puedeVerStockExacto => _authService.esSupervisor;
  bool get _puedeCancelarOrden => _authService.esSupervisor;

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
    _productosStream = _productosRef.orderBy('nombre').snapshots();
  }

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

  void _mostrarMensaje(String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _vaciarOrden() {
    setState(() {
      _carrito.clear();
      _metodoPago = null;
      _efectivoController.clear();
    });
    _mostrarMensaje('Orden cancelada', Colors.orange.shade800);
  }

  Future<bool> _solicitarDatosTarjeta() async {
    final nombreController = TextEditingController();
    final numeroController = TextEditingController();
    final vencimientoController = TextEditingController();
    final cvvController = TextEditingController();
    bool ocultarCvv = true;
    bool mostrarReverso = false;
    String? errorValidacion;

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Row(
                children: [
                  Icon(Icons.credit_card_rounded, color: Color(0xff362419)),
                  SizedBox(width: 10),
                  Text(
                    'Pago con tarjeta',
                    style: TextStyle(
                      color: Color(0xff362419),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTarjetaAnimada(
                          nombre: nombreController.text,
                          numero: numeroController.text,
                          vencimiento: vencimientoController.text,
                          cvv: cvvController.text,
                          mostrarReverso: mostrarReverso,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: nombreController,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => setDialogState(() {}),
                          decoration: _inputTarjeta(
                            'Nombre del titular',
                            Icons.person_outline_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: numeroController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                          onChanged: (_) => setDialogState(() {}),
                          decoration: _inputTarjeta(
                            'Número de tarjeta',
                            Icons.credit_card_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: vencimientoController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FechaVencimientoFormatter(),
                                ],
                                onChanged: (_) => setDialogState(() {}),
                                decoration: _inputTarjeta(
                                  'MM/AA',
                                  Icons.calendar_month_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Focus(
                                onFocusChange: (tieneFoco) {
                                  setDialogState(() {
                                    mostrarReverso = tieneFoco;
                                  });
                                },
                                child: TextField(
                                  controller: cvvController,
                                  obscureText: ocultarCvv,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  onChanged: (_) => setDialogState(() {}),
                                  decoration:
                                      _inputTarjeta(
                                        'CVV',
                                        Icons.lock_outline_rounded,
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setDialogState(() {
                                              ocultarCvv = !ocultarCvv;
                                            });
                                          },
                                          icon: Icon(
                                            ocultarCvv
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (errorValidacion != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              errorValidacion!,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.blue,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Simulación académica. Los datos de la tarjeta no se guardan.',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff362419),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    String? error;
                    if (nombreController.text.trim().length < 3) {
                      error = 'Ingresa el nombre del titular';
                    } else if (numeroController.text.length != 16) {
                      error = 'Ingresa los 16 dígitos de la tarjeta';
                    } else if (!RegExp(
                      r'^(0[1-9]|1[0-2])\/\d{2}$',
                    ).hasMatch(vencimientoController.text)) {
                      error = 'Ingresa una fecha válida con formato MM/AA';
                    } else if (cvvController.text.length < 3) {
                      error = 'Ingresa un CVV válido';
                    }

                    if (error == null) {
                      Navigator.pop(dialogContext, true);
                    } else {
                      setDialogState(() => errorValidacion = error);
                    }
                  },
                  icon: const Icon(Icons.lock_outline_rounded, size: 17),
                  label: Text('Pagar \$${_totalVenta.toStringAsFixed(2)}'),
                ),
              ],
            );
          },
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 600));
    nombreController.dispose();
    numeroController.dispose();
    vencimientoController.dispose();
    cvvController.dispose();
    return resultado ?? false;
  }

  Widget _buildTarjetaAnimada({
    required String nombre,
    required String numero,
    required String vencimiento,
    required String cvv,
    required bool mostrarReverso,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: mostrarReverso ? math.pi : 0),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      builder: (context, angulo, child) {
        final parteTrasera = angulo > math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angulo),
          child: parteTrasera
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: _buildReversoTarjeta(cvv),
                )
              : _buildFrenteTarjeta(
                  nombre: nombre,
                  numero: numero,
                  vencimiento: vencimiento,
                ),
        );
      },
    );
  }

  Widget _buildFrenteTarjeta({
    required String nombre,
    required String numero,
    required String vencimiento,
  }) {
    final nombreVisible = nombre.trim().isEmpty
        ? 'NOMBRE DEL TITULAR'
        : nombre.trim().toUpperCase();
    final fechaVisible = vencimiento.trim().isEmpty ? 'MM/AA' : vencimiento;

    return _contenedorTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.memory_rounded, color: Color(0xffE7C873), size: 34),
              Icon(Icons.contactless_rounded, color: Colors.white, size: 31),
            ],
          ),
          const Spacer(),
          Text(
            _formatearNumeroTarjeta(numero),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: Text(
                  nombreVisible,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                fechaVisible,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          const Text(
            'COFFEE CAT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReversoTarjeta(String cvv) {
    return _contenedorTarjeta(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 27),
          Container(height: 48, color: const Color(0xff17120F)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                cvv.trim().isEmpty ? '•••' : cvv.trim(),
                style: const TextStyle(
                  color: Color(0xff362419),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 17),
            child: Text(
              'COFFEE CAT · PAGO SEGURO',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenedorTarjeta({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(21),
  }) {
    return Container(
      width: double.infinity,
      height: 205,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff362419), Color(0xff6F4E37), Color(0xff8B634A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff362419).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }

  String _formatearNumeroTarjeta(String numero) {
    final digitos = numero.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      buffer.write(i < digitos.length ? digitos[i] : '•');
      if ((i + 1) % 4 == 0 && i != 15) buffer.write('  ');
    }
    return buffer.toString();
  }

  InputDecoration _inputTarjeta(String texto, IconData icono) {
    return InputDecoration(
      labelText: texto,
      prefixIcon: Icon(icono),
      filled: true,
      fillColor: const Color(0xffF6F1EC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffE8DDD3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xff362419), width: 1.5),
      ),
    );
  }

  Future<void> _procesarVenta() async {
    if (_procesandoVenta) return;

    if (_carrito.isEmpty) {
      _mostrarMensaje('Agrega productos al carrito', Colors.orange);
      return;
    }
    if (_metodoPago == null) {
      _mostrarMensaje('Selecciona método de pago', Colors.orange);
      return;
    }

    double? efectivoRecibido;
    if (_metodoPago == 'efectivo') {
      efectivoRecibido = double.tryParse(
        _efectivoController.text.trim().replaceAll(',', '.'),
      );
      if (efectivoRecibido == null) {
        _mostrarMensaje('Ingresa el efectivo recibido', Colors.orange);
        return;
      }
      if (efectivoRecibido < _totalVenta) {
        _mostrarMensaje('El efectivo recibido es menor al total', Colors.red);
        return;
      }
    }

    if (_metodoPago == 'tarjeta') {
      setState(() => _procesandoVenta = true);
      final pagoConfirmado = await _solicitarDatosTarjeta();
      if (!mounted) return;
      setState(() => _procesandoVenta = false);
      if (!pagoConfirmado) return;
    }

    if (!mounted) return;
    setState(() => _procesandoVenta = true);

    try {
      final usuarioEmail = FirebaseAuth.instance.currentUser?.email ?? 'desconocido';
      final itemsParaGuardar = _carrito.map((item) => {
        'id': item.id,
        'nombre': item.nombre,
        'precio': item.precio,
        'cantidad': item.cantidad,
      }).toList();
      final total = _totalVenta;
      final metodo = _metodoPago;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final stocksActuales = <String, int>{};

        for (var item in _carrito) {
          final productoRef = _productosRef.doc(item.id);
          final productoDoc = await transaction.get(productoRef);
          
          if (!productoDoc.exists) throw Exception('Producto ${item.nombre} ya no existe');
          
          final stockActual = ((productoDoc.data() as Map<String, dynamic>?)?['cantidad'] as num?)?.toInt() ?? 0;
          if (stockActual < item.cantidad) {
            throw Exception('Stock insuficiente para ${item.nombre}');
          }

          stocksActuales[item.id] = stockActual;
        }

        for (var item in _carrito) {
          final productoRef = _productosRef.doc(item.id);
          transaction.update(productoRef, {
            'cantidad': stocksActuales[item.id]! - item.cantidad,
            'fecha_modificacion': FieldValue.serverTimestamp(),
          });
        }

        final nuevaVentaRef = _ventasRef.doc();
        transaction.set(nuevaVentaRef, {
          'productos': itemsParaGuardar,
          'total': total,
          'metodo_pago': metodo,
          'fecha': FieldValue.serverTimestamp(),
          'usuario': usuarioEmail,
        });
      });

      if (mounted) {
        setState(() => _procesandoVenta = false);
        _mostrarExitoDialog(efectivoRecibido);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _procesandoVenta = false);
        _mostrarMensaje('Error: $e', Colors.red);
      }
    }
  }

  void _mostrarExitoDialog(double? efectivoRecibido) {
    final cambio = (efectivoRecibido ?? 0) - _totalVenta;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Venta Exitosa', style: TextStyle(color: Color(0xff362419), fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: \$${_totalVenta.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (_metodoPago == 'efectivo' && efectivoRecibido != null) ...[
              const SizedBox(height: 8),
              Text('Efectivo: \$${efectivoRecibido.toStringAsFixed(2)}'),
              Text('Cambio: \$${cambio.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
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
            child: const Text('Aceptar', style: TextStyle(color: Color(0xff362419), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRolChip() {
    final usuario = _authService.usuarioActual;
    final esAdmin = _authService.esAdmin;
    final esSupervisor = _authService.esSupervisor && !esAdmin;
    final color = esAdmin
        ? Colors.deepPurple
        : esSupervisor
        ? Colors.blue.shade700
        : const Color(0xff6F4E37);
    final icono = esAdmin
        ? Icons.admin_panel_settings_rounded
        : esSupervisor
        ? Icons.supervisor_account_rounded
        : Icons.point_of_sale_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario?.rolLabel ?? 'Usuario',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (usuario != null)
                Text(
                  usuario.nombre,
                  style: const TextStyle(color: Colors.black54, fontSize: 9),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final bool isMobile = outerConstraints.maxWidth < 800;

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ventas 💰',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff362419),
                          ),
                        ),
                        Text(
                          'Coffee Cat - Punto de venta',
                          style: TextStyle(
                            color: Color(0xff55453A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildRolChip(),
                ],
              ),
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
                stream: _productosStream,
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
                            key: ValueKey(producto.id),
                            producto: producto,
                            data: data,
                            imagenesPorDefecto: _imagenesPorDefecto,
                            mostrarStockExacto: _puedeVerStockExacto,
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '🛒 Orden de Venta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff362419),
                    ),
                  ),
                ),
                if (_puedeCancelarOrden && _carrito.isNotEmpty)
                  IconButton(
                    tooltip: 'Cancelar orden',
                    onPressed: _vaciarOrden,
                    icon: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.redAccent,
                    ),
                  ),
              ],
            ),
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
                      key: ValueKey(item.id),
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
                  onSelected: (s) => setState(() {
                    _metodoPago = s ? 'efectivo' : null;
                  }),
                  selectedColor: const Color(0xff362419),
                  labelStyle: TextStyle(color: _metodoPago == 'efectivo' ? Colors.white : Colors.black87),
                ),
                ChoiceChip(
                  label: const Text('Tarjeta', style: TextStyle(fontSize: 11)),
                  selected: _metodoPago == 'tarjeta',
                  onSelected: (s) => setState(() {
                    _metodoPago = s ? 'tarjeta' : null;
                    if (s) _efectivoController.clear();
                  }),
                  selectedColor: const Color(0xff362419),
                  labelStyle: TextStyle(color: _metodoPago == 'tarjeta' ? Colors.white : Colors.black87),
                ),
              ],
            ),
            if (_metodoPago == 'efectivo') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _efectivoController,
                keyboardType: TextInputType.number,
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
                onPressed: _carrito.isEmpty || _procesandoVenta
                    ? null
                    : _procesarVenta,
                child: _procesandoVenta
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'PROCESAR VENTA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

// ============================================================================
// WIDGETS EXTRAÍDOS (Aíslan los rebuilds para máximo rendimiento)
// ============================================================================

class _ProductoCard extends StatelessWidget {
  final DocumentSnapshot producto;
  final Map<String, dynamic> data;
  final Map<String, String> imagenesPorDefecto;
  final bool mostrarStockExacto;
  final VoidCallback onTap;

  const _ProductoCard({
    super.key,
    required this.producto,
    required this.data,
    required this.imagenesPorDefecto,
    required this.mostrarStockExacto,
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
                        gaplessPlayback: true,
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
                            color: Colors.red[800],
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
                      mostrarStockExacto
                          ? '$cantidad disp.'
                          : tieneStock
                          ? 'Disponible'
                          : 'Agotado',
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
    super.key,
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
                  gaplessPlayback: true,
                  cacheWidth: 80,
                  cacheHeight: 80,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_cafe, size: 24), // ✅ CORREGIDO
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

class FechaVencimientoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String numeros = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (numeros.length > 4) numeros = numeros.substring(0, 4);

    final textoFormateado = numeros.length > 2
        ? '${numeros.substring(0, 2)}/${numeros.substring(2)}'
        : numeros;

    return TextEditingValue(
      text: textoFormateado,
      selection: TextSelection.collapsed(offset: textoFormateado.length),
    );
  }
}
