import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

// Función global para generar color único por materia
MaterialColor getMateriaColor(String materiaNombre) {
  final hash = materiaNombre.hashCode;
  final colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.deepOrange,
    Colors.lime,
    Colors.deepPurple,
  ];
  return colors[hash.abs() % colors.length];
}

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
          // Tarjeta de bienvenida eliminada
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
      final materiasSnapshot = await FirebaseFirestore.instance
          .collection('materias')
          .where('estudiantes', arrayContains: userId)
          .get();

      final List<Map<String, dynamic>> allAssignments = [];
      final now = DateTime.now();

      // Para cada materia, obtener asignaciones
      for (var materiaDoc in materiasSnapshot.docs) {
        final materiaId = materiaDoc.id;
        final materiaNombre = materiaDoc['nombre'];
        
        final assignmentsSnapshot = await FirebaseFirestore.instance
            .collection('materias')
            .doc(materiaId)
            .collection('asignaciones')
            .get();

        for (var assignmentDoc in assignmentsSnapshot.docs) {
          final data = assignmentDoc.data();
          try {
            final fechaStr = data['fechaEntrega'];
            final horaStr = data['horaEntrega'] ?? '23:59';
            
            DateTime fechaHora;
            try {
              fechaHora = DateTime.parse('$fechaStr $horaStr:00');
            } catch (e) {
              fechaHora = DateTime.parse(fechaStr);
              final horaParts = horaStr.split(':');
              fechaHora = DateTime(
                fechaHora.year,
                fechaHora.month,
                fechaHora.day,
                int.parse(horaParts[0]),
                int.parse(horaParts[1]),
              );
            }
            
            if (fechaHora.isAfter(now)) {
              allAssignments.add({
                ...data,
                'materiaId': materiaId,
                'materiaNombre': materiaNombre,
                'fechaEntregaDate': fechaHora,
              });
            }
          } catch (e) {
            // Error silencioso
          }
        }
      }

      allAssignments.sort((a, b) => 
        a['fechaEntregaDate'].compareTo(b['fechaEntregaDate']));

      return allAssignments;
    } catch (e) {
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

    // Obtener color de la materia usando la función global
    final materiaColor = getMateriaColor(assignment['materiaNombre']);
    final backgroundColor = isPastDue 
        ? Colors.grey.shade200 
        : isUrgent 
            ? Colors.red.shade50 
            : materiaColor.shade50;
    
    final borderColor = isPastDue
        ? Colors.grey.shade400
        : isUrgent 
            ? Colors.red.shade200 
            : materiaColor.shade200;

    final iconColor = isPastDue 
        ? Colors.grey 
        : isUrgent 
            ? Colors.red 
            : materiaColor;

    return InkWell(
      onTap: () => _showAssignmentDetailDialog(context, assignment, fechaEntrega),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Indicador de color de materia
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
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
                      // Chip de materia con color
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: materiaColor.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: materiaColor.shade300),
                        ),
                        child: Text(
                          assignment['materiaNombre'],
                          style: TextStyle(
                            fontSize: 11,
                            color: materiaColor.shade900,
                            fontWeight: FontWeight.w600,
                          ),
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
                            : materiaColor,
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
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
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

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('eventos')
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

                      // Filtrar por grado en el cliente
                      final eventosPorGrado = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final grados = data['grados'] as List;
                        
                        final gradoInt = grado is int ? grado : int.tryParse(grado.toString());
                        return grados.any((g) {
                          final gInt = g is int ? g : int.tryParse(g.toString());
                          return gInt == gradoInt;
                        });
                      }).toList();

                      // Filtrar eventos futuros
                      final now = DateTime.now();
                      final eventosFuturos = eventosPorGrado.where((doc) {
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
                          
                          return InkWell(
                            onTap: () => _showEventDetailDialog(context, data, fecha),
                            child: Container(
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
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
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

  void _showEventDetailDialog(
    BuildContext context,
    Map<String, dynamic> data,
    DateTime fecha,
  ) {
    final hora = data['hora'] ?? 'Todo el día';
    final lugar = data['lugar'] ?? 'No especificado';
    final descripcion = data['descripcion'] ?? '';
    final now = DateTime.now();
    final diasHasta = fecha.difference(now).inDays;

    // Obtener el ID del evento desde el contexto del StreamBuilder
    String? eventoId;
    
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('eventos')
            .where('titulo', isEqualTo: data['titulo'])
            .snapshots(),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.hasData && eventSnapshot.data!.docs.isNotEmpty) {
            eventoId = eventSnapshot.data!.docs.first.id;
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: eventoId != null 
                ? FirebaseFirestore.instance
                    .collection('notificaciones_eventos')
                    .doc('${FirebaseAuth.instance.currentUser!.uid}_$eventoId')
                    .snapshots()
                : null,
            builder: (context, notifSnapshot) {
              final tieneNotificacion = notifSnapshot.hasData && notifSnapshot.data!.exists;

              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header con ícono
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event, color: Colors.green.shade700, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Evento Escolar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Título del evento
                        Text(
                          data['titulo'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Badge de tiempo restante
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: diasHasta <= 3 
                                ? Colors.orange.shade50 
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: diasHasta <= 3 
                                  ? Colors.orange.shade200 
                                  : Colors.blue.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                diasHasta <= 3 
                                    ? Icons.warning_amber 
                                    : Icons.info_outline,
                                size: 20,
                                color: diasHasta <= 3 
                                    ? Colors.orange.shade700 
                                    : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                diasHasta == 0 
                                    ? '¡Hoy!' 
                                    : diasHasta == 1 
                                        ? 'Mañana' 
                                        : 'En $diasHasta días',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: diasHasta <= 3 
                                      ? Colors.orange.shade700 
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Botón de notificación
                        if (eventoId != null && diasHasta >= 0)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Material(
                              color: tieneNotificacion 
                                  ? Colors.purple.shade50 
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _toggleNotificacion(
                                  context,
                                  eventoId!,
                                  data['titulo'],
                                  fecha,
                                  tieneNotificacion,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        tieneNotificacion 
                                            ? Icons.notifications_active 
                                            : Icons.notifications_outlined,
                                        color: tieneNotificacion 
                                            ? Colors.purple.shade700 
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tieneNotificacion 
                                                  ? 'Notificación activada' 
                                                  : 'Activar recordatorio',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: tieneNotificacion 
                                                    ? Colors.purple.shade700 
                                                    : Colors.grey.shade800,
                                              ),
                                            ),
                                            Text(
                                              tieneNotificacion
                                                  ? 'Recibirás un recordatorio el día del evento'
                                                  : 'Te recordaremos el día del evento',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        tieneNotificacion 
                                            ? Icons.check_circle 
                                            : Icons.add_circle_outline,
                                        color: tieneNotificacion 
                                            ? Colors.purple.shade700 
                                            : Colors.grey.shade600,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        
                        // Fecha y hora
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
                                    'Fecha:',
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
                                    DateFormat('EEEE, d \'de\' MMMM yyyy').format(fecha),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Hora:',
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
                                    hora,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Lugar:',
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
                                    lugar,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        if (descripcion.isNotEmpty) ...[
                          const SizedBox(height: 20),
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
                              descripcion,
                              style: const TextStyle(fontSize: 15, height: 1.5),
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
              );
            },
          );
        },
        ),
      );
  }

  Future<void> _toggleNotificacion(
    BuildContext context,
    String eventoId,
    String eventoTitulo,
    DateTime fechaEvento,
    bool tieneNotificacion,
  ) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final docId = '${userId}_$eventoId';

    try {
      if (tieneNotificacion) {
        // Eliminar notificación
        await FirebaseFirestore.instance
            .collection('notificaciones_eventos')
            .doc(docId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.notifications_off, color: Colors.white),
                SizedBox(width: 8),
                Text('Recordatorio desactivado'),
              ],
            ),
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        // Crear notificación
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('¡Recordatorio activado! Te avisaremos el ${DateFormat('d/MM/yyyy').format(fechaEvento)}'),
                ),
              ],
            ),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
