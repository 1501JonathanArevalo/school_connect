import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../../core/constants/app_sizes.dart';
import '../../../services/auth_navigation_service.dart';

class TestUsersDialog extends StatelessWidget {
  const TestUsersDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const TestUsersDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSizes.paddingLarge),
            _buildDescription(),
            const SizedBox(height: AppSizes.paddingLarge),
            _buildStudentsSection(context),
            const SizedBox(height: AppSizes.paddingMedium),
            _buildTeachersSection(context),
            const SizedBox(height: AppSizes.paddingLarge),
            const Divider(),
            const SizedBox(height: AppSizes.paddingMedium),
            _buildDeleteAllButton(context),
            const SizedBox(height: AppSizes.paddingSmall),
            _buildCloseButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: Icon(
            Icons.science,
            color: Colors.purple.shade700,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Crear Usuarios de Prueba',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      'Selecciona cuántos usuarios crear:',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildStudentsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.school, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Estudiantes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTestUserButton(
            context,
            '5 Estudiantes',
            Icons.school,
            Colors.green,
            () => _createRandomUsers(context, true, 5),
          ),
          const SizedBox(height: 8),
          _buildTestUserButton(
            context,
            '10 Estudiantes',
            Icons.school,
            Colors.green,
            () => _createRandomUsers(context, true, 10),
          ),
          const SizedBox(height: 8),
          _buildTestUserButton(
            context,
            '100 Estudiantes',
            Icons.school,
            Colors.green,
            () => _createRandomUsers(context, true, 100),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Profesores',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTestUserButton(
            context,
            '3 Profesores',
            Icons.person,
            Colors.blue,
            () => _createRandomUsers(context, false, 3),
          ),
          const SizedBox(height: 8),
          _buildTestUserButton(
            context,
            '5 Profesores',
            Icons.person,
            Colors.blue,
            () => _createRandomUsers(context, false, 5),
          ),
          const SizedBox(height: 8),
          _buildTestUserButton(
            context,
            '25 Profesores',
            Icons.person,
            Colors.blue,
            () => _createRandomUsers(context, false, 25),
          ),
        ],
      ),
    );
  }

  Widget _buildTestUserButton(
    BuildContext context,
    String label,
    IconData icon,
    MaterialColor color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
          onPressed();
        },
      ),
    );
  }

  Widget _buildDeleteAllButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.delete_sweep, color: Colors.red),
        label: const Text(
          'Eliminar todos los usuarios de prueba',
          style: TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
          _deleteAllTestUsers(context);
        },
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Cerrar'),
      ),
    );
  }

  Future<void> _createRandomUsers(
    BuildContext context,
    bool isStudent,
    int count,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final random = Random();
      final batch = firestore.batch();

      final nombres = isStudent
          ? ['Ana', 'Carlos', 'María', 'Juan', 'Sofía', 'Diego', 'Laura', 'Pedro', 'Lucía', 'Miguel']
          : ['Prof. García', 'Prof. Martínez', 'Prof. López', 'Prof. Rodríguez', 'Prof. González'];

      final apellidos = [
        'Pérez', 'González', 'Rodríguez', 'Fernández',
        'López', 'Martínez', 'Sánchez', 'Ramírez'
      ];

      for (int i = 0; i < count; i++) {
        final nombre = '${nombres[random.nextInt(nombres.length)]} '
                      '${apellidos[random.nextInt(apellidos.length)]}';
        final randomId = random.nextInt(99999);
        final email = isStudent
            ? 'estudiante_test_$randomId@test.com'
            : 'profesor_test_$randomId@test.com';

        final docRef = firestore.collection('users').doc();

        final userData = {
          'uid': docRef.id,
          'email': email,
          'nombre': nombre,
          'role': isStudent ? 'student' : 'teacher',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': 'admin_test',
          'isTestUser': true,
        };

        if (isStudent) {
          userData['grade'] = random.nextInt(12) + 1;
        }

        batch.set(docRef, userData);
      }

      await batch.commit();

      if (context.mounted) {
        AuthNavigationService.showSuccessSnackBar(
          context,
          '✅ $count ${isStudent ? "estudiantes" : "profesores"} de prueba creados',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AuthNavigationService.showErrorSnackBar(
          context,
          '❌ Error al crear usuarios: $e',
        );
      }
    }
  }

  Future<void> _deleteAllTestUsers(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 12),
            Text('⚠️ Eliminar Usuarios de Prueba'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de eliminar TODOS los usuarios de prueba?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar Todos'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final testUsers = await FirebaseFirestore.instance
            .collection('users')
            .where('isTestUser', isEqualTo: true)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in testUsers.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        if (context.mounted) {
          AuthNavigationService.showSuccessSnackBar(
            context,
            '✅ ${testUsers.docs.length} usuarios de prueba eliminados',
          );
        }
      } catch (e) {
        if (context.mounted) {
          AuthNavigationService.showErrorSnackBar(
            context,
            '❌ Error: $e',
          );
        }
      }
    }
  }
}
