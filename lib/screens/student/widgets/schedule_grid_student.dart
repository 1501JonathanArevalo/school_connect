import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';

class ScheduleGridStudent extends StatelessWidget {
  final List<Map<String, dynamic>> horarios;

  const ScheduleGridStudent({super.key, required this.horarios});

  @override
  Widget build(BuildContext context) {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    final horas = [
      '07:00',
      '08:00',
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: {
              0: const FixedColumnWidth(80),
              for (int i = 1; i <= dias.length; i++)
                i: const FixedColumnWidth(150),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7B5FCE), Color(0xFF9575CD)],
                  ),
                ),
                children: [
                  _buildHeaderCell('Hora'),
                  ...dias.map((dia) => _buildHeaderCell(dia)),
                ],
              ),
              // Filas de horas
              ...horas.map((hora) => _buildHourRow(hora, dias)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  TableRow _buildHourRow(String hora, List<String> dias) {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Text(
              hora,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        ...dias.map((dia) => _buildSlotCell(dia, hora)),
      ],
    );
  }

  Widget _buildSlotCell(String dia, String hora) {
    final slot = '$dia-$hora';
    
    // Buscar materias en este slot
    final materiasEnSlot = horarios.where((h) {
      final horario = h['horario'] as String;
      return horario == slot;
    }).toList();

    if (materiasEnSlot.isEmpty) {
      return Container(
        height: 70,
        color: Colors.transparent,
      );
    }

    // Si hay una materia
    final materia = materiasEnSlot.first;
    final nombre = materia['nombre'] as String;
    
    // Generar color basado en el nombre de la materia
    final color = _getMateriaColor(nombre);

    return Container(
      height: 70,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nombre,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (materiasEnSlot.length > 1)
              Text(
                '+${materiasEnSlot.length - 1}',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getMateriaColor(String materiaNombre) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
    ];
    
    final hash = materiaNombre.hashCode.abs();
    return colors[hash % colors.length];
  }
}