// student_home.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:school_connect/auth_service.dart';
import 'package:school_connect/login_screen.dart';
import 'package:school_connect/screens/student/screens/assignments_tab.dart';
import 'package:school_connect/screens/student/screens/dashboard_tab.dart';
import 'package:school_connect/screens/student/screens/schedule_tab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _checkEventNotifications();
  }

  Future<void> _requestNotificationPermission() async {
    if (kIsWeb) {
      try {
        // Verificar si el navegador soporta notificaciones
        final permission = html.Notification.permission;
        
        if (permission == 'default') {
          // Pedir permiso
          final result = await html.Notification.requestPermission();
          if (result == 'granted') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Notificaciones activadas'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        print('Error requesting notification permission: $e');
      }
    }
  }

  Future<void> _checkEventNotifications() async {
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

        // Si el evento es hoy
        if (fechaEventoSinHora.isAtSameMomentAs(today)) {
          await _showEventNotification(data['eventoTitulo'], fechaEvento);
          
          // Marcar como notificado
          await doc.reference.update({'notificado': true});
        }
      }
    } catch (e) {
      print('Error checking notifications: $e');
    }
  }

  Future<void> _showEventNotification(String titulo, DateTime fecha) async {
    if (kIsWeb) {
      try {
        // Verificar permiso
        if (html.Notification.permission == 'granted') {
          // Crear notificación del navegador
          html.Notification(
            '¡Evento Hoy! 🎉',
            body: '$titulo - ${DateFormat('d \'de\' MMMM').format(fecha)}',
            icon: '/icons/Icon-192.png', // Puedes cambiar esto por tu icono
          );
        }
      } catch (e) {
        print('Error showing browser notification: $e');
      }
    }

    // También mostrar diálogo en la app
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.event_available, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¡Evento Hoy!',
                style: TextStyle(fontSize: 20),
              ),
            ),
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
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡No olvides asistir a este evento!',
              style: TextStyle(fontSize: 14),
            ),
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

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final AuthService authService = AuthService();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Estudiante'),
          actions: [
            // Botón para gestionar notificaciones
            PopupMenuButton<String>(
              icon: const Icon(Icons.notifications),
              onSelected: (value) {
                if (value == 'ver') {
                  _showActiveReminders(context, userId);
                } else if (value == 'permisos') {
                  _manageNotificationPermissions(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'ver',
                  child: Row(
                    children: [
                      Icon(Icons.list),
                      SizedBox(width: 8),
                      Text('Mis recordatorios'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'permisos',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Configurar notificaciones'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _cerrarSesion(context, authService),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Inicio'),
              Tab(icon: Icon(Icons.assignment), text: 'Tareas'), 
              Tab(icon: Icon(Icons.schedule), text: 'Horario'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DashboardTab(userId: userId),
            AssignmentsTab(userId: userId),
            ScheduleTab(userId: userId),
          ],
        ),
      ),
    );
  }

  void _manageNotificationPermissions(BuildContext context) {
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
        statusText = 'Las notificaciones están bloqueadas. Debes habilitarlas desde la configuración del navegador.';
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                  ),
                ],
              ),
            ),
            if (permission == 'default') ...[
              const SizedBox(height: 16),
              const Text(
                'Las notificaciones te ayudarán a recordar eventos importantes.',
                style: TextStyle(fontSize: 14),
              ),
            ],
            if (permission == 'denied') ...[
              const SizedBox(height: 16),
              const Text(
                'Para habilitar las notificaciones:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Haz clic en el ícono de candado en la barra de direcciones\n'
                '2. Busca "Notificaciones"\n'
                '3. Cambia a "Permitir"',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
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

  void _showActiveReminders(BuildContext context, String userId) {
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              SizedBox(
                height: 300,
                child: StreamBuilder<QuerySnapshot>(
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
                            Icon(
                              Icons.notifications_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tienes recordatorios activos',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    // Ordenar en el cliente en lugar de en Firestore
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
                            leading: Icon(
                              Icons.event,
                              color: Colors.purple.shade700,
                            ),
                            title: Text(data['eventoTitulo']),
                            subtitle: Text(
                              DateFormat('d \'de\' MMMM yyyy').format(fecha),
                            ),
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
                ),
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

  void _cerrarSesion(BuildContext context, AuthService authService) async {
    try {
      await authService.signOut();
      if (kIsWeb) {
        html.window.location.reload();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }
}