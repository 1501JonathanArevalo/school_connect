import 'package:flutter/material.dart';

class ScheduleViewer extends StatelessWidget {
  final List<dynamic> horarios;

  const ScheduleViewer({super.key, required this.horarios});

  @override
  Widget build(BuildContext context) {
    final horariosFormateados = horarios
        .map((h) => h.toString().split('|')[0]) // Obtener solo el slot
        .toSet() // Eliminar duplicados
        .toList();

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: horariosFormateados.map((slot) {
        final parts = slot.split('-');
        return Chip(
          label: Text('${parts[0]} ${parts[1]}'),
          backgroundColor: Colors.blue[100],
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}