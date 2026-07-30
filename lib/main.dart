import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome.dart';
import 'dashboard.dart';

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
        primarySwatch: Colors.brown,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Mientras Firebase comprueba el estado de la sesión al recargar
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xff362419),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xffCFCFCD),
                ),
              ),
            );
          }

          // Si la sesión está activa en el navegador
          if (snapshot.hasData && snapshot.data != null) {
            return const DashboardPage();
          }

          // Si no hay sesión activa
          return const WelcomeScreen();
        },
      ),
    );
  }
}