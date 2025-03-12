import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  final String materiaId;

  const AttendanceScreen({super.key, required this.materiaId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  late String _currentDate;
  String? _grado;

  @override
  void initState() {
    super.initState();
    _currentDate = _dateFormat.format(DateTime.now());
    _loadGrado();
  }

  Future<void> _loadGrado() async {
    final materiaDoc = await FirebaseFirestore.instance
        .collection('materias')
        .doc(widget.materiaId)
        .get();
    setState(() {
      _grado = materiaDoc['grado'];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_grado == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Asistencia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('grade', isEqualTo: _grado) // Filtramos por grado
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final estudiantes = snapshot.data!.docs;

          if (estudiantes.isEmpty) {
            return const Center(child: Text('No hay estudiantes en este grado'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: estudiantes.length,
            itemBuilder: (context, index) {
              final estudiante = estudiantes[index];
              final estudianteId = estudiante.id;

          return StreamBuilder<DocumentSnapshot>( // Cambia FutureBuilder por StreamBuilder
            stream: FirebaseFirestore.instance
                .collection('materias')
                .doc(widget.materiaId)
                .collection('estudiantes')
                .doc(estudianteId)
                .snapshots(), // Usa snapshots() en lugar de get()
            builder: (context, estudianteSnapshot) {
            final data = estudianteSnapshot.data?.data() as Map<String, dynamic>?;
            final asistencias = data?['asistencias'] ?? {}; // Si no existe, usa mapa vacío
            final presente = asistencias[_currentDate] ?? false;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text(estudiante['nombre']),
                      trailing: Switch(
                        value: presente,
                        onChanged: (value) => _updateAttendance(
                          estudianteId,
                          value,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateAttendance(String estudianteId, bool presente) async {
  final docRef = FirebaseFirestore.instance
      .collection('materias')
      .doc(widget.materiaId)
      .collection('estudiantes')
      .doc(estudianteId);

  // Crear documento si no existe
  if (!(await docRef.get()).exists) {
    await docRef.set({'asistencias': {}});
  }

  await docRef.update({
    'asistencias.$_currentDate': presente,
  });
}

// attendance_screen.dart (corrección completa)
Future<void> _selectDate() async {
  final selectedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2023),
    lastDate: DateTime.now(),
  );

  if (selectedDate != null) {
    setState(() {
      _currentDate = _dateFormat.format(selectedDate); // ✅ Esto fuerza la reconstrucción
    });
  }
}
}