import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_connect/screens/teacher/attendance_screen.dart';
import 'materials_section.dart'; // Nueva importación


class SubjectDetails extends StatefulWidget {
  final String materiaId;
  final int initialTab;

  const SubjectDetails({
    super.key,
    required this.materiaId,
    required this.initialTab,
  });

  @override
  State<SubjectDetails> createState() => _SubjectDetailsState();
}

class _SubjectDetailsState extends State<SubjectDetails> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('materias')
              .doc(widget.materiaId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('Cargando...');
            return Text(snapshot.data!['nombre']);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assignment)), 
            Tab(icon: Icon(Icons.people)), 
            Tab(icon: Icon(Icons.library_books)),
          ],
        ),
      ),
      body: // En las pestañas:
      TabBarView(
        controller: _tabController,
        children: [
          _BuildAssignments(materiaId: widget.materiaId),
          AttendanceScreen(materiaId: widget.materiaId), // Cambiamos esto
          MaterialsSection(materiaId: widget.materiaId), 
        ],
      ),
    );
  }
}

class _BuildAssignments extends StatefulWidget {
  final String materiaId;

  const _BuildAssignments({required this.materiaId});

  @override
  State<_BuildAssignments> createState() => _BuildAssignmentsState();
}

class _BuildAssignmentsState extends State<_BuildAssignments> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Nueva Tarea'),
            onPressed: () => _showAssignmentForm(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('materias')
                .doc(widget.materiaId)
                .collection('asignaciones')
                .orderBy('fechaEntrega')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final asignaciones = snapshot.data!.docs;

              if (asignaciones.isEmpty) {
                return const Center(child: Text('No hay tareas asignadas'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: asignaciones.length,
                itemBuilder: (context, index) {
                  final asignacion = asignaciones[index];
                  return _AssignmentCard(
                    asignacion: asignacion,
                    onEdit: () => _showAssignmentForm(
                      context, 
                      asignacion: asignacion,
                    ),
                    onDelete: () => _deleteAssignment(asignacion.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAssignmentForm(
    BuildContext context, {
    QueryDocumentSnapshot? asignacion,
  }) {
    final _formKey = GlobalKey<FormState>();
    final _tituloController = TextEditingController(
      text: asignacion?['titulo'],
    );
    final _descripcionController = TextEditingController(
      text: asignacion?['descripcion'],
    );
    final _fechaEntregaController = TextEditingController(
      text: asignacion?['fechaEntrega'],
    );
      final _linkController = TextEditingController(text: asignacion?['link']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(asignacion == null ? 'Nueva Tarea' : 'Editar Tarea'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese un título';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese una descripción';
                      }
                      return null;
                    },
                  ),
                                    const SizedBox(height: 16),
                  TextFormField(
                    controller: _linkController,
                    decoration: InputDecoration(
                    labelText: 'Enlace relacionado (opcional)',
                    prefixIcon: Icon(Icons.link),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty && !value.startsWith('http')) {
                        return 'Ingrese un enlace válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fechaEntregaController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de entrega (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese una fecha';
                      }
                      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                        return 'Formato inválido';
                      }
                      return null;
                    },
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
                if (_formKey.currentState!.validate()) {
                  await _saveAssignment(
                    widget.materiaId,
                    asignacion?.id,
                    _tituloController.text,
                    _descripcionController.text,
                    _linkController.text,
                    _fechaEntregaController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAssignment(
    String materiaId,
    String? asignacionId,
    String titulo,
    String descripcion,
    String link,
    String fechaEntrega,
  ) async {
    final collection = FirebaseFirestore.instance
        .collection('materias')
        .doc(materiaId)
        .collection('asignaciones');

    final data = {
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaEntrega': fechaEntrega,
      'link': link, // Nuevo campo
      'fechaCreacion': FieldValue.serverTimestamp(),
    };

    if (asignacionId == null) {
      await collection.add(data);
    } else {
      await collection.doc(asignacionId).update(data);
    }
  }

  Future<void> _deleteAssignment(String asignacionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tarea'),
        content: const Text('¿Estás seguro de eliminar esta tarea?'),
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
          .collection('materias')
          .doc(widget.materiaId)
          .collection('asignaciones')
          .doc(asignacionId)
          .delete();
    }
  }
}

class _AssignmentCard extends StatelessWidget {
  final QueryDocumentSnapshot asignacion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssignmentCard({
    required this.asignacion,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              asignacion['titulo'],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(asignacion['descripcion']),
            const SizedBox(height: 8),
            Text(
              'Fecha de entrega: ${asignacion['fechaEntrega']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

