import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../services/auth_navigation_service.dart';

class EventFormDialog extends StatefulWidget {
  final String teacherId;
  final DocumentSnapshot? evento;

  const EventFormDialog({
    super.key,
    required this.teacherId,
    this.evento,
  });

  static Future<void> show(
    BuildContext context,
    String teacherId, [
    DocumentSnapshot? evento,
  ]) {
    return showDialog(
      context: context,
      builder: (context) => EventFormDialog(
        teacherId: teacherId,
        evento: evento,
      ),
    );
  }

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _horaController;
  late final TextEditingController _lugarController;
  late DateTime _selectedDate;
  late List<int> _selectedGrados;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(
      text: widget.evento?.get('titulo'),
    );
    _descripcionController = TextEditingController(
      text: widget.evento?.get('descripcion'),
    );
    _horaController = TextEditingController(
      text: widget.evento?.get('hora') ?? '',
    );
    _lugarController = TextEditingController(
      text: widget.evento?.get('lugar') ?? '',
    );
    _selectedDate = widget.evento != null 
        ? (widget.evento!.get('fecha') as Timestamp).toDate()
        : DateTime.now();
    _selectedGrados = widget.evento != null
        ? List<int>.from(widget.evento!.get('grados'))
        : [];
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _horaController.dispose();
    _lugarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSizes.paddingLarge),
                _buildTituloField(),
                const SizedBox(height: AppSizes.paddingMedium),
                _buildDescripcionField(),
                const SizedBox(height: AppSizes.paddingMedium),
                _buildDateSelector(),
                const SizedBox(height: AppSizes.paddingMedium),
                _buildHoraField(),
                const SizedBox(height: AppSizes.paddingMedium),
                _buildLugarField(),
                const SizedBox(height: AppSizes.paddingMedium),
                _buildGradosSelector(),
                const SizedBox(height: AppSizes.paddingLarge),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: Icon(
            Icons.event,
            color: Colors.purple.shade700,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            widget.evento == null ? 'Crear Evento' : 'Editar Evento',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTituloField() {
    return TextFormField(
      controller: _tituloController,
      decoration: InputDecoration(
        labelText: 'Título del evento',
        hintText: 'Ej: Reunión de padres',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Ingrese un título' : null,
    );
  }

  Widget _buildDescripcionField() {
    return TextFormField(
      controller: _descripcionController,
      decoration: InputDecoration(
        labelText: 'Descripción',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: 3,
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('es', 'ES'),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha del evento',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d \'de\' MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHoraField() {
    return TextFormField(
      controller: _horaController,
      decoration: InputDecoration(
        labelText: 'Hora (opcional)',
        hintText: 'Ej: 10:00 AM',
        prefixIcon: const Icon(Icons.access_time),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildLugarField() {
    return TextFormField(
      controller: _lugarController,
      decoration: InputDecoration(
        labelText: 'Lugar (opcional)',
        hintText: 'Ej: Auditorio',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildGradosSelector() {
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
              Icon(Icons.people, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              const Text(
                'Grados que asistirán:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (index) {
              final grado = index + 1;
              return FilterChip(
                label: Text('$grado°'),
                selected: _selectedGrados.contains(grado),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedGrados.add(grado);
                    } else {
                      _selectedGrados.remove(grado);
                    }
                  });
                },
                selectedColor: Colors.green.shade200,
              );
            }),
          ),
          if (_selectedGrados.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Selecciona al menos un grado',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
            ),
            child: Text(widget.evento == null ? 'Crear' : 'Guardar'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate() && _selectedGrados.isNotEmpty) {
      final data = {
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'fecha': Timestamp.fromDate(_selectedDate),
        'hora': _horaController.text.trim(),
        'lugar': _lugarController.text.trim(),
        'grados': _selectedGrados,
        'creadoPor': widget.teacherId,
        'creadoEn': FieldValue.serverTimestamp(),
      };

      try {
        if (widget.evento == null) {
          await FirebaseFirestore.instance
              .collection('eventos')
              .add(data);
          
          if (mounted) {
            AuthNavigationService.showSuccessSnackBar(
              context,
              'Evento creado exitosamente',
            );
          }
        } else {
          await widget.evento!.reference.update(data);
          
          if (mounted) {
            AuthNavigationService.showSuccessSnackBar(
              context,
              'Evento actualizado',
            );
          }
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          AuthNavigationService.showErrorSnackBar(
            context,
            'Error: $e',
          );
        }
      }
    }
  }
}
