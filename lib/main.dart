import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_router.dart';

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
    return MaterialApp.router(
      title: 'Coffee Cat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff362419),
          primary: const Color(0xff362419),
          surface: const Color(0xffF5F0EB),
        ),
        scaffoldBackgroundColor: const Color(0xffF5F0EB),
        fontFamily: 'Roboto',
      ),
      routerConfig: appRouter,
    );
  }
}