import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/notification_service.dart';

class UserMenuWidget extends StatelessWidget {
  final String userId;
  final VoidCallback onLogout;

  const UserMenuWidget({
    super.key,
    required this.userId,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final nombre = snapshot.hasData
            ? snapshot.data!['nombre'] ?? 'Usuario'
            : 'Usuario';

        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          child: _buildUserAvatar(nombre),
          itemBuilder: (context) => _buildMenuItems(nombre),
          onSelected: (value) => _handleMenuSelection(value, context),
        );
      },
    );
  }

  Widget _buildUserAvatar(String nombre) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 18,
            child: Text(
              nombre[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFB199DB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            nombre.split(' ')[0],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 20, color: Colors.white),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(String nombre) {
    return [
      PopupMenuItem(
        enabled: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              FirebaseAuth.instance.currentUser!.email ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const Divider(),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'recordatorios',
        child: Row(
          children: [
            Icon(Icons.notifications),
            SizedBox(width: 12),
            Text('Mis recordatorios'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'notificaciones',
        child: Row(
          children: [
            Icon(Icons.settings),
            SizedBox(width: 12),
            Text('Configurar notificaciones'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'logout',
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ];
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'recordatorios':
        NotificationService.showActiveReminders(context, userId);
        break;
      case 'notificaciones':
        NotificationService.manageNotificationPermissions(context);
        break;
      case 'logout':
        onLogout();
        break;
    }
  }
}
