import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../services/auth_navigation_service.dart';
import 'event_form_dialog.dart';

class EventCard extends StatelessWidget {
  final DocumentSnapshot evento;
  final Map<String, dynamic> data;
  final bool esCreador;
  final String teacherId;

  const EventCard({
    super.key,
    required this.evento,
    required this.data,
    required this.esCreador,
    required this.teacherId,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = (data['fecha'] as Timestamp).toDate();
    final ahora = DateTime.now();
    final esPasado = fecha.isBefore(ahora);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSizes.paddingMedium),
        leading: _buildDateIcon(fecha, esPasado),
        title: _buildTitle(esPasado),
        subtitle: _buildSubtitle(context),
        trailing: esCreador ? _buildActions(context) : null,
      ),
    );
  }

  Widget _buildDateIcon(DateTime fecha, bool esPasado) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: esPasado 
              ? [Colors.grey.shade400, Colors.grey.shade600]
              : [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('d').format(fecha),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            DateFormat('MMM').format(fecha).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(bool esPasado) {
    return Row(
      children: [
        Expanded(
          child: Text(
            data['titulo'],
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              decoration: esPasado ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        if (!esCreador)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['descripcion']?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                data['descripcion'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildInfoChip(
                Icons.people,
                'Grados: ${(data['grados'] as List).join(", ")}',
                Colors.blue,
              ),
              if (data['hora']?.isNotEmpty ?? false)
                _buildInfoChip(Icons.access_time, data['hora'], Colors.orange),
              if (data['lugar']?.isNotEmpty ?? false)
                _buildInfoChip(Icons.location_on, data['lugar'], Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: IconButton(
            icon: Icon(Icons.edit, color: Colors.blue.shade700, size: 18),
            tooltip: 'Editar',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: () => EventFormDialog.show(context, teacherId, evento),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: IconButton(
            icon: Icon(Icons.delete, color: Colors.red.shade700, size: 18),
            tooltip: 'Eliminar',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: () => _deleteEvent(context),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteEvent(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 12),
            Text('Eliminar Evento'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de eliminar este evento?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await evento.reference.delete();
        if (context.mounted) {
          AuthNavigationService.showSuccessSnackBar(
            context,
            'Evento eliminado',
          );
        }
      } catch (e) {
        if (context.mounted) {
          AuthNavigationService.showErrorSnackBar(
            context,
            'Error: $e',
          );
        }
      }
    }
  }
}
