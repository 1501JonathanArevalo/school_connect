import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../services/auth_navigation_service.dart';
import '../user_form_dialog.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final QueryDocumentSnapshot userDoc;
  final bool isInGradeSection;

  const UserCard({
    super.key,
    required this.user,
    required this.userDoc,
    this.isInGradeSection = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!user.containsKey('uid') || !user.containsKey('email')) {
      return const SizedBox.shrink();
    }

    final isTestUser = user['isTestUser'] == true;
    final nombre = user['nombre'] ?? user['email'];
    final role = user['role'] ?? 'student';

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isInGradeSection ? 8 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isTestUser ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: isTestUser ? Colors.orange.shade200 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: _buildAvatar(role, isTestUser),
        title: _buildTitle(nombre, isTestUser),
        subtitle: _buildSubtitle(role),
        trailing: _buildActions(context),
      ),
    );
  }

  Widget _buildAvatar(String role, bool isTestUser) {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: role == 'student'
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.blue.shade400, Colors.blue.shade600],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            role == 'student' ? Icons.school : Icons.person,
            color: Colors.white,
            size: 24,
          ),
        ),
        if (isTestUser)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.science,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitle(String nombre, bool isTestUser) {
    return Row(
      children: [
        Expanded(
          child: Text(
            nombre,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        if (isTestUser)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'TEST',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(String role) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email_outlined, size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  user['email'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (role == 'student' && user.containsKey('grade') && user['grade'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.class_outlined, size: 13, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'Grado ${user['grade']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: IconButton(
            icon: Icon(Icons.edit, color: Colors.blue.shade700, size: 18),
            tooltip: 'Editar',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: () => _editUser(context),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: IconButton(
            icon: Icon(Icons.delete, color: Colors.red.shade700, size: 18),
            tooltip: 'Eliminar',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: () => _deleteUser(context),
          ),
        ),
      ],
    );
  }

  Future<void> _editUser(BuildContext context) async {
    try {
      final result = await showDialog(
        context: context,
        builder: (context) => UserFormDialog.edit(user: user),
      );

      if (result == true && context.mounted) {
        AuthNavigationService.showSuccessSnackBar(
          context,
          'Usuario actualizado',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AuthNavigationService.showErrorSnackBar(
          context,
          'Error: $e',
        );
      }
    }
  }

  Future<void> _deleteUser(BuildContext context) async {
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
            Text('Eliminar Usuario'),
          ],
        ),
        content: const Text('¿Estás seguro de eliminar este usuario?'),
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user['uid'])
            .delete();

        if (context.mounted) {
          AuthNavigationService.showSuccessSnackBar(
            context,
            'Usuario eliminado',
          );
        }
      } catch (e) {
        if (context.mounted) {
          AuthNavigationService.showErrorSnackBar(
            context,
            'Error: $e',
          );
        }
      }
    }
  }
}
