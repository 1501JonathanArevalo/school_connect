import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:school_connect/auth_service.dart';
import 'package:school_connect/login_screen.dart';
import 'dart:html' as html;
import 'screens/teacher/grades_screen.dart';

class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final AuthService authService = AuthService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Profesor'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.school), text: 'Mis Clases'),
              Tab(icon: Icon(Icons.event), text: 'Eventos'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _cerrarSesion(context, authService),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            GradesScreen(teacherId: userId),
            _TeacherEventsTab(teacherId: userId),
          ],
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

class _TeacherEventsTab extends StatelessWidget {
  final String teacherId;

  const _TeacherEventsTab({required this.teacherId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Crear Evento'),
            onPressed: () => _showEventDialog(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('eventos')
                .orderBy('fecha', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Filtrar eventos creados por este profesor o sin creador
              final eventos = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return !data.containsKey('creadoPor') || data['creadoPor'] == teacherId;
              }).toList();

              if (eventos.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No has creado eventos',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: eventos.length,
                itemBuilder: (context, index) {
                  final evento = eventos[index];
                  final data = evento.data() as Map<String, dynamic>;
                  final fecha = (data['fecha'] as Timestamp).toDate();
                  final ahora = DateTime.now();
                  final esPasado = fecha.isBefore(ahora);
                  final esCreador = data['creadoPor'] == teacherId;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    color: esPasado ? Colors.grey.shade100 : null,
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: esPasado ? Colors.grey : Colors.green,
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
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              data['titulo'],
                              style: TextStyle(
                                decoration: esPasado ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          if (!esCreador)
                            const Chip(
                              label: Text('Admin', style: TextStyle(fontSize: 10)),
                              backgroundColor: Colors.orange,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['descripcion']?.isNotEmpty ?? false)
                            Text(
                              data['descripcion'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.people, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Grados: ${(data['grados'] as List).join(", ")}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                data['hora'] ?? 'Todo el día',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          if (data['lugar']?.isNotEmpty ?? false)
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  data['lugar'],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                        ],
                      ),
                      trailing: esCreador ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEventDialog(context, evento),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteEvent(context, evento),
                          ),
                        ],
                      ) : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEventDialog(BuildContext context, [DocumentSnapshot? evento]) {
    final formKey = GlobalKey<FormState>();
    final tituloController = TextEditingController(
      text: evento?.get('titulo'),
    );
    final descripcionController = TextEditingController(
      text: evento?.get('descripcion'),
    );
    final horaController = TextEditingController(
      text: evento?.get('hora') ?? '',
    );
    final lugarController = TextEditingController(
      text: evento?.get('lugar') ?? '',
    );
    
    DateTime selectedDate = evento != null 
        ? (evento.get('fecha') as Timestamp).toDate()
        : DateTime.now();
    
    List<int> selectedGrados = evento != null
        ? List<int>.from(evento.get('grados'))
        : [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(evento == null ? 'Crear Evento' : 'Editar Evento'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título del evento',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Ingrese un título' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      'Fecha: ${DateFormat('d/MM/yyyy').format(selectedDate)}',
                    ),
                    leading: const Icon(Icons.calendar_today),
                    trailing: const Icon(Icons.edit),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('es', 'ES'),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: horaController,
                    decoration: const InputDecoration(
                      labelText: 'Hora (opcional - ej: 10:00 AM)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                      hintText: 'Ej: 10:00 AM o Todo el día',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: lugarController,
                    decoration: const InputDecoration(
                      labelText: 'Lugar (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                      hintText: 'Ej: Auditorio, Cancha, Salón 101',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people, size: 20),
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
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(12, (index) {
                            final grado = index + 1;
                            return FilterChip(
                              label: Text('$grado°'),
                              selected: selectedGrados.contains(grado),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedGrados.add(grado);
                                  } else {
                                    selectedGrados.remove(grado);
                                  }
                                });
                              },
                              selectedColor: Colors.green.shade200,
                            );
                          }),
                        ),
                        if (selectedGrados.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Selecciona al menos un grado',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
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
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate() && selectedGrados.isNotEmpty) {
                  final data = {
                    'titulo': tituloController.text.trim(),
                    'descripcion': descripcionController.text.trim(),
                    'fecha': Timestamp.fromDate(selectedDate),
                    'hora': horaController.text.trim(),
                    'lugar': lugarController.text.trim(),
                    'grados': selectedGrados,
                    'creadoPor': teacherId,
                    'creadoEn': FieldValue.serverTimestamp(),
                  };

                  try {
                    if (evento == null) {
                      await FirebaseFirestore.instance
                          .collection('eventos')
                          .add(data);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Evento creado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      await evento.reference.update(data);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Evento actualizado'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else if (selectedGrados.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Selecciona al menos un grado'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(BuildContext context, DocumentSnapshot evento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Evento'),
        content: const Text('¿Estás seguro de eliminar este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await evento.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Evento eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}