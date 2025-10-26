import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/widgets/gradient_header.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/action_button_group.dart';
import '../../core/constants/app_sizes.dart';
import 'user_form_dialog.dart';
import 'widgets/user_card.dart';
import 'widgets/grade_section.dart';
import 'widgets/test_users_dialog.dart';

class UsersTab extends StatelessWidget {
  const UsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildActionButtons(context),
        Expanded(child: _buildUsersList()),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GradientHeader(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(height: 120);
          }

          final users = snapshot.data!.docs;
          final totalUsers = users.where((u) => 
            (u.data() as Map)['role'] != 'admin'
          ).length;
          final students = users.where((u) => 
            (u.data() as Map)['role'] == 'student'
          ).length;
          final teachers = users.where((u) => 
            (u.data() as Map)['role'] == 'teacher'
          ).length;
          final testUsers = users.where((u) => 
            (u.data() as Map)['isTestUser'] == true
          ).length;

          return Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Usuarios',
                  value: totalUsers.toString(),
                  icon: Icons.people,
                  iconColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Estudiantes',
                  value: students.toString(),
                  icon: Icons.school,
                  iconColor: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Profesores',
                  value: teachers.toString(),
                  icon: Icons.person,
                  iconColor: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Prueba',
                  value: testUsers.toString(),
                  icon: Icons.science,
                  iconColor: Colors.orangeAccent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return ActionButtonGroup(
      buttons: [
        ActionButtonData(
          icon: Icons.school,
          label: 'Nuevo Estudiante',
          color: Colors.green,
          onPressed: () => showDialog(
            context: context,
            builder: (context) => const UserFormDialog(isStudent: true),
          ),
        ),
        ActionButtonData(
          icon: Icons.person,
          label: 'Nuevo Profesor',
          color: Colors.blue,
          onPressed: () => showDialog(
            context: context,
            builder: (context) => const UserFormDialog(isStudent: false),
          ),
        ),
        ActionButtonData(
          icon: Icons.science,
          label: 'Usuarios Test',
          color: Colors.orange,
          onPressed: () => TestUsersDialog.show(context),
        ),
      ],
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isNotEqualTo: 'admin')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando usuarios...'),
              ],
            ),
          );
        }

        final allUsers = snapshot.data?.docs ?? [];
        final validUsers = allUsers.where((doc) {
          try {
            return doc.exists && doc.data() != null;
          } catch (e) {
            return false;
          }
        }).toList();

        final teachers = validUsers.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data != null && data['role'] == 'teacher';
        }).toList();

        final students = validUsers.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data != null && data['role'] == 'student';
        }).toList();

        if (validUsers.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: 'No hay usuarios registrados',
            subtitle: 'Crea tu primer estudiante o profesor',
          );
        }

        // Agrupar estudiantes por grado
        final Map<int, List<QueryDocumentSnapshot>> studentsByGrade = {};
        for (var student in students) {
          try {
            final data = student.data() as Map<String, dynamic>?;
            if (data == null) continue;
            
            int grade = 0;
            if (data.containsKey('grade') && data['grade'] != null) {
              if (data['grade'] is int) {
                grade = data['grade'] as int;
              } else if (data['grade'] is String) {
                grade = int.tryParse(data['grade']) ?? 0;
              }
            }
            
            if (!studentsByGrade.containsKey(grade)) {
              studentsByGrade[grade] = [];
            }
            studentsByGrade[grade]!.add(student);
          } catch (e) {
            print('Error agrupando estudiante: $e');
          }
        }

        final sortedGrades = studentsByGrade.keys.toList()..sort();

        return Container(
          color: Colors.grey.shade100,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            children: [
              _buildSectionCard(
                title: 'Profesores',
                count: teachers.length,
                icon: Icons.person,
                color: Colors.blue,
                children: teachers.isEmpty
                    ? [_buildEmptyState('No hay profesores registrados', Icons.person_outline)]
                    : teachers.map((userDoc) {
                        final user = userDoc.data() as Map<String, dynamic>;
                        return UserCard(user: user, userDoc: userDoc);
                      }).toList(),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Estudiantes',
                count: students.length,
                icon: Icons.school,
                color: Colors.green,
                children: students.isEmpty
                    ? [_buildEmptyState('No hay estudiantes registrados', Icons.school_outlined)]
                    : sortedGrades.map((grade) {
                        final gradeStudents = studentsByGrade[grade] ?? [];
                        return GradeSection(grade: grade, students: gradeStudents);
                      }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
