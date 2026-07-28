import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<void> recrearUsuarios() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  final usuarios = [
    {'email': 'supervisor@coffeecat.com', 'password': 'sup123', 'nombre': 'Supervisor', 'rol': 'supervisor'},
    {'email': 'vendedor@coffeecat.com', 'password': 'ven123', 'nombre': 'Vendedor', 'rol': 'vendedor'},
  ];

  for (var usuario in usuarios) {
    try {
      // Intentar crear usuario
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: usuario['email'] as String,
        password: usuario['password'] as String,
      );

      String uid = userCredential.user!.uid;
      debugPrint('✅ Usuario creado: ${usuario['email']}');
      debugPrint('   UID: $uid');

      // Crear documento en Firestore
      await firestore.collection('usuarios').doc(uid).set({
        'nombre': usuario['nombre'],
        'email': usuario['email'],
        'rol': usuario['rol'],
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      debugPrint('   Documento creado en Firestore');
    } catch (e) {
      debugPrint('❌ Error con ${usuario['email']}: $e');
    }
  }
}