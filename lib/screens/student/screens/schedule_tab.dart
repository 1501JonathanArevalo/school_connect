import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_connect/screens/student/widgets/schedule_grid_student.dart';

class ScheduleTab extends StatelessWidget {
  final String userId;
  
  const ScheduleTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('materias')
          .where('estudiantes', arrayContains: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final materias = snapshot.data!.docs;
        final horarios = _procesarHorarios(materias);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ScheduleGridStudent(horarios: horarios),
        );
      },
    );
  }

  List<Map<String, String>> _procesarHorarios(List<QueryDocumentSnapshot> materias) {
    List<Map<String, String>> horarios = [];
    for (var materia in materias) {
      final horariosMateria = materia['horarios'] as List<dynamic>;
      final nombreMateria = materia['nombre'] as String;
      for (var horario in horariosMateria) {
        horarios.add({'horario': horario.toString(), 'nombre': nombreMateria});
      }
    }
    return horarios;
  }
}