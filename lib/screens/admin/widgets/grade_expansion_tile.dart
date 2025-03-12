import 'package:flutter/material.dart';
import 'package:school_connect/screens/admin/widgets/materia_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GradeExpansionTile extends StatelessWidget {
  final String grado;
  final List<QueryDocumentSnapshot> materias;
  final Function(String) onDeleteMateria;

  const GradeExpansionTile({
    super.key,
    required this.grado,
    required this.materias,
    required this.onDeleteMateria,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        leading: const Icon(Icons.class_, size: 30),
        title: Text('Grado $grado', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text('${materias.length} materias registradas'),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: materias.map((materia) => 
                MateriaCard(
                  materia: materia, 
                  onDelete: onDeleteMateria
                )
              ).toList(),
            ),
          )
        ],
      ),
    );
  }
}