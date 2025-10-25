// student_home.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:school_connect/auth_service.dart';
import 'package:school_connect/login_screen.dart';
import 'package:school_connect/screens/student/screens/assignments_tab.dart';
import 'package:school_connect/screens/student/screens/dashboard_tab.dart';
import 'package:school_connect/screens/student/screens/schedule_tab.dart';
import 'dart:html' as html;

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final AuthService _authService = AuthService();

    return DefaultTabController(
      length: 3, // Cambiar de 2 a 3
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Estudiante'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _cerrarSesion(context, _authService),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Inicio'),
              Tab(icon: Icon(Icons.assignment), text: 'Tareas'), 
              Tab(icon: Icon(Icons.schedule), text: 'Horario'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DashboardTab(userId: userId), // Nueva pestaña
            AssignmentsTab(userId: userId),
            ScheduleTab(userId: userId),
          ],
        ),
      ),
    );
  }

  void _cerrarSesion(BuildContext context, AuthService authService) async {
    try {
      await authService.signOut();
      if (kIsWeb) {
        html.window.location.reload();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }
}