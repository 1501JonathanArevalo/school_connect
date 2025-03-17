import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_connect/screens/admin/schedules/schedule_viewer.dart';

class MateriaCard extends StatelessWidget {
  final QueryDocumentSnapshot materia;
  final Function(String) onDelete;

  const MateriaCard({
    super.key,
    required this.materia,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = materia.data() as Map<String, dynamic>;
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(data['profesorId'])
          .get(),
      builder: (context, profesorSnapshot) {
        final profesor = profesorSnapshot.data;
        final profesorNombre = profesor?['nombre'] ?? 'Profesor no asignado';
        final profesorEmail = profesor?['email'] ?? '';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: const Icon(Icons.book, size: 30),
            title: Text(data['nombre'], 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScheduleViewer(horarios: data['horarios'] ?? []),
                const SizedBox(height: 5),
                Text('Profesor: $profesorNombre ($profesorEmail)'),
                Text('Estudiantes inscritos: ${data['estudiantes'].length}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(materia.id),
            ),
          ),
        );
      },
    );
  }
}