import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;

class NotificationService {
  static Future<void> requestPermission() async {
    if (!kIsWeb) return;
    
    try {
      final permission = html.Notification.permission;
      if (permission == 'default') {
        await html.Notification.requestPermission();
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }

  static Future<void> showNotification(String title, String body) async {
    if (!kIsWeb) return;
    
    try {
      if (html.Notification.permission == 'granted') {
        html.Notification(title, body: body, icon: '/icons/Icon-192.png');
      }
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  static Future<void> checkEventNotifications(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      final notificaciones = await FirebaseFirestore.instance
          .collection('notificaciones_eventos')
          .where('userId', isEqualTo: userId)
          .where('notificado', isEqualTo: false)
          .get();

      for (var doc in notificaciones.docs) {
        final data = doc.data();
        final fechaEvento = (data['fechaEvento'] as Timestamp).toDate();
        final fechaEventoSinHora = DateTime(
          fechaEvento.year,
          fechaEvento.month,
          fechaEvento.day,
        );

        if (fechaEventoSinHora.isAtSameMomentAs(today)) {
          await showNotification(
            '¡Evento Hoy! 🎉',
            '${data['eventoTitulo']} - ${DateFormat('d \'de\' MMMM').format(fechaEvento)}',
          );
          
          if (context.mounted) {
            _showEventDialog(context, data['eventoTitulo'], fechaEvento);
          }
          
          await doc.reference.update({'notificado': true});
        }
      }
    } catch (e) {
      print('Error checking notifications: $e');
    }
  }

  static void _showEventDialog(BuildContext context, String titulo, DateTime fecha) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.event_available, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('¡Evento Hoy!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hoy, ${DateFormat('d \'de\' MMMM').format(fecha)}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('¡No olvides asistir a este evento!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  static void showActiveReminders(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.purple.shade700),
                  const SizedBox(width: 12),
                  const Text(
                    'Mis Recordatorios',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              SizedBox(
                height: 300,
                child: _buildRemindersList(userId),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildRemindersList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notificaciones_eventos')
          .where('userId', isEqualTo: userId)
          .where('notificado', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final recordatorios = snapshot.data!.docs;

        if (recordatorios.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No tienes recordatorios activos',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        final recordatoriosOrdenados = List<QueryDocumentSnapshot>.from(recordatorios);
        recordatoriosOrdenados.sort((a, b) {
          final fechaA = (a.data() as Map<String, dynamic>)['fechaEvento'] as Timestamp;
          final fechaB = (b.data() as Map<String, dynamic>)['fechaEvento'] as Timestamp;
          return fechaA.compareTo(fechaB);
        });

        return ListView.builder(
          itemCount: recordatoriosOrdenados.length,
          itemBuilder: (context, index) {
            final data = recordatoriosOrdenados[index].data() as Map<String, dynamic>;
            final fecha = (data['fechaEvento'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.event, color: Colors.purple.shade700),
                title: Text(data['eventoTitulo']),
                subtitle: Text(DateFormat('d \'de\' MMMM yyyy').format(fecha)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await recordatoriosOrdenados[index].reference.delete();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void manageNotificationPermissions(BuildContext context) {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las notificaciones solo están disponibles en la versión web'),
        ),
      );
      return;
    }

    final permission = html.Notification.permission;
    String statusText;
    IconData statusIcon;
    Color statusColor;

    switch (permission) {
      case 'granted':
        statusText = 'Las notificaciones están activadas';
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'denied':
        statusText = 'Las notificaciones están bloqueadas';
        statusIcon = Icons.block;
        statusColor = Colors.red;
        break;
      default:
        statusText = 'No has dado permiso para notificaciones';
        statusIcon = Icons.info;
        statusColor = Colors.orange;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications),
            SizedBox(width: 8),
            Text('Notificaciones'),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor),
              const SizedBox(width: 12),
              Expanded(child: Text(statusText)),
            ],
          ),
        ),
        actions: [
          if (permission == 'default')
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await html.Notification.requestPermission();
                if (result == 'granted') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Notificaciones activadas'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Activar notificaciones'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  static Future<void> toggleEventNotification(
    String eventoId,
    String eventoTitulo,
    DateTime fechaEvento,
    bool currentlyHasNotification,
  ) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final docId = '${userId}_$eventoId';

    if (currentlyHasNotification) {
      await FirebaseFirestore.instance
          .collection('notificaciones_eventos')
          .doc(docId)
          .delete();
    } else {
      await FirebaseFirestore.instance
          .collection('notificaciones_eventos')
          .doc(docId)
          .set({
            'userId': userId,
            'eventoId': eventoId,
            'eventoTitulo': eventoTitulo,
            'fechaEvento': Timestamp.fromDate(fechaEvento),
            'fechaCreacion': FieldValue.serverTimestamp(),
            'notificado': false,
          });
    }
  }
}
