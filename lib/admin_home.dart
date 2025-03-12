import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_connect/auth_service.dart';
import 'package:school_connect/login_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:school_connect/screens/admin/subject_form.dart';
import 'package:school_connect/screens/admin/user_form_dialog.dart';
import 'dart:html' as html;

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Fecha desconocida';
    return DateFormat('dd/MM/yyyy HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000),
    );
  }

  void _cerrarSesion(BuildContext context) async {
    try {
      await _authService.signOut();
      if (kIsWeb) {
        html.window.location.reload();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  void _deleteUser(String uid) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: const Text('¿Estás seguro de eliminar este usuario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore.collection('users').doc(uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Usuario eliminado')),
      );
    }
  }

Widget _buildUserTab() {
  return StreamBuilder<QuerySnapshot>(
    stream: _authService.getUsers(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final users = snapshot.data!.docs;
      if (users.isEmpty) {
        return const Center(child: Text('No hay usuarios registrados'));
      }

      return ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final userDoc = users[index];
          if (!userDoc.exists) {
            return const SizedBox.shrink(); // O un widget placeholder
          }

          // Convertir los datos del documento a Map<String, dynamic>
          final user = userDoc.data() as Map<String, dynamic>;

          return ListTile(
            title: Text(user['email'] ?? 'Sin email'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rol: ${user['role'] ?? 'Sin rol'}'),
                if (user['role'] == 'student')
                  Text('Curso: Grado ${user['grade']}'),
                Text('Creado: ${_formatDate(user['createdAt'])}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteUser(user['uid']),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => UserFormDialog.edit(user: user),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Administrador'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_add), text: 'Usuarios'),
              Tab(icon: Icon(Icons.school), text: 'Materias'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _cerrarSesion(context),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.school),
                        label: const Text('Crear Estudiante'),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => UserFormDialog(isStudent: true),
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person),
                        label: const Text('Crear Profesor'),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => UserFormDialog(isStudent: false),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildUserTab()),
              ],
            ),
            SubjectForm(authService: _authService),
          ],
        ),
      ),
    );
  }
}