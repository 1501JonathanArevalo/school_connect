import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_connect/auth_service.dart';
import 'widgets/schedule_selector.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../services/auth_navigation_service.dart';
import '../../services/schedule_service.dart';

class SubjectForm extends StatefulWidget {
  final AuthService? authService;

  const SubjectForm({super.key, this.authService});

  @override
  State<SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends State<SubjectForm> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // Header con estadísticas
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B5FCE), Color(0xFF9575CD)],
              ),
            ),
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('materias').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(height: 100);
                    }

                    final materias = snapshot.data!.docs;
                    final totalMaterias = materias.length;

                    // Contar profesores únicos
                    final profesores = materias
                        .map((m) => (m.data() as Map)['profesorId'])
                        .toSet()
                        .length;

                    // Contar grados únicos
                    final grados = materias
                        .map((m) => (m.data() as Map)['grado'])
                        .toSet()
                        .length;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Materias',
                            totalMaterias.toString(),
                            Icons.book,
                            Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Profesores',
                            profesores.toString(),
                            Icons.person,
                            Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Grados',
                            grados.toString(),
                            Icons.school,
                            Colors.greenAccent,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: const Text(
                      'Crear Nueva Materia',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF7B5FCE),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _showSubjectDialog(context),
                  ),
                ),
              ],
            ),
          ),

          // Lista de materias agrupadas por grado
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('materias').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final materias = snapshot.data!.docs;

                if (materias.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay materias creadas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu primera materia',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Agrupar por grado
                final Map<String, List<QueryDocumentSnapshot>> materiasPorGrado = {};
                for (var materia in materias) {
                  final data = materia.data() as Map<String, dynamic>;
                  final grado = data['grado'].toString();

                  if (!materiasPorGrado.containsKey(grado)) {
                    materiasPorGrado[grado] = [];
                  }
                  materiasPorGrado[grado]!.add(materia);
                }

                // Ordenar grados
                final gradosOrdenados = materiasPorGrado.keys.toList()
                  ..sort((a, b) {
                    final aInt = int.tryParse(a) ?? 0;
                    final bInt = int.tryParse(b) ?? 0;
                    return aInt.compareTo(bInt);
                  });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: gradosOrdenados.length,
                  itemBuilder: (context, index) {
                    final grado = gradosOrdenados[index];
                    final materiasDelGrado = materiasPorGrado[grado]!;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: index == 0,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          childrenPadding: const EdgeInsets.only(bottom: 8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.purple.shade400, Colors.purple.shade600],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '$grado°',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            'Grado $grado',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${materiasDelGrado.length} ${materiasDelGrado.length == 1 ? "materia" : "materias"}',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          children: materiasDelGrado.map((materia) {
                            return _buildMateriaCard(context, materia);
                          }).toList(),
                        ),
                      ),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMateriaCard(BuildContext context, QueryDocumentSnapshot materia) {
    final data = materia.data() as Map<String, dynamic>;
    final nombre = data['nombre'] ?? 'Sin nombre';
    final profesorId = data['profesorId'];
    final estudiantesCount = (data['estudiantes'] as List?)?.length ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.indigo.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.book,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          nombre,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profesor
              FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(profesorId).get(),
                builder: (context, snapshot) {
                  final profesorNombre = snapshot.hasData && snapshot.data != null
                      ? ((snapshot.data!.data() as Map?)?['nombre'] ?? 'Sin asignar')
                      : 'Cargando...';

                  return Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Prof. $profesorNombre',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              // Estudiantes
              Row(
                children: [
                  Icon(Icons.people_outline, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      '$estudiantesCount estudiantes',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.edit, color: Colors.blue.shade700, size: 18),
                tooltip: 'Editar',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () => _showSubjectDialog(context, materia: materia),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.delete, color: Colors.red.shade700, size: 18),
                tooltip: 'Eliminar',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () => _deleteSubject(context, materia),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubjectDialog(BuildContext context, {QueryDocumentSnapshot? materia}) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: materia != null ? (materia.data() as Map)['nombre'] : '',
    );

    String? selectedGrado = materia != null
        ? (materia.data() as Map)['grado'].toString()
        : null;
    String? selectedProfesor = materia != null
        ? (materia.data() as Map)['profesorId']
        : null;
    
    List<String> selectedSchedules = materia != null
        ? List<String>.from((materia.data() as Map)['horarios'] ?? [])
        : [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLarge)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                          ),
                          child: Icon(
                            Icons.book,
                            color: Colors.purple.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            materia == null ? 'Nueva Materia' : 'Editar Materia',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingLarge),

                    // Nombre de la materia
                    TextFormField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la Materia',
                        hintText: 'Ej: Matemáticas, Español, Ciencias',
                        prefixIcon: const Icon(Icons.book_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Ingrese el nombre' : null,
                    ),
                    const SizedBox(height: 20),

                    // Selector de grado
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('users')
                          .where('role', isEqualTo: 'student')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final grados = snapshot.data!.docs
                            .map((doc) => (doc.data() as Map)['grade'].toString())
                            .toSet()
                            .toList()
                          ..sort((a, b) {
                            final aInt = int.tryParse(a) ?? 0;
                            final bInt = int.tryParse(b) ?? 0;
                            return aInt.compareTo(bInt);
                          });

                        return DropdownButtonFormField<String>(
                          value: selectedGrado,
                          decoration: InputDecoration(
                            labelText: 'Grado',
                            prefixIcon: const Icon(Icons.school),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: grados.map((grado) {
                            return DropdownMenuItem(
                              value: grado,
                              child: Text('Grado $grado'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedGrado = value;
                              // Limpiar horarios cuando cambia el grado
                              selectedSchedules = [];
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Seleccione un grado' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Selector de profesor
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('users')
                          .where('role', isEqualTo: 'teacher')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final profesores = snapshot.data!.docs;

                        if (profesores.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No hay profesores registrados',
                                    style: TextStyle(color: Colors.orange.shade700),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedProfesor,
                          decoration: InputDecoration(
                            labelText: 'Profesor Asignado',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: profesores.map((profesor) {
                            final data = profesor.data() as Map;
                            return DropdownMenuItem(
                              value: profesor.id,
                              child: Text(data['nombre'] ?? data['email']),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => selectedProfesor = value),
                          validator: (value) =>
                              value == null ? 'Seleccione un profesor' : null,
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),

                    // Selector de horarios
                    if (selectedGrado != null)
                      ScheduleSelector(
                        grado: selectedGrado!,
                        initialSchedules: selectedSchedules,
                        excludeMateriaId: materia?.id,
                        onScheduleSelected: (schedules) {
                          setState(() => selectedSchedules = schedules);
                        },
                      ),

                    if (selectedSchedules.isEmpty && selectedGrado != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Seleccione al menos un horario',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: AppSizes.paddingLarge),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate() && 
                                  selectedSchedules.isNotEmpty) {
                                // Validar horarios antes de guardar
                                final isValid = await ScheduleService.validateSchedules(
                                  selectedSchedules,
                                  selectedGrado!,
                                  excludeMateriaId: materia?.id,
                                );

                                if (!isValid) {
                                  AuthNavigationService.showErrorSnackBar(
                                    context,
                                    'Algunos horarios están ocupados. Por favor, seleccione otros.',
                                  );
                                  return;
                                }

                                await _saveSubject(
                                  context,
                                  materia,
                                  nombreController.text.trim(),
                                  selectedGrado!,
                                  selectedProfesor!,
                                  selectedSchedules,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                              ),
                            ),
                            child: Text(materia == null ? 'Crear' : 'Guardar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      );
  }

  Future<void> _saveSubject(
    BuildContext context,
    QueryDocumentSnapshot? materia,
    String nombre,
    String grado,
    String profesorId,
    List<String> horarios,
  ) async {
    try {
      // Validar que haya horarios
      if (horarios.isEmpty) {
        if (context.mounted) {
          AuthNavigationService.showErrorSnackBar(
            context,
            'Debe seleccionar al menos un horario',
          );
        }
        return;
      }

      // Obtener estudiantes del grado
      final estudiantesSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('grade', isEqualTo: int.parse(grado))
          .get();

      final estudiantesIds = estudiantesSnapshot.docs.map((doc) => doc.id).toList();

      final data = {
        'nombre': nombre,
        'grado': grado,
        'profesorId': profesorId,
        'estudiantes': estudiantesIds,
        'horarios': horarios,
        'actualizadoEn': FieldValue.serverTimestamp(),
      };

      if (materia == null) {
        data['creadoEn'] = FieldValue.serverTimestamp();
        await _firestore.collection('materias').add(data);
      } else {
        await materia.reference.update(data);
      }

      if (context.mounted) {
        Navigator.pop(context);
        AuthNavigationService.showSuccessSnackBar(
          context,
          materia == null 
              ? '✅ Materia creada con ${horarios.length} horarios' 
              : '✅ Materia actualizada',
        );
      }
    } catch (e) {
      print('Error guardando materia: $e');
      if (context.mounted) {
        AuthNavigationService.showErrorSnackBar(
          context,
          '❌ Error: $e',
        );
      }
    }
  }

  Future<void> _deleteSubject(BuildContext context, QueryDocumentSnapshot materia) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('Eliminar Materia'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de eliminar esta materia?\n\n'
          'Se eliminarán todas las asignaciones y materiales asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Eliminar asignaciones
        final asignaciones = await materia.reference.collection('asignaciones').get();
        for (var doc in asignaciones.docs) {
          await doc.reference.delete();
        }

        // Eliminar materiales
        final materiales = await materia.reference.collection('materiales').get();
        for (var doc in materiales.docs) {
          await doc.reference.delete();
        }

        // Eliminar materia
        await materia.reference.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Materia eliminada'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}