import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_details_screen.dart';

class StudentsList extends StatelessWidget {
  final String materiaId;

  const StudentsList({super.key, required this.materiaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Estudiantes'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('materias')
            .doc(materiaId)
            .get(),
        builder: (context, materiaSnapshot) {
          if (materiaSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!materiaSnapshot.hasData || !materiaSnapshot.data!.exists) {
            return const Center(child: Text('Materia no encontrada'));
          }

          final materiaData = materiaSnapshot.data!.data() as Map<String, dynamic>;
          final grado = materiaData['grado'];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .where('studentInfo.grado', isEqualTo: grado)
                .snapshots(),
            builder: (context, estudiantesSnapshot) {
              if (estudiantesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!estudiantesSnapshot.hasData || estudiantesSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No hay estudiantes en este grado'));
              }

              final estudiantes = estudiantesSnapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: estudiantes.length,
                itemBuilder: (context, index) {
                  final estudiante = estudiantes[index];
                  final studentData = estudiante.data() as Map<String, dynamic>;
                  final studentInfo = studentData['studentInfo'] ?? {};

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text(studentData['nombre'] ?? 'Nombre no disponible'), // Cambio aquí
                      subtitle: Text('Grado: ${studentInfo['grado'] ?? 'No disponible'}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentDetailsScreen(
                              studentId: estudiante.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}