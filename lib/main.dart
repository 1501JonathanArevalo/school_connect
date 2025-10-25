import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // Agregar esto
import 'firebase_options.dart';
import 'login_screen.dart';
import 'admin_home.dart';
import 'teacher_home.dart';
import 'student_home.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es_ES', null); // Agregar esto
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

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout al cargar datos del usuario');
            },
          ),
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (roleSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error al cargar perfil'),
                  Text('${roleSnapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          );
        }

        // Si el documento no existe, crearlo automáticamente
        if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
          return FutureBuilder(
            future: _createUserDocument(user),
            builder: (context, createSnapshot) {
              if (createSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Configurando perfil...'),
                      ],
                    ),
                  ),
                );
              }
              
              if (createSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${createSnapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Recargar después de crear el documento
              return const LoadingScreen();
            },
          );
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

// Función auxiliar para crear el documento del usuario
Future<void> _createUserDocument(User user) async {
  print('🔧 Creando documento para usuario: ${user.uid}');
  
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .set({
        'uid': user.uid,
        'email': user.email,
        'nombre': user.email?.split('@')[0] ?? 'Usuario',
        'role': 'admin', // Por defecto admin para el primer usuario
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
      });
  
  print('✅ Documento creado exitosamente');
}