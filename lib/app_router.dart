import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/auth_service.dart';
import 'widgets/main_layout.dart';
import 'login.dart';
import 'dashboard.dart';
import 'inventario.dart';
import 'ventas.dart';
import 'estadisticas.dart';
import 'configuracion.dart';
import 'empleados.dart';
import 'welcome.dart';

final AuthService _authService = AuthService();

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/welcome',
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (BuildContext context, GoRouterState state) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final ruta = state.matchedLocation;
    final estaEnAuth = (ruta == '/login' || ruta == '/welcome');

    if (firebaseUser == null) return estaEnAuth ? null : '/welcome';

    if (_authService.usuarioActual == null) await _authService.cargarUsuarioActual();

    final usuario = _authService.usuarioActual;
    if (usuario == null || !usuario.activo) return '/welcome';

    final esVendedorPuro = _authService.esVendedor && !_authService.esSupervisor;
    final esAdmin = _authService.esAdmin;

    if (estaEnAuth) return esVendedorPuro ? '/ventas' : '/';

    if (esVendedorPuro) {
      if (ruta == '/' || ruta == '/estadisticas' || ruta == '/empleados' || ruta == '/configuracion') return '/ventas';
    } else {
      if (!esAdmin && (ruta == '/empleados' || ruta == '/configuracion')) return '/';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
        GoRoute(path: '/inventario', builder: (context, state) => const InventarioScreen()),
        GoRoute(path: '/ventas', builder: (context, state) => const VentasPage()),
        GoRoute(path: '/estadisticas', builder: (context, state) => const EstadisticasPage()),
        GoRoute(path: '/configuracion', builder: (context, state) => const ConfiguracionPage()),
        GoRoute(path: '/empleados', builder: (context, state) => const EmpleadosPage()),
      ],
    ),
  ],
);