import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_connect/screens/student/widgets/assignment_dialog.dart';

class AssignmentsSection extends StatelessWidget {
  final String materiaId;
  
  const AssignmentsSection({super.key, required this.materiaId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('materias')
          .doc(materiaId)
          .collection('asignaciones')
          .orderBy('fechaEntrega')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final asignaciones = snapshot.data!.docs;
        if (asignaciones.isEmpty) return const Text('No hay asignaciones pendientes.');
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: asignaciones.length,
          itemBuilder: (context, index) {
            final asignacion = asignaciones[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(asignacion['titulo']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Entrega: ${asignacion['fechaEntrega']}'),
                  if (asignacion['link']?.isNotEmpty ?? false)
                    InkWell(
                      child: const Text('Enlace de la tarea', 
                        style: TextStyle(color: Colors.blue)),
                      onTap: () => launchUrl(Uri.parse(asignacion['link'])),
                    ),
                ],
              ),
              onTap: () => showAssignmentDetails(context, asignacion),
            );
          },
        );
      },
    );
  }
}