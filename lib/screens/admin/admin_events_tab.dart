import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/widgets/gradient_header.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../teacher/widgets/event_card.dart';
import '../teacher/widgets/event_form_dialog.dart';

class AdminEventsTab extends StatelessWidget {
  const AdminEventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildEventsList(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GradientHeader(
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('eventos').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(height: 100);
              }

              final eventos = snapshot.data!.docs;
              final now = DateTime.now();
              final proximosEventos = eventos.where((doc) {
                final fecha = ((doc.data() as Map)['fecha'] as Timestamp).toDate();
                return fecha.isAfter(now);
              }).length;
              final eventosPasados = eventos.length - proximosEventos;

              return Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total',
                      value: eventos.length.toString(),
                      icon: Icons.event,
                      iconColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Próximos',
                      value: proximosEventos.toString(),
                      icon: Icons.event_available,
                      iconColor: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Pasados',
                      value: eventosPasados.toString(),
                      icon: Icons.event_busy,
                      iconColor: Colors.grey,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 22),
              label: const Text(
                'Crear Nuevo Evento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                elevation: 0,
              ),
              onPressed: () => EventFormDialog.show(context, 'admin'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('eventos')
          .orderBy('fecha', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final eventos = snapshot.data!.docs;

        if (eventos.isEmpty) {
          return const EmptyState(
            icon: Icons.event_busy,
            title: 'No hay eventos creados',
            subtitle: 'Crea tu primer evento escolar',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          itemCount: eventos.length,
          itemBuilder: (context, index) {
            final evento = eventos[index];
            final data = evento.data() as Map<String, dynamic>;

            return EventCard(
              evento: evento,
              data: data,
              esCreador: true,
              teacherId: 'admin',
            );
          },
        );
      },
    );
  }
}
