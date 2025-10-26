import 'package:flutter/material.dart';
import 'package:school_connect/screens/student/widgets/materials_section.dart';
import 'package:school_connect/screens/student/widgets/assignments_section.dart';


class SubjectExpansion extends StatelessWidget {
  final Map<String, dynamic> materia;
  final String materiaId;
  
  static const boldStyle = TextStyle(fontWeight: FontWeight.bold);
  
  const SubjectExpansion({
    super.key,
    required this.materia,
    required this.materiaId,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(materia['nombre']),
      subtitle: Text('Grado: ${materia['grado']}'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Horarios: ${materia['horarios']}'),
              const SizedBox(height: 16),
              const Text('Materiales de clase:', style: boldStyle),
              MaterialsSection(materiaId: materiaId),
              const SizedBox(height: 16),
              const Text('Asignaciones:', style: boldStyle),
              AssignmentsSection(materiaId: materiaId),
            ],
          ),
        ),
      ],
    );
  }
}