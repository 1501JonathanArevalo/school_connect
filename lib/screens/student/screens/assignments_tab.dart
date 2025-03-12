import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_connect/screens/student/widgets/subject_expansion.dart';

class AssignmentsTab extends StatelessWidget {
  final String userId;
  
  const AssignmentsTab({super.key, required this.userId});

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
        return ListView.builder(
          itemCount: materias.length,
          itemBuilder: (context, index) => SubjectExpansion(
            materia: materias[index].data() as Map<String, dynamic>,
            materiaId: materias[index].id,
          ),
        );
      },
    );
  }
}