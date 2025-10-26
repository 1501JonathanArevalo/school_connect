import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../services/schedule_service.dart';

class ScheduleSelector extends StatefulWidget {
  final String grado;
  final List<String> initialSchedules;
  final ValueChanged<List<String>> onScheduleSelected;
  final String? excludeMateriaId;

  const ScheduleSelector({
    super.key,
    required this.grado,
    required this.initialSchedules,
    required this.onScheduleSelected,
    this.excludeMateriaId,
  });

  @override
  State<ScheduleSelector> createState() => _ScheduleSelectorState();
}

class _ScheduleSelectorState extends State<ScheduleSelector> {
  final List<String> _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  final List<String> _horas = [
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

  late List<String> _selectedSlots;
  List<Map<String, String>> _occupiedSchedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedSlots = List.from(widget.initialSchedules);
    _loadOccupiedSchedules();
  }

  Future<void> _loadOccupiedSchedules() async {
    setState(() => _isLoading = true);
    final occupied = await ScheduleService.getOccupiedSchedules(
      widget.grado,
      excludeMateriaId: widget.excludeMateriaId,
    );
    setState(() {
      _occupiedSchedules = occupied;
      _isLoading = false;
    });
  }

  bool _isSlotOccupied(String slot) {
    return _occupiedSchedules.any((s) => s['horario'] == slot);
  }

  String _getOccupantName(String slot) {
    final occupant = _occupiedSchedules.firstWhere(
      (s) => s['horario'] == slot,
      orElse: () => {'nombre': ''},
    );
    return occupant['nombre'] ?? '';
  }

  void _toggleSlot(String slot) {
    if (_isSlotOccupied(slot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Este horario está ocupado por ${_getOccupantName(slot)}'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      if (_selectedSlots.contains(slot)) {
        _selectedSlots.remove(slot);
      } else {
        _selectedSlots.add(slot);
      }
      widget.onScheduleSelected(_selectedSlots);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              const Text(
                'Seleccione los horarios:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Leyenda
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(Colors.blue.shade100, 'Seleccionado'),
              _buildLegendItem(Colors.red.shade100, 'Ocupado'),
              _buildLegendItem(Colors.grey.shade100, 'Disponible'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Tabla de horarios
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildScheduleTable(),
          ),
          
          if (_selectedSlots.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Horarios seleccionados: ${_selectedSlots.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedSlots.map((slot) {
                      return Chip(
                        label: Text(
                          ScheduleService.formatSchedule(slot),
                          style: const TextStyle(fontSize: 11),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _toggleSlot(slot),
                        backgroundColor: Colors.blue.shade100,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildScheduleTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 1),
      columnWidths: {
        0: const FixedColumnWidth(80),
        for (int i = 1; i <= _dias.length; i++)
          i: const FixedColumnWidth(120),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: [
            _buildHeaderCell('Hora'),
            ..._dias.map((dia) => _buildHeaderCell(dia)),
          ],
        ),
        // Filas de horas
        ..._horas.map((hora) => _buildHourRow(hora)),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  TableRow _buildHourRow(String hora) {
    return TableRow(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Text(
              hora,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        ..._dias.map((dia) => _buildSlotCell(dia, hora)),
      ],
    );
  }

  Widget _buildSlotCell(String dia, String hora) {
    final slot = '$dia-$hora';
    final isOccupied = _isSlotOccupied(slot);
    final isSelected = _selectedSlots.contains(slot);
    final occupantName = isOccupied ? _getOccupantName(slot) : '';

    Color bgColor;
    if (isOccupied) {
      bgColor = Colors.red.shade100;
    } else if (isSelected) {
      bgColor = Colors.blue.shade100;
    } else {
      bgColor = Colors.grey.shade50;
    }

    return GestureDetector(
      onTap: () => _toggleSlot(slot),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: isSelected 
                ? Colors.blue.shade400 
                : isOccupied 
                    ? Colors.red.shade400 
                    : Colors.grey.shade300,
            width: isSelected || isOccupied ? 2 : 1,
          ),
        ),
        child: Center(
          child: isOccupied
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    occupantName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : isSelected
                  ? Icon(Icons.check, color: Colors.blue.shade700, size: 20)
                  : const Icon(Icons.add, color: Colors.grey, size: 16),
        ),
      ),
    );
  }
}
