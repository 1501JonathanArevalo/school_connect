import 'package:flutter/material.dart';
import 'package:school_connect/shared/widgets/app_bar_with_gradient.dart';
import 'package:school_connect/services/auth_navigation_service.dart';
import 'package:school_connect/shared/widgets/logout_button.dart';
import 'screens/admin/users_tab.dart';
import 'screens/admin/subjects_tab.dart';
import 'screens/admin/admin_events_tab.dart';
import 'scripts/fix_student_grades.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBarWithGradient(
          title: 'Panel Administrador',
          subtitle: 'School Connect',
          leadingIcon: Icons.admin_panel_settings,
          actions: [
            LogoutButton(
              onPressed: () => AuthNavigationService.signOut(context),
            ),
            IconButton(
              icon: const Icon(Icons.build_circle),
              tooltip: 'Corregir estudiantes',
              onPressed: () {
                _showFixStudentsDialog(context);
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              color: const Color(0xFF9575CD),
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorPadding: EdgeInsets.symmetric(horizontal: 16),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
                tabs: [
                  Tab(icon: Icon(Icons.people, size: 24), height: 56, text: 'Usuarios'),
                  Tab(icon: Icon(Icons.school, size: 24), height: 56, text: 'Materias'),
                  Tab(icon: Icon(Icons.event, size: 24), height: 56, text: 'Eventos'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            UsersTab(),
            SubjectsTab(),
            AdminEventsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.build),
          tooltip: 'Herramientas de mantenimiento',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Herramientas de Mantenimiento'),
                content: const Text(
                  'Esta herramienta corregirá los grados de todos los estudiantes que tengan grado 0.\n\n'
                  '¿Desea continuar?'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      
                      // Mostrar loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Corrigiendo grados...'),
                            ],
                          ),
                        ),
                      );

                      try {
                        await FixStudentGrades.fixAllStudentGrades();
                        Navigator.pop(context); // Cerrar loading
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Grados corregidos exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        Navigator.pop(context); // Cerrar loading
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Corregir'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Agregar este método para corregir estudiantes
  void _showFixStudentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.build_circle, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('Corregir Estudiantes'),
          ],
        ),
        content: const Text(
          'Esta herramienta buscará estudiantes con grado 0 o inválido '
          'y te permitirá asignarles el grado correcto.\n\n'
          '¿Deseas continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _fixStudentsWithGradeZero(context);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _fixStudentsWithGradeZero(BuildContext context) async {
    try {
      // Mostrar diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Buscando estudiantes...'),
            ],
          ),
        ),
      );

      print('🔧 Buscando estudiantes con grado 0 o inválido...');
      
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      // Filtrar estudiantes con grado 0 o null
      final studentsWithInvalidGrade = studentsSnapshot.docs.where((doc) {
        final data = doc.data();
        final grade = data['grade'];
        return grade == null || grade == 0;
      }).toList();

      print('📊 Estudiantes con grado inválido: ${studentsWithInvalidGrade.length}');

      // Cerrar diálogo de carga
      if (context.mounted) Navigator.pop(context);

      if (studentsWithInvalidGrade.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Todos los estudiantes tienen grado válido'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Procesar cada estudiante
      for (var doc in studentsWithInvalidGrade) {
        if (!context.mounted) break;
        
        final data = doc.data();
        final nombre = data['nombre'] ?? 'Sin nombre';
        final email = data['email'] ?? '';
        
        // Mostrar diálogo para asignar grado
        final grado = await showDialog<int>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Asignar Grado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estudiante: $nombre'),
                Text('Email: $email', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                const Text('Seleccione el grado correcto:'),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Grado',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(12, (i) => i + 1)
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text('Grado $g'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    Navigator.pop(context, value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Omitir este estudiante'),
              ),
            ],
          ),
        );

        if (grado != null && context.mounted) {
          try {
            // Actualizar el estudiante
            await doc.reference.update({
              'grade': grado,
              'studentInfo.grado': grado.toString(),
            });
            
            print('✅ Grado $grado asignado a $nombre');
            
            // Agregar a materias
            await FirebaseFirestore.instance
                .collection('materias')
                .where('grado', isEqualTo: grado.toString())
                .get()
                .then((materias) {
                  for (var materia in materias.docs) {
                    materia.reference.update({
                      'estudiantes': FieldValue.arrayUnion([doc.id])
                    });
                  }
                });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Grado $grado asignado a $nombre'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          } catch (e) {
            print('❌ Error actualizando $nombre: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error actualizando $nombre'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Proceso completado'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      print('❌ Error: $e');
      if (context.mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga si está abierto
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