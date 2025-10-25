import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardTab extends StatelessWidget {
  final String userId;

  const DashboardTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          // Layout responsive: columnas en pantallas grandes, filas en móviles
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                // Pantallas grandes: 2 columnas
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna izquierda: Tareas (50%)
                    Expanded(
                      flex: 1,
                      child: _PendingAssignmentsSection(userId: userId),
                    ),
                    const SizedBox(width: 20),
                    // Columna derecha: Periódico arriba y Eventos abajo (50%)
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          const _StudentNewsSection(),
                          const SizedBox(height: 20),
                          _UpcomingEventsSection(userId: userId),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Pantallas pequeñas: columna única
                return Column(
                  children: [
                    _PendingAssignmentsSection(userId: userId),
                    const SizedBox(height: 20),
                    const _StudentNewsSection(),
                    const SizedBox(height: 20),
                    _UpcomingEventsSection(userId: userId),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
          builder: (context, snapshot) {
            final nombre = snapshot.hasData 
                ? snapshot.data!['nombre'] ?? 'Estudiante'
                : 'Estudiante';
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $nombre!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, d \'de\' MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Sección de tareas pendientes - altura completa
class _PendingAssignmentsSection extends StatelessWidget {
  final String userId;

  const _PendingAssignmentsSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 600), // Altura mínima
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Tareas Pendientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getPendingAssignments(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    print('❌ Error en tareas: ${snapshot.error}');
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final allAssignments = snapshot.data ?? [];

                  if (allAssignments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '¡No tienes tareas pendientes!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    children: allAssignments.map((assignment) => 
                      _buildAssignmentItem(context, assignment)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getPendingAssignments(String userId) async {
    try {
      print('🔍 Cargando tareas pendientes para usuario: $userId');
      
      // Obtener materias del estudiante
      final materiasSnapshot = await FirebaseFirestore.instance
          .collection('materias')
          .where('estudiantes', arrayContains: userId)
          .get();

      print('📚 Materias encontradas: ${materiasSnapshot.docs.length}');

      final List<Map<String, dynamic>> allAssignments = [];
      final now = DateTime.now();

      // Para cada materia, obtener asignaciones
      for (var materiaDoc in materiasSnapshot.docs) {
        final materiaId = materiaDoc.id;
        final materiaNombre = materiaDoc['nombre'];
        
        print('📖 Procesando materia: $materiaNombre ($materiaId)');
        
        final assignmentsSnapshot = await FirebaseFirestore.instance
            .collection('materias')
            .doc(materiaId)
            .collection('asignaciones')
            .get();

        print('📝 Asignaciones en $materiaNombre: ${assignmentsSnapshot.docs.length}');

        for (var assignmentDoc in assignmentsSnapshot.docs) {
          final data = assignmentDoc.data();
          try {
            final fechaStr = data['fechaEntrega'];
            final horaStr = data['horaEntrega'] ?? '23:59';
            
            print('📅 Procesando tarea: ${data['titulo']}');
            print('   Fecha: $fechaStr, Hora: $horaStr');
            
            // Combinar fecha y hora - agregar segundos si no están
            DateTime fechaHora;
            try {
              // Intentar parsear con formato completo
              fechaHora = DateTime.parse('$fechaStr $horaStr:00');
            } catch (e) {
              // Si falla, intentar solo con la fecha
              print('⚠️ Error parseando hora, usando solo fecha');
              fechaHora = DateTime.parse(fechaStr);
              // Agregar la hora manualmente
              final horaParts = horaStr.split(':');
              fechaHora = DateTime(
                fechaHora.year,
                fechaHora.month,
                fechaHora.day,
                int.parse(horaParts[0]),
                int.parse(horaParts[1]),
              );
            }
            
            print('   Fecha parseada: $fechaHora');
            print('   Está después de ahora: ${fechaHora.isAfter(now)}');
            
            if (fechaHora.isAfter(now)) {
              allAssignments.add({
                ...data,
                'materiaId': materiaId,
                'materiaNombre': materiaNombre,
                'fechaEntregaDate': fechaHora,
              });
              print('   ✅ Tarea agregada a la lista');
            } else {
              print('   ❌ Tarea vencida, no se agrega');
            }
          } catch (e) {
            print('❌ Error parsing date for assignment ${data['titulo']}: $e');
            print('   fechaEntrega: ${data['fechaEntrega']}');
            print('   horaEntrega: ${data['horaEntrega']}');
          }
        }
      }

      // Ordenar por fecha de entrega
      allAssignments.sort((a, b) => 
        a['fechaEntregaDate'].compareTo(b['fechaEntregaDate']));

      print('✅ Total de tareas pendientes: ${allAssignments.length}');

      return allAssignments;
    } catch (e) {
      print('❌ Error loading assignments: $e');
      return [];
    }
  }

  Widget _buildAssignmentItem(BuildContext context, Map<String, dynamic> assignment) {
    final fechaEntrega = assignment['fechaEntregaDate'] as DateTime;
    final now = DateTime.now();
    final difference = fechaEntrega.difference(now);
    
    final daysUntilDue = difference.inDays;
    final hoursUntilDue = difference.inHours;
    final minutesUntilDue = difference.inMinutes;
    
    final isUrgent = hoursUntilDue <= 24;
    final isPastDue = fechaEntrega.isBefore(now);

    String timeLabel;
    if (isPastDue) {
      timeLabel = 'Vencida';
    } else if (daysUntilDue == 0) {
      if (hoursUntilDue == 0) {
        timeLabel = '$minutesUntilDue min';
      } else {
        timeLabel = '$hoursUntilDue hrs';
      }
    } else if (daysUntilDue == 1) {
      timeLabel = 'Mañana';
    } else {
      timeLabel = '$daysUntilDue días';
    }

    return InkWell(
      onTap: () => _showAssignmentDetailDialog(context, assignment, fechaEntrega),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPastDue 
              ? Colors.grey.shade200 
              : isUrgent 
                  ? Colors.red.shade50 
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPastDue
                ? Colors.grey.shade400
                : isUrgent 
                    ? Colors.red.shade200 
                    : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isPastDue 
                      ? Colors.grey 
                      : isUrgent 
                          ? Colors.red 
                          : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment['titulo'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: isPastDue ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignment['materiaNombre'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPastDue 
                        ? Colors.grey 
                        : isUrgent 
                            ? Colors.red 
                            : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    timeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Entrega: ${DateFormat('d/MM/yyyy').format(fechaEntrega)} a las ${DateFormat('HH:mm').format(fechaEntrega)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignmentDetailDialog(
    BuildContext context,
    Map<String, dynamic> assignment,
    DateTime fechaEntrega,
  ) {
    final now = DateTime.now();
    final isPastDue = fechaEntrega.isBefore(now);
    final difference = fechaEntrega.difference(now);
    final isUrgent = difference.inHours <= 24;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con materia
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.book, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          assignment['materiaNombre'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Título
                Text(
                  assignment['titulo'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Estado de la tarea
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPastDue 
                        ? Colors.grey.shade200 
                        : isUrgent 
                            ? Colors.red.shade50 
                            : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPastDue
                          ? Colors.grey.shade400
                          : isUrgent 
                              ? Colors.red.shade200 
                              : Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPastDue 
                            ? Icons.error_outline 
                            : isUrgent 
                                ? Icons.warning_amber 
                                : Icons.check_circle_outline,
                        size: 20,
                        color: isPastDue 
                            ? Colors.grey.shade700 
                            : isUrgent 
                                ? Colors.red.shade700 
                                : Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPastDue 
                            ? 'Tarea Vencida' 
                            : isUrgent 
                                ? 'Entrega Urgente' 
                                : 'Pendiente',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isPastDue 
                              ? Colors.grey.shade700 
                              : isUrgent 
                                  ? Colors.red.shade700 
                                  : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Fecha y hora de entrega
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text(
                            'Fecha de entrega:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            DateFormat('EEEE, d \'de\' MMMM yyyy').format(fechaEntrega),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text(
                            'Hora de entrega:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            DateFormat('HH:mm').format(fechaEntrega),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Descripción
                const Text(
                  'Descripción:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    assignment['descripcion'],
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
                
                // Enlace si existe
                if (assignment['link'] != null && 
                    assignment['link'].toString().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Recursos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse(assignment['link']);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              assignment['link'],
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.open_in_new, 
                            size: 18, 
                            color: Colors.blue.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Botón de cerrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Sección de eventos próximos
class _UpcomingEventsSection extends StatelessWidget {
  final String userId;

  const _UpcomingEventsSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 280),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Eventos Próximos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (!userSnapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Error al cargar información del usuario',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final grado = userData?['grade'];

                  if (grado == null) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No se encontró el grado del estudiante',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // Consulta simplificada: solo filtrar por grado
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('eventos')
                        .where('grados', arrayContains: grado)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        print('❌ Error en eventos: ${snapshot.error}');
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Error al cargar eventos',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                              Text(
                                '${snapshot.error}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No hay eventos próximos',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      // Filtrar eventos futuros en el cliente
                      final now = DateTime.now();
                      final eventosFuturos = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final fecha = (data['fecha'] as Timestamp).toDate();
                        return fecha.isAfter(now);
                      }).toList();

                      // Ordenar por fecha
                      eventosFuturos.sort((a, b) {
                        final fechaA = ((a.data() as Map<String, dynamic>)['fecha'] as Timestamp).toDate();
                        final fechaB = ((b.data() as Map<String, dynamic>)['fecha'] as Timestamp).toDate();
                        return fechaA.compareTo(fechaB);
                      });

                      // Tomar solo los primeros 3
                      final eventosAMostrar = eventosFuturos.take(3).toList();

                      if (eventosAMostrar.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No hay eventos próximos',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: eventosAMostrar.map((evento) {
                          final data = evento.data() as Map<String, dynamic>;
                          final fecha = (data['fecha'] as Timestamp).toDate();
                          final hora = data['hora'] ?? '';
                          final lugar = data['lugar'] ?? '';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('d').format(fecha),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MMM').format(fecha).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['titulo'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (data['descripcion'] != null && 
                                          data['descripcion'].toString().isNotEmpty)
                                        Text(
                                          data['descripcion'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (hora.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time, 
                                              size: 12, 
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              hora,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (lugar.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on, 
                                              size: 12, 
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                lugar,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sección de noticias estudiantiles
class _StudentNewsSection extends StatelessWidget {
  const _StudentNewsSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 280),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.newspaper, color: Colors.purple.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Periódico Estudiantil',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.purple,
                    onPressed: () => _showCreateNewsDialog(context),
                  ),
                ],
              ),
              const Divider(),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('noticias')
                    .orderBy('fecha', descending: true)
                    .limit(3)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final noticias = snapshot.data!.docs;

                  if (noticias.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay noticias publicadas. ¡Sé el primero en escribir!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    children: noticias.map((noticia) {
                      final data = noticia.data() as Map<String, dynamic>;
                      final fecha = (data['fecha'] as Timestamp).toDate();
                      
                      return InkWell(
                        onTap: () => _showNewsDetail(context, data, noticia.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.purple,
                                    radius: 16,
                                    child: Text(
                                      data['autorNombre'][0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['titulo'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Por ${data['autorNombre']} • ${DateFormat('d MMM').format(fecha)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['contenido'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateNewsDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final tituloController = TextEditingController();
    final contenidoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Noticia'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Ingrese un título' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: contenidoController,
                  decoration: const InputDecoration(
                    labelText: 'Contenido',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Ingrese el contenido' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final user = FirebaseAuth.instance.currentUser!;
                final userData = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();

                await FirebaseFirestore.instance.collection('noticias').add({
                  'titulo': tituloController.text,
                  'contenido': contenidoController.text,
                  'autorId': user.uid,
                  'autorNombre': userData['nombre'],
                  'fecha': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Noticia publicada')),
                );
              }
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  void _showNewsDetail(BuildContext context, Map<String, dynamic> data, String noticiaId) {
    final fecha = (data['fecha'] as Timestamp).toDate();
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final isAuthor = data['autorId'] == currentUserId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['titulo']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Por ${data['autorNombre']} • ${DateFormat('d \'de\' MMMM yyyy, HH:mm').format(fecha)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const Divider(height: 20),
              Text(data['contenido']),
            ],
          ),
        ),
        actions: [
          if (isAuthor)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Eliminar noticia'),
                    content: const Text('¿Estás seguro?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await FirebaseFirestore.instance
                      .collection('noticias')
                      .doc(noticiaId)
                      .delete();
                  Navigator.pop(context);
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
