import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'admin_home.dart';
import 'teacher_home.dart';
import 'student_home.dart';
//hola prueba
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classroom App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
home: StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const LoadingScreen();
    }

    final user = snapshot.data;
    if (user == null) return const LoginScreen();

    // Cambiar FutureBuilder por StreamBuilder
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(), // Usar snapshots() para escuchar cambios
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        // Verificar si el documento existe
        if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
          return const LoadingScreen();
        }

        final role = roleSnapshot.data!.get('role') ?? 'student';

        switch (role) {
          case 'admin':
            return const AdminHome();
          case 'teacher':
            return const TeacherHome();
          default:
            return const StudentHome();
        }
      },
    );
  },
),
    );
  }
}
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}