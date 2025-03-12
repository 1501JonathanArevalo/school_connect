import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_connect/screens/teacher/students_list.dart';
import 'subject_details.dart';

class SubjectsScreen extends StatelessWidget {
  final String grade;

  const SubjectsScreen({super.key, required this.grade});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Grado $grade')),
      body: StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('materias')
      .where('profesorId', isEqualTo: FirebaseAuth.instance.currentUser!.uid) // <- Filtro por ID de profesor
      .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemCount: snapshot.data!.docs.length,
itemBuilder: (context, index) {
  final materia = snapshot.data!.docs[index];
  return _SubjectCard(
    name: materia['nombre'],
    horarios: (materia['horarios'] as List<dynamic>).cast<String>(), // Conversión segura
    estudiantesCount: materia['estudiantes'].length,
    materiaId: materia.id,
  );
},
          );
        },
      ),
    );
  }
}



class _SubjectCard extends StatelessWidget {
  final String name;
  final List<String> horarios; // Cambiar tipo a List<String>
  final int estudiantesCount;
  final String materiaId;

  const _SubjectCard({
    required this.name,
    required this.horarios,
    required this.estudiantesCount,
    required this.materiaId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: const Icon(Icons.book, size: 32),
        title: Text(name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(
        horarios.join(', '), // Convertir lista a string separado por comas
        style: const TextStyle(fontSize: 12),
      ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildInfoRow('Estudiantes inscritos:', '$estudiantesCount'),
          const SizedBox(height: 16),
          
          // Nuevo ListTile para ver la lista completa de estudiantes
          ListTile(
            title: const Text('Ver lista completa de estudiantes'),
            leading: const Icon(Icons.list),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentsList(materiaId: materiaId),
                ),
              );
            },
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.assignment,
                label: 'Tareas',
                onPressed: () => _navigateToDetails(context, 0),
              ),
              _ActionButton(
                icon: Icons.people,
                label: 'Estudiantes',
                onPressed: () => _navigateToDetails(context, 1),
              ),
              _ActionButton(
                icon: Icons.library_books,
                label: 'Materiales',
                onPressed: () => _navigateToDetails(context, 2),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(value),
      ],
    );
  }

  void _navigateToDetails(BuildContext context, int initialTab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectDetails(
          materiaId: materiaId,
          initialTab: initialTab,
        ),
      ),
    );
  }
}
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 32),
          onPressed: onPressed,
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}