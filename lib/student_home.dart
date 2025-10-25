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
import 'package:school_connect/screens/student/screens/dashboard_tab.dart'; // Importar para usar la función global

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _checkEventNotifications();
    _searchController.addListener(() {
      setState(() {
        _isSearching = _searchController.text.isNotEmpty;
      });
    });
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final AuthService authService = AuthService();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Cambiado para que el degradado sea visible
          foregroundColor: Colors.white,
          elevation: 1,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7B5FCE), // Púrpura institucional
                  Color(0xFF9575CD),
                  Color(0xFFB39DDB),
                ],
              ),
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.school, size: 28, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'School Connect',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // Barra de búsqueda mejorada
              Container(
                height: 40,
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Buscar tareas, eventos, materiales...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey.shade600, size: 20),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onTap: () {
                    if (_searchController.text.isEmpty) {
                      _showSearchSuggestions(context, userId);
                    }
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _showSearchResults(context, userId, value);
                    }
                  },
                ),
              ),
              const Spacer(),
            ],
          ),
          actions: [
            // Menú con avatar y nombre del usuario
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snapshot) {
                final nombre = snapshot.hasData
                    ? snapshot.data!['nombre'] ?? 'Usuario'
                    : 'Usuario';

                return PopupMenuButton<String>(
                  offset: const Offset(0, 50),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 18,
                          child: Text(
                            nombre[0].toUpperCase(),
                            style: TextStyle(
                              color: Color.fromARGB(255, 177, 153, 219), // Mismo púrpura claro
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre.split(' ')[0], // Solo el primer nombre
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, size: 20, color: Colors.white),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            FirebaseAuth.instance.currentUser!.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Divider(),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'recordatorios',
                      child: Row(
                        children: [
                          Icon(Icons.notifications),
                          SizedBox(width: 12),
                          Text('Mis recordatorios'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'notificaciones',
                      child: Row(
                        children: [
                          Icon(Icons.settings),
                          SizedBox(width: 12),
                          Text('Configurar notificaciones'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 12),
                          Text(
                            'Cerrar sesión',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'recordatorios':
                        _showActiveReminders(context, userId);
                        break;
                      case 'notificaciones':
                        _manageNotificationPermissions(context);
                        break;
                      case 'logout':
                        _cerrarSesion(context, authService);
                        break;
                    }
                  },
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60, // Más sutil cuando no está seleccionado
            indicatorColor: Colors.white,
            indicatorWeight: 3,
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

  void _showSearchSuggestions(BuildContext context, String userId) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.search, color: Colors.purple.shade700),
                  const SizedBox(width: 12),
                  const Text(
                    'Búsqueda rápida',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text(
                'Busca por:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildSearchSuggestionChip('Tareas pendientes', Icons.assignment),
              _buildSearchSuggestionChip('Eventos próximos', Icons.event),
              _buildSearchSuggestionChip('Materiales', Icons.library_books),
              _buildSearchSuggestionChip('Materias', Icons.book),
              const SizedBox(height: 16),
              const Text(
                'O escribe algo para buscar...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestionChip(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _searchController.text = label;
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.purple.shade700),
              const SizedBox(width: 12),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchResults(BuildContext context, String userId, String query) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.search, color: Colors.purple.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Resultados para "$query"',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: _SearchResultsWidget(userId: userId, query: query),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultsWidget extends StatelessWidget {
  final String userId;
  final String query;

  const _SearchResultsWidget({required this.userId, required this.query});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _performSearch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final results = snapshot.data!;
        final totalResults = results['tareas']!.length + 
                           results['eventos']!.length + 
                           results['materiales']!.length;

        if (totalResults == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron resultados',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (results['tareas']!.isNotEmpty) ...[
                _buildSectionHeader('Tareas (${results['tareas']!.length})', Icons.assignment),
                ...results['tareas']!.map((tarea) => _buildTaskCard(context, tarea)),
                const SizedBox(height: 16),
              ],
              if (results['eventos']!.isNotEmpty) ...[
                _buildSectionHeader('Eventos (${results['eventos']!.length})', Icons.event),
                ...results['eventos']!.map((evento) => _buildEventCard(context, evento)),
                const SizedBox(height: 16),
              ],
              if (results['materiales']!.isNotEmpty) ...[
                _buildSectionHeader('Materiales (${results['materiales']!.length})', Icons.library_books),
                ...results['materiales']!.map((material) => _buildMaterialCard(context, material)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> tarea) {
    final fechaEntrega = tarea['fechaEntregaDate'] as DateTime;
    final materiaColor = getMateriaColor(tarea['materiaNombre']); // Usar función importada
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: materiaColor.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: materiaColor.shade200, width: 1.5),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: materiaColor.shade100,
          child: Icon(Icons.assignment, color: materiaColor.shade700),
        ),
        title: Text(
          tarea['titulo'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: materiaColor.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: materiaColor.shade300),
              ),
              child: Text(
                tarea['materiaNombre'],
                style: TextStyle(
                  fontSize: 11,
                  color: materiaColor.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Entrega: ${DateFormat('d/MM/yyyy HH:mm').format(fechaEntrega)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: materiaColor),
        onTap: () {
          Navigator.pop(context);
          DefaultTabController.of(context).animateTo(1);
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> evento) {
    final fecha = evento['fecha'] as DateTime;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(Icons.event, color: Colors.green.shade700),
        ),
        title: Text(evento['titulo']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (evento['descripcion'] != null && evento['descripcion'].toString().isNotEmpty)
              Text(
                evento['descripcion'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              DateFormat('d \'de\' MMMM yyyy').format(fecha),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(context);
          // Navegar al tab de inicio donde están los eventos
          DefaultTabController.of(context).animateTo(0);
        },
      ),
    );
  }

  Widget _buildMaterialCard(BuildContext context, Map<String, dynamic> material) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.library_books, color: Colors.blue.shade700),
        ),
        title: Text(material['nombre']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(material['materiaNombre']),
            Text(
              material['tipo'] == 'enlace' ? 'Enlace' : 'Archivo ${material['formato']}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(context);
          // Navegar al tab de horario donde están los materiales
          DefaultTabController.of(context).animateTo(2);
        },
      ),
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _performSearch() async {
    final queryLower = query.toLowerCase();
    final results = {
      'tareas': <Map<String, dynamic>>[],
      'eventos': <Map<String, dynamic>>[],
      'materiales': <Map<String, dynamic>>[],
    };

    try {
      // Buscar tareas
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      final userGrade = userData['grade'];

      final materiasSnapshot = await FirebaseFirestore.instance
          .collection('materias')
          .where('grado', isEqualTo: userGrade)
          .get();

      for (var materiaDoc in materiasSnapshot.docs) {
        final materiaNombre = materiaDoc['nombre'];
        
        // Buscar tareas de esta materia
        final assignmentsSnapshot = await FirebaseFirestore.instance
            .collection('materias')
            .doc(materiaDoc.id)
            .collection('asignaciones')
            .get();

        for (var assignmentDoc in assignmentsSnapshot.docs) {
          final data = assignmentDoc.data();
          final titulo = data['titulo']?.toString().toLowerCase() ?? '';
          final descripcion = data['descripcion']?.toString().toLowerCase() ?? '';
          
          if (titulo.contains(queryLower) || 
              descripcion.contains(queryLower) ||
              materiaNombre.toString().toLowerCase().contains(queryLower)) {
            try {
              final fechaStr = data['fechaEntrega'];
              final horaStr = data['horaEntrega'] ?? '23:59';
              final fechaHora = DateTime.parse('$fechaStr $horaStr:00');
              
              results['tareas']!.add({
                ...data,
                'materiaNombre': materiaNombre,
                'fechaEntregaDate': fechaHora,
              });
            } catch (e) {
              // Ignorar tareas con fechas inválidas
            }
          }
        }

        // Buscar materiales de esta materia
        final materialesSnapshot = await FirebaseFirestore.instance
            .collection('materias')
            .doc(materiaDoc.id)
            .collection('materiales')
            .get();

        for (var materialDoc in materialesSnapshot.docs) {
          final data = materialDoc.data();
          final nombre = data['nombre']?.toString().toLowerCase() ?? '';
          
          if (nombre.contains(queryLower)) {
            results['materiales']!.add({
              ...data,
              'materiaNombre': materiaNombre,
            });
          }
        }
      }

      // Buscar eventos
      final eventosSnapshot = await FirebaseFirestore.instance
          .collection('eventos')
          .get();

      for (var eventoDoc in eventosSnapshot.docs) {
        final data = eventoDoc.data();
        final titulo = data['titulo']?.toString().toLowerCase() ?? '';
        final descripcion = data['descripcion']?.toString().toLowerCase() ?? '';
        final grados = data['grados'] as List;
        
        // Verificar si el evento es para el grado del usuario
        final gradoInt = userGrade is int ? userGrade : int.tryParse(userGrade.toString());
        final esParaMiGrado = grados.any((g) {
          final gInt = g is int ? g : int.tryParse(g.toString());
          return gInt == gradoInt;
        });

        if (esParaMiGrado && (titulo.contains(queryLower) || descripcion.contains(queryLower))) {
          final fecha = (data['fecha'] as Timestamp).toDate();
          results['eventos']!.add({
            ...data,
            'fecha': fecha,
          });
        }
      }

    } catch (e) {
      print('Error en búsqueda: $e');
    }

    return results;
  }
}