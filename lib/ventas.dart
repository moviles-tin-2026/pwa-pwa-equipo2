import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  static const Color cafeOscuro = Color(0xff362419);
  static const Color cafeMedio = Color(0xff6F4E37);
  static const Color cafeClaro = Color(0xffB78E6A);
  static const Color crema = Color(0xffF6F1EC);
  static const Color borde = Color(0xffE8DDD3);

  final CollectionReference _productosRef = FirebaseFirestore.instance
      .collection('productos');

  final CollectionReference _ventasRef = FirebaseFirestore.instance.collection(
    'ventas',
  );

  late final Stream<QuerySnapshot> _productosStream;

  final List<Map<String, dynamic>> _carrito = [];

  String? _metodoPago;
  bool _procesandoVenta = false;

  final TextEditingController _efectivoController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _productosStream = _productosRef.orderBy('nombre').snapshots();
  }

  double get _totalVenta {
    return _carrito.fold(
      0,
      (total, item) =>
          total +
          ((item['precio'] as num).toDouble() * (item['cantidad'] as int)),
    );
  }

  int get _totalArticulos {
    return _carrito.fold(0, (total, item) => total + (item['cantidad'] as int));
  }

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> _seleccionarCantidad(DocumentSnapshot producto) async {
    final data = producto.data() as Map<String, dynamic>;

    final int stockDisponible =
        int.tryParse((data['cantidad'] ?? 0).toString()) ?? 0;

    if (stockDisponible <= 0) {
      _mostrarMensaje('Producto no disponible', Colors.red);
      return;
    }

    final String nombre = (data['nombre'] ?? 'Sin nombre').toString();

    final double precio =
        double.tryParse((data['precio'] ?? 0).toString()) ?? 0;

    int cantidadSeleccionada = 1;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool llegoAlLimite = cantidadSeleccionada >= stockDisponible;

            return Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xffEFE5DC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_cafe_rounded,
                        color: cafeMedio,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: cafeOscuro,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '\$${precio.toStringAsFixed(2)} por unidad',
                      style: const TextStyle(color: cafeMedio),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Selecciona la cantidad',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: crema,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _botonSelector(
                            icono: Icons.remove_rounded,
                            habilitado: cantidadSeleccionada > 1,
                            onPressed: () {
                              setModalState(() {
                                cantidadSeleccionada--;
                              });
                            },
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              '$cantidadSeleccionada',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: cafeOscuro,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _botonSelector(
                            icono: Icons.add_rounded,
                            habilitado: !llegoAlLimite,
                            onPressed: () {
                              setModalState(() {
                                cantidadSeleccionada++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (llegoAlLimite) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Máximo disponible seleccionado',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cafeOscuro,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(bottomContext);

                          _agregarCantidadAlCarrito(
                            producto,
                            cantidadSeleccionada,
                          );
                        },
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: Text(
                          'Agregar $cantidadSeleccionada a la orden',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _botonSelector({
    required IconData icono,
    required bool habilitado,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: habilitado ? onPressed : null,
      style: IconButton.styleFrom(
        backgroundColor: habilitado ? cafeOscuro : Colors.grey.shade300,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.grey.shade500,
      ),
      icon: Icon(icono),
    );
  }

  void _agregarCantidadAlCarrito(
    DocumentSnapshot producto,
    int cantidadAgregar,
  ) {
    final data = producto.data() as Map<String, dynamic>;

    final int stockDisponible =
        int.tryParse((data['cantidad'] ?? 0).toString()) ?? 0;

    final index = _carrito.indexWhere((item) => item['id'] == producto.id);

    final int cantidadActual = index == -1
        ? 0
        : _carrito[index]['cantidad'] as int;

    if (cantidadActual + cantidadAgregar > stockDisponible) {
      _mostrarMensaje(
        'La cantidad seleccionada ya no está disponible',
        Colors.orange,
      );
      return;
    }

    setState(() {
      if (index != -1) {
        _carrito[index]['cantidad'] = cantidadActual + cantidadAgregar;
      } else {
        _carrito.add({
          'id': producto.id,
          'nombre': data['nombre'] ?? 'Sin nombre',
          'precio': double.tryParse((data['precio'] ?? 0).toString()) ?? 0,
          'cantidad': cantidadAgregar,
          'stockMaximo': stockDisponible,
        });
      }
    });

    _mostrarMensaje(
      '$cantidadAgregar producto(s) agregados',
      Colors.green.shade700,
    );
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

    final index = _carrito.indexWhere((item) => item['id'] == id);

    if (index == -1) return;

    final stockMax = _carrito[index]['stockMaximo'] as int;

    if (nuevaCantidad > stockMax) {
      _mostrarMensaje('No hay más unidades disponibles', Colors.orange);
      return;
    }

    setState(() {
      _carrito[index]['cantidad'] = nuevaCantidad;
    });
  }

  Future<bool> _solicitarDatosTarjeta() async {
    final formKey = GlobalKey<FormState>();

    final nombreController = TextEditingController();

    final numeroController = TextEditingController();

    final vencimientoController = TextEditingController();

    final cvvController = TextEditingController();

    bool ocultarCvv = true;
    bool mostrarReverso = false;

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
                  Icon(Icons.credit_card_rounded, color: cafeOscuro),
                  SizedBox(width: 10),
                  Text(
                    'Pago con tarjeta',
                    style: TextStyle(
                      color: cafeOscuro,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
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
                        TextFormField(
                          controller: nombreController,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (value) {
                            setDialogState(() {});
                          },
                          decoration: _inputDecoration(
                            'Nombre del titular',
                            Icons.person_outline_rounded,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 3) {
                              return 'Ingresa el nombre del titular';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: numeroController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                          onChanged: (value) {
                            setDialogState(() {});
                          },
                          decoration: _inputDecoration(
                            'Número de tarjeta',
                            Icons.credit_card_rounded,
                          ),
                          validator: (value) {
                            if (value == null || value.length != 16) {
                              return 'Ingresa los 16 dígitos';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: vencimientoController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FechaVencimientoFormatter()],
                                onChanged: (value) {
                                  setDialogState(() {});
                                },
                                decoration: _inputDecoration(
                                  'MM/AA',
                                  Icons.calendar_month_outlined,
                                ),
                                validator: (value) {
                                  final formatoValido = RegExp(
                                    r'^(0[1-9]|1[0-2])\/\d{2}$',
                                  ).hasMatch(value ?? '');

                                  if (!formatoValido) {
                                    return 'Formato MM/AA';
                                  }

                                  return null;
                                },
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
                                child: TextFormField(
                                  controller: cvvController,
                                  obscureText: ocultarCvv,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  onChanged: (value) {
                                    setDialogState(() {});
                                  },
                                  decoration:
                                      _inputDecoration(
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
                                  validator: (value) {
                                    if (value == null || value.length < 3) {
                                      return 'CVV inválido';
                                    }

                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
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
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cafeOscuro,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext, true);
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
        final bool parteTrasera = angulo > math.pi / 2;

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
    final String nombreVisible = nombre.trim().isEmpty
        ? 'NOMBRE DEL TITULAR'
        : nombre.trim().toUpperCase();

    final String numeroVisible = _formatearNumeroTarjeta(numero);

    final String fechaVisible = vencimiento.trim().isEmpty
        ? 'MM/AA'
        : vencimiento.trim();

    return Container(
      width: double.infinity,
      height: 205,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff362419), Color(0xff6F4E37), Color(0xff8B634A)],
        ),
        boxShadow: [
          BoxShadow(
            color: cafeOscuro.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 31,
                decoration: BoxDecoration(
                  color: const Color(0xffE7C873),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.memory_rounded,
                  color: Color(0xff8B6B27),
                  size: 22,
                ),
              ),
              const Icon(
                Icons.contactless_rounded,
                color: Colors.white,
                size: 31,
              ),
            ],
          ),
          const Spacer(),
          Text(
            numeroVisible,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TITULAR',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nombreVisible,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VÁLIDA HASTA',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
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
            ],
          ),
          const SizedBox(height: 12),
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
    final String cvvVisible = cvv.trim().isEmpty ? '•••' : cvv.trim();

    return Container(
      width: double.infinity,
      height: 205,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff362419), Color(0xff6F4E37), Color(0xff8B634A)],
        ),
        boxShadow: [
          BoxShadow(
            color: cafeOscuro.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 26),
          Container(
            width: double.infinity,
            height: 48,
            color: const Color(0xff17120F),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CÓDIGO DE SEGURIDAD',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.centerRight,
                  child: Text(
                    cvvVisible,
                    style: const TextStyle(
                      color: cafeOscuro,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'COFFEE CAT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Icon(
                      Icons.security_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatearNumeroTarjeta(String numero) {
    final String digitos = numero.replaceAll(RegExp(r'\D'), '');

    String resultado = '';

    for (int i = 0; i < 16; i++) {
      resultado += i < digitos.length ? digitos[i] : '•';

      if ((i + 1) % 4 == 0 && i != 15) {
        resultado += '  ';
      }
    }

    return resultado;
  }

  InputDecoration _inputDecoration(String texto, IconData icono) {
    return InputDecoration(
      labelText: texto,
      prefixIcon: Icon(icono),
      filled: true,
      fillColor: crema,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cafeOscuro, width: 1.5),
      ),
    );
  }

  Future<void> _procesarVenta() async {
    if (_carrito.isEmpty) {
      _mostrarMensaje('Agrega productos al carrito', Colors.orange);
      return;
    }

    if (_metodoPago == null) {
      _mostrarMensaje('Selecciona un método de pago', Colors.orange);
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
      final pagoConfirmado = await _solicitarDatosTarjeta();

      if (!pagoConfirmado) return;
    }

    setState(() {
      _procesandoVenta = true;
    });

    try {
      for (var item in _carrito) {
        final productoRef = _productosRef.doc(item['id']);

        final productoDoc = await productoRef.get();

        final productoData = productoDoc.data() as Map<String, dynamic>;

        final stockActual =
            int.tryParse((productoData['cantidad'] ?? 0).toString()) ?? 0;

        await productoRef.update({
          'cantidad': stockActual - (item['cantidad'] as int),
        });
      }

      await _ventasRef.add({
        'productos': _carrito
            .map(
              (item) => {
                'id': item['id'],
                'nombre': item['nombre'],
                'precio': item['precio'],
                'cantidad': item['cantidad'],
              },
            )
            .toList(),
        'total': _totalVenta,
        'metodo_pago': _metodoPago,
        'fecha': FieldValue.serverTimestamp(),
        'usuario': FirebaseAuth.instance.currentUser?.email ?? 'desconocido',
      });

      if (!mounted) return;

      setState(() {
        _procesandoVenta = false;
      });

      await _mostrarVentaExitosa(efectivoRecibido);
    } catch (e) {
      if (mounted) {
        setState(() {
          _procesandoVenta = false;
        });

        _mostrarMensaje('Error al procesar la venta: $e', Colors.red);
      }
    }
  }

  Future<void> _mostrarVentaExitosa(double? efectivoRecibido) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: Container(
            width: 65,
            height: 65,
            decoration: const BoxDecoration(
              color: Color(0xffE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.green,
              size: 40,
            ),
          ),
          title: const Text(
            'Venta exitosa',
            textAlign: TextAlign.center,
            style: TextStyle(color: cafeOscuro, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'La venta se registró correctamente',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              _filaResumen(
                'Método',
                _metodoPago == 'efectivo' ? 'Efectivo' : 'Tarjeta',
              ),
              const SizedBox(height: 10),
              _filaResumen('Total', '\$${_totalVenta.toStringAsFixed(2)}'),
              if (_metodoPago == 'efectivo' && efectivoRecibido != null) ...[
                const SizedBox(height: 10),
                _filaResumen(
                  'Cambio',
                  '\$${(efectivoRecibido - _totalVenta).toStringAsFixed(2)}',
                  color: Colors.green,
                ),
              ],
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 160,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cafeOscuro,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Aceptar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _carrito.clear();
      _metodoPago = null;
      _efectivoController.clear();
    });
  }

  Widget _filaResumen(String nombre, String valor, {Color color = cafeOscuro}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(nombre, style: const TextStyle(color: Colors.black54)),
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: crema,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEncabezado(),
          const SizedBox(height: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return _buildVistaMovil();
                }

                return Row(
                  children: [
                    Expanded(flex: 2, child: _buildCatalogo()),
                    const SizedBox(width: 18),
                    Expanded(child: _buildCarrito()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncabezado() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: cafeOscuro,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.point_of_sale_rounded, color: Colors.white),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Punto de venta',
                style: TextStyle(
                  color: cafeOscuro,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Coffee Cat · Sistema de ventas',
                style: TextStyle(color: cafeMedio, fontSize: 12),
              ),
            ],
          ),
        ),
        if (_totalArticulos > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borde),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  color: cafeOscuro,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_totalArticulos',
                  style: const TextStyle(
                    color: cafeOscuro,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVistaMovil() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borde),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: cafeMedio,
              indicator: BoxDecoration(
                color: cafeOscuro,
                borderRadius: BorderRadius.circular(10),
              ),
              tabs: [
                const Tab(
                  icon: Icon(Icons.coffee_rounded, size: 18),
                  text: 'Productos',
                ),
                Tab(
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                  text: 'Orden ($_totalArticulos)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: TabBarView(children: [_buildCatalogo(), _buildCarrito()]),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCatalogo() {
    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.coffee_rounded, color: cafeOscuro),
              SizedBox(width: 8),
              Text(
                'Selecciona un producto',
                style: TextStyle(
                  color: cafeOscuro,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Presiona un producto y elige la cantidad',
            style: TextStyle(color: Colors.black45, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _productosStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildEstadoVacio(
                    Icons.cloud_off_rounded,
                    'No fue posible cargar los productos',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: cafeOscuro),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEstadoVacio(
                    Icons.inventory_2_outlined,
                    'No hay productos disponibles',
                  );
                }

                final productos = snapshot.data!.docs;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int columnas;

                    if (constraints.maxWidth >= 850) {
                      columnas = 4;
                    } else if (constraints.maxWidth >= 550) {
                      columnas = 3;
                    } else if (constraints.maxWidth >= 300) {
                      columnas = 2;
                    } else {
                      columnas = 1;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 5),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnas,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: columnas == 1 ? 1.7 : 0.95,
                      ),
                      itemCount: productos.length,
                      itemBuilder: (context, index) {
                        return _buildProducto(productos[index]);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducto(DocumentSnapshot producto) {
    final data = producto.data() as Map<String, dynamic>;

    final String nombre = (data['nombre'] ?? 'Sin nombre').toString();

    final double precio =
        double.tryParse((data['precio'] ?? 0).toString()) ?? 0;

    final int stock = int.tryParse((data['cantidad'] ?? 0).toString()) ?? 0;

    final bool disponible = stock > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disponible ? () => _seleccionarCantidad(producto) : null,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borde),
          ),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: disponible
                          ? const Color(0xffEFE5DC)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.local_cafe_rounded,
                      color: disponible ? cafeMedio : Colors.grey,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: cafeOscuro,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '\$${precio.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: cafeOscuro,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: disponible
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        disponible ? 'Disponible' : 'Agotado',
                        style: TextStyle(
                          color: disponible
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarrito() {
    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: cafeOscuro),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Orden actual',
                  style: TextStyle(
                    color: cafeOscuro,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$_totalArticulos artículos',
                style: const TextStyle(
                  color: cafeMedio,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: borde),
          Expanded(
            child: _carrito.isEmpty
                ? _buildCarritoVacio()
                : ListView.separated(
                    itemCount: _carrito.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 8);
                    },
                    itemBuilder: (context, index) {
                      return _buildItemCarrito(_carrito[index]);
                    },
                  ),
          ),
          const Divider(color: borde),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: cafeOscuro,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${_totalVenta.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Método de pago',
            style: TextStyle(
              color: cafeOscuro,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetodoPago(
                  texto: 'Efectivo',
                  icono: Icons.payments_outlined,
                  valor: 'efectivo',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetodoPago(
                  texto: 'Tarjeta',
                  icono: Icons.credit_card_rounded,
                  valor: 'tarjeta',
                ),
              ),
            ],
          ),
          if (_metodoPago == 'efectivo') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _efectivoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                'Efectivo recibido',
                Icons.attach_money_rounded,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: cafeOscuro,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: _carrito.isEmpty || _procesandoVenta
                  ? null
                  : _procesarVenta,
              icon: _procesandoVenta
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                _procesandoVenta ? 'PROCESANDO...' : 'PROCESAR VENTA',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarritoVacio() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: crema,
            child: Icon(
              Icons.shopping_cart_outlined,
              color: cafeClaro,
              size: 30,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Tu orden está vacía',
            style: TextStyle(color: cafeOscuro, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Selecciona un producto',
            style: TextStyle(color: Colors.black45, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCarrito(Map<String, dynamic> item) {
    final int cantidad = item['cantidad'] as int;

    final double precio = (item['precio'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: crema,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xffE7D7C8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_cafe_rounded,
              color: cafeMedio,
              size: 20,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nombre'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: cafeOscuro,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${(precio * cantidad).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: cafeMedio,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _botonCarrito(Icons.remove_rounded, () {
            _actualizarCantidad(item['id'].toString(), cantidad - 1);
          }),
          SizedBox(
            width: 28,
            child: Text(
              '$cantidad',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: cafeOscuro,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _botonCarrito(Icons.add_rounded, () {
            _actualizarCantidad(item['id'].toString(), cantidad + 1);
          }),
          IconButton(
            tooltip: 'Eliminar',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              _eliminarDelCarrito(item['id'].toString());
            },
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonCarrito(IconData icono, VoidCallback onPressed) {
    return SizedBox(
      width: 29,
      height: 29,
      child: IconButton(
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: cafeOscuro,
        ),
        onPressed: onPressed,
        icon: Icon(icono, size: 17),
      ),
    );
  }

  Widget _buildMetodoPago({
    required String texto,
    required IconData icono,
    required String valor,
  }) {
    final seleccionado = _metodoPago == valor;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _metodoPago = valor;

          if (valor != 'efectivo') {
            _efectivoController.clear();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xffEFE5DC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? cafeOscuro : borde,
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: cafeOscuro, size: 17),
            const SizedBox(width: 6),
            Text(
              texto,
              style: const TextStyle(
                color: cafeOscuro,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoVacio(IconData icono, String texto) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: cafeClaro, size: 42),
          const SizedBox(height: 10),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: cafeMedio,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _efectivoController.dispose();
    super.dispose();
  }
}

class FechaVencimientoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String numeros = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (numeros.length > 4) {
      numeros = numeros.substring(0, 4);
    }

    String textoFormateado = numeros;

    if (numeros.length > 2) {
      textoFormateado = '${numeros.substring(0, 2)}/${numeros.substring(2)}';
    }

    return TextEditingValue(
      text: textoFormateado,
      selection: TextSelection.collapsed(offset: textoFormateado.length),
    );
  }
}
