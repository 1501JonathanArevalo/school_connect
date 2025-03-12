import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_connect/auth_service.dart';
import 'package:school_connect/login_screen.dart';
import 'subjects_screen.dart';
import 'dart:html' as html; // Para usar window.location.reload()


class GradesScreen extends StatelessWidget {
  final String teacherId;

  const GradesScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context) {
        final AuthService _authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursos que dictas'),
                actions: [
          IconButton(
            icon: Icon(Icons.logout), // Ícono de cerrar sesión
            onPressed: () => _cerrarSesion(context, _authService),
          ),
        ],
        
        ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('materias')
            .where('profesorId', isEqualTo: teacherId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          
          final grades = _groupByGrade(snapshot.data!.docs);
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: grades.length,
            itemBuilder: (context, index) => _GradeCard(
              grade: grades.keys.elementAt(index),
              subjectsCount: grades.values.elementAt(index),
            ),
          );
        },
      ),
    );
  }

  Map<String, int> _groupByGrade(List<QueryDocumentSnapshot> materias) {
    final Map<String, int> grades = {};
    for (var materia in materias) {
      final grade = materia['grado'];
      grades[grade] = (grades[grade] ?? 0) + 1;
    }
    return grades;
  }
}

void _cerrarSesion(BuildContext context, AuthService authService) async {
  try {
    await authService.signOut(); // Cerrar sesión

    // Forzar recarga en una aplicación web
    if (kIsWeb) {
      html.window.location.reload();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false, // Eliminar todas las rutas anteriores
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al cerrar sesión: $e')),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final String grade;
  final int subjectsCount;

  const _GradeCard({required this.grade, required this.subjectsCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectsScreen(grade: grade),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Grado $grade',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '$subjectsCount Materias',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}