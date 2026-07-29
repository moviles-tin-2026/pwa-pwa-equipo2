import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'welcome.dart'; // ← CAMBIO 1: Importamos la nueva pantalla de bienvenida

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBGPH0Q0L2rUgTKGoAkHXkMIOhZ7VVdibs',
      appId: '1:746032600431:web:2e9fea79a1c68169bb049a',
      messagingSenderId: '746032600431',
      projectId: 'coffee-cat-8b348',
      authDomain: 'coffee-cat-8b348.firebaseapp.com',
      storageBucket: 'coffee-cat-8b348.firebasestorage.app',
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Cat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown, // Tema consistente con tu marca
      ),
      home: const WelcomePage(), // ← CAMBIO 2: La app ahora inicia aquí
    );
  }
}