// ignore_for_file: unused_import, dead_code

import 'package:flutter/material.dart';
import 'package:implementacion_fb/screens/login.dart';
import 'package:implementacion_fb/screens/register.dart';
import 'package:implementacion_fb/screens/feed.dart';
import 'package:implementacion_fb/screens/add-publi.dart';
import 'package:implementacion_fb/screens/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Configurar App Check (opcional)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Solo para desarrollo
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FakeBook',
      initialRoute: '/login',
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterScreen(),
        '/feed': (context) => const FeedScreen(),
        '/addPubli': (context) => const AddPubliScreen(),
        '/perfil': (context) => const ProfileScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder:(context, snapshot) {
        if (snapshot.hasData) {
          return const FeedScreen();
        } else {
          return const LoginPage();
        }

        if (snapshot.hasError) {
          return const Text('Error');
          }
      
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
          }
      },
    );
    throw UnimplementedError();
  }
}