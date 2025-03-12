import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_connect/screens/student/utilities.dart';

void showAssignmentDetails(BuildContext context, Map<String, dynamic> asignacion) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(asignacion['titulo']),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Descripción: ${asignacion['descripcion']}'),
            const SizedBox(height: 10),
            Text('Entrega: ${asignacion['fechaEntrega']}'),
            const SizedBox(height: 10),
            Text('Creación: ${formatDate(asignacion['fechaCreacion'])}'),
            if (asignacion['link']?.isNotEmpty ?? false)
              Column(
                children: [
                  const SizedBox(height: 10),
                  InkWell(
                    child: const Text('Enlace de la tarea', 
                      style: TextStyle(color: Colors.blue)),
                    onTap: () => launchUrl(Uri.parse(asignacion['link'])),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar')),
      ],
    ),
  );
}