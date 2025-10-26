import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_sizes.dart';
import 'user_card.dart';

class GradeSection extends StatelessWidget {
  final int grade;
  final List<QueryDocumentSnapshot> students;

  const GradeSection({
    super.key,
    required this.grade,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: imprimir información de estudiantes
    print('🔍 GradeSection para grado $grade con ${students.length} estudiantes');
    for (var student in students) {
      final data = student.data() as Map<String, dynamic>?;
      print('  - ${data?['nombre']}: grade=${data?['grade']}, studentInfo.grado=${data?['studentInfo']?['grado']}');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade100,
            radius: 20,
            child: Text(
              grade == 0 ? '?' : '$grade°',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(
            grade == 0 ? 'Sin grado asignado' : 'Grado $grade',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${students.length}',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          children: students.map((userDoc) {
            try {
              if (!userDoc.exists) return const SizedBox.shrink();
              final user = userDoc.data() as Map<String, dynamic>?;
              if (user == null || !user.containsKey('email')) {
                return const SizedBox.shrink();
              }
              return UserCard(
                user: user,
                userDoc: userDoc,
                isInGradeSection: true,
              );
            } catch (e) {
              print('❌ Error renderizando UserCard: $e');
              return const SizedBox.shrink();
            }
          }).toList(),
        ),
      ),
    );
  }
}
