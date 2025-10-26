import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_connect/screens/student/utilities.dart';

class MaterialsSection extends StatelessWidget {
  final String materiaId;
  
  const MaterialsSection({super.key, required this.materiaId});

  Icon getFileIcon(String formato) {
    switch (formato.toLowerCase()) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description, color: Colors.blue);
      case 'xls':
      case 'xlsx':
        return const Icon(Icons.table_chart, color: Colors.green);
      case 'ppt':
      case 'pptx':
        return const Icon(Icons.slideshow, color: Colors.orange);
      default:
        return const Icon(Icons.insert_drive_file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('materias')
          .doc(materiaId)
          .collection('materiales')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final materiales = snapshot.data!.docs;
        if (materiales.isEmpty) return const Text('No hay materiales disponibles.');
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: materiales.length,
          itemBuilder: (context, index) {
            final material = materiales[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: getFileIcon(material['formato'] ?? ''),
              title: Text(material['nombre']),
              subtitle: material['tipo'] == 'enlace'
                  ? const Text('Enlace externo')
                  : Text('Archivo ${material['formato']}'),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => launchUrl(Uri.parse(
                  material['tipo'] == 'enlace' 
                    ? material['enlace'] 
                    : material['url']
                )),
              ),
            );
          },
        );
      },
    );
  }
}