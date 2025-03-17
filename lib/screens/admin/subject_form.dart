import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_connect/auth_service.dart';
import 'package:school_connect/screens/admin/widgets/grade_expansion_tile.dart';
import 'package:school_connect/screens/admin/schedules/schedule_grid.dart';

class SubjectForm extends StatefulWidget {
  final AuthService authService;

  const SubjectForm({super.key, required this.authService});

  @override
  State<SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends State<SubjectForm> {
  final _subjectFormKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  String _selectedSubjectGrade = '5';
  String? _selectedTeacherId;
  List<QueryDocumentSnapshot> _teachers = [];
  List<String> _selectedHorarios = [];
List<Map<String, String>> _existingSchedules = []; // De List<String> a List<Map>
  bool _showSubjectForm = false;
  bool _isLoadingSchedules = false;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    _loadExistingSchedules(_selectedSubjectGrade);
  }

  void _loadTeachers() async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .get();
    setState(() {
      _teachers = result.docs;
      if (_teachers.isNotEmpty) {
        _selectedTeacherId = _teachers.first.id;
      }
    });
  }

Future<void> _loadExistingSchedules(String grade) async {
  setState(() => _isLoadingSchedules = true);
  try {
    final result = await FirebaseFirestore.instance
        .collection('materias')
        .where('grado', isEqualTo: grade)
        .get();

    final schedules = result.docs
        .expand((doc) => (doc['horarios'] as List<dynamic>)
// En subject_form.dart, modificar el mapeo:
.map((h) => <String, String>{ // Forzar tipo explícito
  'horario': h.toString(),
  'nombre': doc['nombre'].toString()
}))
        .toList();

    setState(() => _existingSchedules = List<Map<String, String>>.from(schedules));
  } catch (e) {
    setState(() => _existingSchedules = []);
  } finally {
    setState(() => _isLoadingSchedules = false);
  }
}
  void _createSubject() async {
    if (_subjectFormKey.currentState!.validate()) {
      try {
        final estudiantesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('studentInfo.grado', isEqualTo: _selectedSubjectGrade)
            .get();

        await FirebaseFirestore.instance.collection('materias').add({
          'nombre': _subjectNameController.text,
          'grado': _selectedSubjectGrade,
          'profesorId': _selectedTeacherId,
          'estudiantes': estudiantesSnapshot.docs.map((doc) => doc.id).toList(),
          'horarios': _selectedHorarios,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _loadExistingSchedules(_selectedSubjectGrade);
        
        setState(() {
          _showSubjectForm = false;
          _subjectNameController.clear();
          _selectedHorarios.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Materia creada exitosamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⛔ Error: ${e.toString()}')),
        );
      }
    }
  }

@override
Widget build(BuildContext context) {
  return SingleChildScrollView( // Scroll general para toda la pestaña
    child: Column(
      children: [
        if (_isLoadingSchedules)
          const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: Icon(_showSubjectForm ? Icons.close : Icons.add),
            label: Text(_showSubjectForm ? 'Cancelar' : 'Agregar Materia'),
            onPressed: () => setState(() {
              _showSubjectForm = !_showSubjectForm;
              if (!_showSubjectForm) {
                _subjectNameController.clear();
                _selectedHorarios.clear();
              }
            }),
          ),
        ),
        if (_showSubjectForm) _buildCreateSubjectForm(),
        ConstrainedBox( // Limitar el alto del ListView.builder
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6, // Ajusta este valor según sea necesario
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('materias').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final materiasPorGrado = <String, List<QueryDocumentSnapshot>>{};
              for (var doc in snapshot.data!.docs) {
                final grado = doc['grado'];
                materiasPorGrado.putIfAbsent(grado, () => []).add(doc);
              }

              final sortedGrades = materiasPorGrado.keys.toList()
                ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

              return ListView.builder(
                itemCount: sortedGrades.length,
                itemBuilder: (context, index) {
                  final grado = sortedGrades[index];
                  return GradeExpansionTile(
                    grado: grado,
                    materias: materiasPorGrado[grado]!,
                    onDeleteMateria: (id) async {
                      await FirebaseFirestore.instance
                          .collection('materias').doc(id).delete();
                      _loadExistingSchedules(grado);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

  Widget _buildCreateSubjectForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _subjectFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _subjectNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la materia',
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingrese un nombre válido';
                return null;
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedSubjectGrade,
              decoration: const InputDecoration(
                labelText: 'Grado',
                prefixIcon: Icon(Icons.grade),
              ),
              items: List.generate(12, (i) => (i + 1).toString())
                  .map((grade) => DropdownMenuItem(
                        value: grade,
                        child: Text('Grado $grade'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedSubjectGrade = value);
                _loadExistingSchedules(value);
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedTeacherId,
              decoration: const InputDecoration(
                labelText: 'Profesor',
                prefixIcon: Icon(Icons.person),
              ),
              items: _teachers
                  .map((teacher) => DropdownMenuItem(
                        value: teacher.id,
                        child: Text(teacher['email']),
                      ))
                  .toList(),
              validator: (value) { // Validador agregado
                if (value == null || value.isEmpty) {
                  return 'Por favor selecciona un profesor';
                }
                return null;
              },
              onChanged: (value) => setState(() => _selectedTeacherId = value),
            ),
            ScheduleGrid(
              existingSchedules: _existingSchedules,
              onScheduleSelected: (selected) => _selectedHorarios = selected,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                  onPressed: () => setState(() => _showSubjectForm = false),
                ),
                ElevatedButton.icon(
                  onPressed: _createSubject,
                  icon: const Icon(Icons.save),
                  label: const Text('Crear Materia'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(180, 50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}