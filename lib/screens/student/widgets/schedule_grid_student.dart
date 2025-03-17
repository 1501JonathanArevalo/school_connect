import 'package:flutter/material.dart';

class ScheduleGridStudent extends StatelessWidget {
  final List<Map<String, String>> horarios;

  const ScheduleGridStudent({super.key, required this.horarios});

  @override
  Widget build(BuildContext context) {
    final _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    final _horas = [
      '07:00-08:00',
      '08:00-09:00',
      '09:00-10:00',
      '10:00-11:00',
      '11:00-12:00',
      '12:00-13:00',
      '13:00-14:00',
      '14:00-15:00',
      '15:00-16:00',
      '16:00-17:00',
      '17:00-18:00',
    ];

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(100),
      },
      defaultColumnWidth: const FixedColumnWidth(150),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
          ),
          children: [
            const SizedBox(),
            ..._dias.map((dia) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  dia,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14
                  ),
                ),
              ),
            )),
          ],
        ),
        ..._horas.map((hora) => TableRow(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  hora,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500
                  ),
                ),
              ),
            ),
            ..._dias.map((dia) {
              final slot = '$dia-${hora.split('-')[0]}';
              final materiasEnSlot = horarios.where((h) => h['horario']!.contains(slot)).toList();
              
              return Container(
                height: 60,
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    color: materiasEnSlot.isNotEmpty 
                        ? Colors.blue.shade50
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: materiasEnSlot.isNotEmpty 
                        ? Border.all(color: Colors.blue.shade100)
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (materiasEnSlot.isNotEmpty)
                          Text(
                            materiasEnSlot.first['nombre']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (materiasEnSlot.length > 1)
                          Text(
                            '+${materiasEnSlot.length - 1} más',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.blue.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        )),
      ],
    );
  }
}