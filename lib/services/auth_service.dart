import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String uid;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;

  UsuarioModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activo,
  });

  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UsuarioModel(
      uid: doc.id,
      nombre: data['nombre'] ?? 'Sin nombre',
      email: data['email'] ?? '',
      rol: data['rol'] ?? 'vendedor',
      activo: data['activo'] ?? true,
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UsuarioModel? _usuarioActual;

  UsuarioModel? get usuarioActual => _usuarioActual;
  String? get rolActual => _usuarioActual?.rol;
  User? get firebaseUser => _auth.currentUser;

  /// Stream para escuchar el estado de autenticación desde cualquier widget o main.dart
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Carga los datos de Firestore si hay una sesión activa de Firebase al recargar (F5)
  Future<UsuarioModel?> cargarUsuarioActual() async {
    final user = _auth.currentUser;
    if (user == null) {
      _usuarioActual = null;
      return null;
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('usuarios').doc(user.uid).get();

      if (userDoc.exists) {
        _usuarioActual = UsuarioModel.fromFirestore(userDoc);
        if (!_usuarioActual!.activo) {
          await logout();
          return null;
        }
        return _usuarioActual;
      } else {
        await logout();
        return null;
      }
    } catch (e) {
      _usuarioActual = null;
      return null;
    }
  }

  Future<UsuarioModel?> login(String email, String password) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.signOut();
        _usuarioActual = null;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      DocumentSnapshot userDoc = await _firestore.collection('usuarios').doc(userCredential.user!.uid).get();

      if (userDoc.exists) {
        _usuarioActual = UsuarioModel.fromFirestore(userDoc);
        if (!_usuarioActual!.activo) {
          await logout();
          throw Exception('Tu cuenta ha sido desactivada.');
        }
        return _usuarioActual;
      } else {
        await _auth.signOut();
        throw Exception('Usuario no encontrado en el sistema.');
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al iniciar sesión';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        mensaje = 'No existe una cuenta o las credenciales son incorrectas';
      } else if (e.code == 'wrong-password') {
        mensaje = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo no es válido';
      } else if (e.code == 'too-many-requests') {
        mensaje = 'Demasiados intentos. Intenta más tarde';
      }
      throw Exception(mensaje);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> logout() async {
    _usuarioActual = null;
    await _auth.signOut();
  }

  bool tieneRol(String rol) => _usuarioActual?.rol == rol;
  bool get esAdmin => tieneRol('admin');
  bool get esSupervisor => tieneRol('supervisor') || tieneRol('admin');
  bool get esVendedor => tieneRol('vendedor');
  
  String get mensajeBienvenida {
    if (_usuarioActual == null) return 'Ingreso exitoso';
    switch (_usuarioActual!.rol) {
      case 'admin':
        return 'Bienvenido, Administrador';
      case 'supervisor':
        return 'Bienvenido, Supervisor';
      case 'vendedor':
        return 'Bienvenido, Vendedor';
      default:
        return 'Ingreso exitoso';
    }
  }
}