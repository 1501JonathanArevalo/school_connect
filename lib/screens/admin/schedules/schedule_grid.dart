import 'package:flutter/material.dart';

class ScheduleGrid extends StatefulWidget {
  final List<Map<String, String>> existingSchedules; // Cambiar dynamic por String
  final ValueChanged<List<String>> onScheduleSelected;

  const ScheduleGrid({
    super.key,
    required this.existingSchedules,
    required this.onScheduleSelected,
  });

  @override
  _ScheduleGridState createState() => _ScheduleGridState();
}

class _ScheduleGridState extends State<ScheduleGrid> {
  final List<String> _selectedSlots = [];
  final List<String> _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  final List<String> _horas = [
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

  // Función para obtener el nombre de la materia ocupante
  String _getOcupante(String slot) {
    final ocupante = widget.existingSchedules.firstWhere(
      (s) => s['horario'] == slot,
      orElse: () => {'nombre': ''},
    );
    return ocupante['nombre'] ?? '';
  }

  bool _isSlotOccupied(String slot) {
    return widget.existingSchedules.any((s) => s['horario'] == slot);
  }

  void _toggleSlot(String slot) {
    setState(() {
      if (_selectedSlots.contains(slot)) {
        _selectedSlots.remove(slot);
      } else {
        if (!_isSlotOccupied(slot)) {
          _selectedSlots.add(slot);
        }
      }
      widget.onScheduleSelected(_selectedSlots);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text('Seleccione los horarios:', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 20),
          Table(
            border: TableBorder.all(),
            columnWidths: const <int, TableColumnWidth>{
              0: FixedColumnWidth(80),
            },
            defaultColumnWidth: const FixedColumnWidth(200),
            children: [
              TableRow(
                children: [
                  const SizedBox(),
                  ..._dias.map((dia) => 
                    Center(child: Text(dia, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                    ),
                  ), // Paréntesis corregido aquí
                ],
              ),
              ..._horas.map((hora) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(hora, style: const TextStyle(fontSize: 12)),
                  ),
                  ..._dias.map((dia) {
                    final slot = '$dia-$hora';
                    final isOccupied = _isSlotOccupied(slot);
                    final nombreMateria = _getOcupante(slot);
                    
                    return GestureDetector(
                      onTap: () => _toggleSlot(slot),
                      child: SizedBox(
                        height: 30,
                        child: Container(
                          color: isOccupied 
                              ? Colors.red.withOpacity(0.3)
                              : _selectedSlots.contains(slot)
                                  ? Colors.blue.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.1),
                          child: Center(
                            child: isOccupied
                                ? Text(
                                    nombreMateria,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.red[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : _selectedSlots.contains(slot)
                                    ? const Icon(Icons.check, color: Colors.blue, size: 16)
                                    : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              )),
            ],
          ),
          const SizedBox(height: 5),
          const Text('Rojo: Ocupado | Azul: Seleccionado', 
              style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}