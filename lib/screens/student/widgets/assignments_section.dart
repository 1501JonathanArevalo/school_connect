import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class AssignmentsSection extends StatelessWidget {
  final String materiaId;
  
  const AssignmentsSection({super.key, required this.materiaId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('materias')
          .doc(materiaId)
          .collection('asignaciones')
          .orderBy('fechaEntrega')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final asignaciones = snapshot.data!.docs;
        if (asignaciones.isEmpty) return const Text('No hay asignaciones pendientes.');
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: asignaciones.length,
          itemBuilder: (context, index) {
            final asignacion = asignaciones[index].data() as Map<String, dynamic>;
            final horaEntrega = asignacion['horaEntrega'] ?? '23:59';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.assignment),
                title: Text(asignacion['titulo']),
                subtitle: Text('Entrega: ${asignacion['fechaEntrega']} a las $horaEntrega'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAssignmentDetail(context, asignacion),
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignmentDetail(BuildContext context, Map<String, dynamic> assignment) {
    final fechaStr = assignment['fechaEntrega'];
    final horaStr = assignment['horaEntrega'] ?? '23:59';
    
    DateTime fechaEntrega;
    try {
      fechaEntrega = DateTime.parse('$fechaStr $horaStr:00');
    } catch (e) {
      fechaEntrega = DateTime.parse(fechaStr);
      final horaParts = horaStr.split(':');
      fechaEntrega = DateTime(
        fechaEntrega.year,
        fechaEntrega.month,
        fechaEntrega.day,
        int.parse(horaParts[0]),
        int.parse(horaParts[1]),
      );
    }

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
                // Título
                Text(
                  assignment['titulo'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Estado
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
                
                // Enlace
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
                
                // Botón cerrar
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