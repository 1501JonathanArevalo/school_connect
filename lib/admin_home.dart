import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_connect/auth_service.dart';
import 'package:school_connect/login_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:school_connect/screens/admin/subject_form.dart';
import 'package:school_connect/screens/admin/user_form_dialog.dart';
import 'dart:html' as html;
import 'dart:math';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();


  // Función para convertir datos de Firestore de forma segura
  Map<String, dynamic> _cleanUserData(Map<String, dynamic> user) {
    return {
      'uid': user['uid']?.toString() ?? '',
      'email': user['email']?.toString() ?? '',
      'nombre': user['nombre']?.toString() ?? '',
      'role': user['role']?.toString() ?? 'student',
      'createdBy': user['createdBy']?.toString() ?? 'unknown',
      'isTestUser': user['isTestUser'] == true,
      if (user['role'] == 'student')
        'grade': _parseGrade(user['grade']),
    };
  }

  int _parseGrade(dynamic grade) {
    if (grade == null) return 1;
    if (grade is int) return grade;
    if (grade is String) return int.tryParse(grade) ?? 1;
    return 1;
  }

  void _cerrarSesion(BuildContext context) async {
    try {
      await _authService.signOut();
      if (kIsWeb) {
        html.window.location.reload();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  void _deleteUser(String uid) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: const Text('¿Estás seguro de eliminar este usuario?'),
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
      await _firestore.collection('users').doc(uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Usuario eliminado')),
      );
    }
  }

  // Generar usuarios aleatorios de prueba
  Future<void> _createRandomUsers(bool isStudent, int count) async {
    try {
      final batch = _firestore.batch();

      final nombres = isStudent
          ? [
              'Ana',
              'Carlos',
              'María',
              'Juan',
              'Sofía',
              'Diego',
              'Laura',
              'Pedro',
              'Lucía',
              'Miguel'
            ]
          : [
              'Prof. García',
              'Prof. Martínez',
              'Prof. López',
              'Prof. Rodríguez',
              'Prof. González'
            ];

      final apellidos = [
        'Pérez',
        'González',
        'Rodríguez',
        'Fernández',
        'López',
        'Martínez',
        'Sánchez',
        'Ramírez'
      ];

      for (int i = 0; i < count; i++) {
        final nombre =
            '${nombres[_random.nextInt(nombres.length)]} ${apellidos[_random.nextInt(apellidos.length)]}';
        final randomId = _random.nextInt(99999);
        final email = isStudent
            ? 'estudiante_test_$randomId@test.com'
            : 'profesor_test_$randomId@test.com';

        final docRef = _firestore.collection('users').doc();

        final userData = {
          'uid': docRef.id,
          'email': email,
          'nombre': nombre,
          'role': isStudent ? 'student' : 'teacher',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': 'admin_test',
          'isTestUser': true, // Marcador para identificar usuarios de prueba
        };

        if (isStudent) {
          userData['grade'] = _random.nextInt(12) + 1; // Grados del 1 al 12
        }

        batch.set(docRef, userData);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ ${count} ${isStudent ? "estudiantes" : "profesores"} de prueba creados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al crear usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Eliminar todos los usuarios de prueba
  Future<void> _deleteAllTestUsers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Eliminar Usuarios de Prueba'),
        content: const Text(
          '¿Estás seguro de eliminar TODOS los usuarios de prueba?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar Todos'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final testUsers = await _firestore
            .collection('users')
            .where('isTestUser', isEqualTo: true)
            .get();

        final batch = _firestore.batch();
        for (var doc in testUsers.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ ${testUsers.docs.length} usuarios de prueba eliminados'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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

  void _showRandomUsersDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.science,
                      color: Colors.purple.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Crear Usuarios de Prueba',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Selecciona cuántos usuarios crear:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              
              // Sección Estudiantes
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.school, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Estudiantes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTestUserButton(
                      context,
                      '5 Estudiantes',
                      Icons.school,
                      Colors.green,
                      () => _createRandomUsers(true, 5),
                    ),
                    const SizedBox(height: 8),
                    _buildTestUserButton(
                      context,
                      '10 Estudiantes',
                      Icons.school,
                      Colors.green,
                      () => _createRandomUsers(true, 10),
                    ),
                    const SizedBox(height: 8),
                    _buildTestUserButton(
                      context,
                      '100 Estudiantes',
                      Icons.school,
                      Colors.green,
                      () => _createRandomUsers(true, 100),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sección Profesores
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Profesores',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTestUserButton(
                      context,
                      '3 Profesores',
                      Icons.person,
                      Colors.blue,
                      () => _createRandomUsers(false, 3),
                    ),
                    const SizedBox(height: 8),
                    _buildTestUserButton(
                      context,
                      '5 Profesores',
                      Icons.person,
                      Colors.blue,
                      () => _createRandomUsers(false, 5),
                    ),
                    const SizedBox(height: 8),
                    _buildTestUserButton(
                      context,
                      '25 Profesores',
                      Icons.person,
                      Colors.blue,
                      () => _createRandomUsers(false, 25),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Botón de eliminar todos
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                  label: const Text(
                    'Eliminar todos los usuarios de prueba',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteAllTestUsers();
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Botón cerrar
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
        ),
      );
  }

  Widget _buildTestUserButton(
    BuildContext context,
    String label,
    IconData icon,
    MaterialColor color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
          onPressed();
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Estadísticas superiores
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(height: 120);
            }

            final users = snapshot.data!.docs;
            final totalUsers = users.where((u) => (u.data() as Map)['role'] != 'admin').length;
            final students = users.where((u) => (u.data() as Map)['role'] == 'student').length;
            final teachers = users.where((u) => (u.data() as Map)['role'] == 'teacher').length;
            final testUsers = users.where((u) => (u.data() as Map)['isTestUser'] == true).length;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7B5FCE), Color(0xFF9575CD)],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Usuarios',
                          totalUsers.toString(),
                          Icons.people,
                          Colors.white,
                          Colors.white.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Estudiantes',
                          students.toString(),
                          Icons.school,
                          Colors.greenAccent,
                          Colors.greenAccent.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Profesores',
                          teachers.toString(),
                          Icons.person,
                          Colors.blueAccent,
                          Colors.blueAccent.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Prueba',
                          testUsers.toString(),
                          Icons.science,
                          Colors.orangeAccent,
                          Colors.orangeAccent.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),

        // Botones de acción
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.school, size: 20),
                  label: const Text('Nuevo Estudiante'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => UserFormDialog(isStudent: true),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person, size: 20),
                  label: const Text('Nuevo Profesor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => UserFormDialog(isStudent: false),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lista de usuarios
        Expanded(child: _buildUserTab()),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').where('role', isNotEqualTo: 'admin').snapshots(),
      builder: (context, snapshot) {
        print('🔍 Estado: ${snapshot.connectionState}');

        if (snapshot.hasError) {
          print('❌ Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando usuarios...'),
              ],
            ),
          );
        }

        final allUsers = snapshot.data?.docs ?? [];
        
        // Filtrar documentos válidos
        final validUsers = allUsers.where((doc) {
          try {
            return doc.exists && doc.data() != null;
          } catch (e) {
            print('❌ Error validando documento ${doc.id}: $e');
            return false;
          }
        }).toList();

        // Separar profesores y estudiantes
        final teachers = validUsers.where((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            return data != null && 
                   data.containsKey('role') && 
                   data['role'] == 'teacher';
          } catch (e) {
            print('❌ Error procesando profesor ${doc.id}: $e');
            return false;
          }
        }).toList();

        final students = validUsers.where((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            return data != null && 
                   data.containsKey('role') && 
                   data['role'] == 'student';
          } catch (e) {
            print('❌ Error procesando estudiante ${doc.id}: $e');
            return false;
          }
        }).toList();

        // Agrupar estudiantes por curso
        final Map<int, List<QueryDocumentSnapshot>> studentsByGrade = {};
        for (var student in students) {
          try {
            final data = student.data() as Map<String, dynamic>?;
            if (data == null) continue;
            
            // Manejar diferentes tipos de datos para grade
            int grade = 0;
            if (data.containsKey('grade') && data['grade'] != null) {
              if (data['grade'] is int) {
                grade = data['grade'] as int;
              } else if (data['grade'] is String) {
                grade = int.tryParse(data['grade']) ?? 0;
              }
            }
            
            if (!studentsByGrade.containsKey(grade)) {
              studentsByGrade[grade] = [];
            }
            studentsByGrade[grade]!.add(student);
          } catch (e) {
            print('❌ Error agrupando estudiante ${student.id}: $e');
          }
        }

        // Ordenar los cursos
        final sortedGrades = studentsByGrade.keys.toList()..sort();

        print('✅ Profesores: ${teachers.length}, Estudiantes: ${students.length}');

        if (validUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No hay usuarios registrados'),
                const SizedBox(height: 16),
                Text(
                  'Crea tu primer estudiante o profesor',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Container(
          color: Colors.grey.shade100,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Sección de Profesores con diseño mejorado
              _buildSectionCard(
                title: 'Profesores',
                count: teachers.length,
                icon: Icons.person,
                color: Colors.blue,
                children: teachers.isEmpty
                    ? [_buildEmptyState('No hay profesores registrados', Icons.person_outline)]
                    : teachers.map((userDoc) {
                        try {
                          if (!userDoc.exists) return const SizedBox.shrink();
                          final user = userDoc.data() as Map<String, dynamic>?;
                          if (user == null || !user.containsKey('email')) {
                            return const SizedBox.shrink();
                          }
                          return _buildUserCard(user);
                        } catch (e) {
                          return const SizedBox.shrink();
                        }
                      }).toList(),
              ),
              const SizedBox(height: 16),
              // Sección de Estudiantes por grado
              _buildSectionCard(
                title: 'Estudiantes',
                count: students.length,
                icon: Icons.school,
                color: Colors.green,
                children: students.isEmpty
                    ? [_buildEmptyState('No hay estudiantes registrados', Icons.school_outlined)]
                    : sortedGrades.map((grade) {
                        final gradeStudents = studentsByGrade[grade] ?? [];
                        return _buildGradeSection(grade, gradeStudents);
                      }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
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
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildGradeSection(int grade, List<QueryDocumentSnapshot> students) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade100,
            radius: 20,
            child: Text(
              grade == 0 ? '?' : '$grade°',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(
            grade == 0 
                ? 'Sin grado asignado'
                : 'Grado $grade',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${students.length}',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          children: students.map((userDoc) {
            try {
              if (!userDoc.exists) return const SizedBox.shrink();
              final user = userDoc.data() as Map<String, dynamic>?;
              if (user == null || !user.containsKey('email')) {
                return const SizedBox.shrink();
              }
              return _buildUserCard(user, isInGradeSection: true);
            } catch (e) {
              return const SizedBox.shrink();
            }
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, {bool isInGradeSection = false}) {
    // Validar que el usuario tenga los campos mínimos necesarios
    if (!user.containsKey('uid') || !user.containsKey('email')) {
      print('⚠️ Usuario sin campos requeridos: $user');
      return const SizedBox.shrink();
    }

    final isTestUser = user['isTestUser'] == true;
    final nombre = user.containsKey('nombre') && user['nombre'] != null 
        ? user['nombre'] as String
        : user['email'] as String;
    final role = user['role'] ?? 'student';

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isInGradeSection ? 8 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isTestUser ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTestUser ? Colors.orange.shade200 : Colors.grey.shade200,
          width: 1,
        ),
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
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: role == 'student' 
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.blue.shade400, Colors.blue.shade600],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                role == 'student' ? Icons.school : Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
            if (isTestUser)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.science,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (isTestUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TEST',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 13, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      user['email'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              if (role == 'student' && user.containsKey('grade') && user['grade'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.class_outlined, size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        'Grado ${user['grade']}',
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
                onPressed: () async {
                  try {
                    final userDataCopy = _cleanUserData(user);
                    
                    final result = await showDialog(
                      context: context,
                      builder: (context) => UserFormDialog.edit(user: userDataCopy),
                    );
                    
                    if (result == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Usuario actualizado'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
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
                onPressed: () => _deleteUser(user['uid']?.toString() ?? ''),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Color(0xFF7B5FCE), // Púrpura institucional más oscuro
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 80, // Aumentado de 70 a 80
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Aumentado de 8 a 10
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12), // Aumentado de 10 a 12
                ),
                child: const Icon(Icons.admin_panel_settings, size: 32, color: Colors.white), // Aumentado de 28 a 32
              ),
              const SizedBox(width: 16), // Aumentado de 12 a 16
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Panel Administrador',
                    style: TextStyle(
                      fontSize: 22, // Aumentado de 20 a 22
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4), // Añadido espacio entre textos
                  Text(
                    'School Connect',
                    style: TextStyle(
                      fontSize: 13, // Aumentado de 12 a 13
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56), // Aumentado de 50 a 56
            child: Container(
              color: Color(0xFF9575CD),
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorPadding: EdgeInsets.symmetric(horizontal: 16),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600, 
                  fontSize: 15, // Aumentado de 14 a 15
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    icon: Icon(Icons.people, size: 24), // Aumentado de 22 a 24
                    height: 56, // Altura específica para las tabs
                    text: 'Usuarios',
                  ),
                  Tab(
                    icon: Icon(Icons.school, size: 24),
                    height: 56,
                    text: 'Materias',
                  ),
                  Tab(
                    icon: Icon(Icons.event, size: 24),
                    height: 56,
                    text: 'Eventos',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(10), // Aumentado de 8 a 10
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10), // Aumentado de 8 a 10
                  ),
                  child: const Icon(Icons.science, color: Colors.white, size: 22), // Aumentado de 20 a 22
                ),
                tooltip: 'Usuarios de prueba',
                onPressed: _showRandomUsersDialog,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(10), // Aumentado de 8 a 10
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10), // Aumentado de 8 a 10
                  ),
                  child: const Icon(Icons.logout, color: Colors.white, size: 22), // Aumentado de 20 a 22
                ),
                tooltip: 'Cerrar sesión',
                onPressed: () => _cerrarSesion(context),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildUsersTab(),
            SubjectForm(authService: _authService),
            _EventsTab(),
          ],
        ),
      ),
    );
  }
}

// Nueva clase para gestionar eventos
class _EventsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // Header con estadísticas y botón
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
                  stream: FirebaseFirestore.instance.collection('eventos').snapshots(),
                  builder: (context, snapshot) {
                    final totalEventos = snapshot.data?.docs.length ?? 0;
                    final now = DateTime.now();
                    final proximosEventos = snapshot.data?.docs.where((doc) {
                      final fecha = ((doc.data() as Map)['fecha'] as Timestamp).toDate();
                      return fecha.isAfter(now);
                    }).length ?? 0;
                    final eventospasados = totalEventos - proximosEventos;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildEventStatCard(
                            'Total',
                            totalEventos.toString(),
                            Icons.event,
                            Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildEventStatCard(
                            'Próximos',
                            proximosEventos.toString(),
                            Icons.event_available,
                            Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildEventStatCard(
                            'Pasados',
                            eventospasados.toString(),
                            Icons.event_busy,
                            Colors.grey,
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
                      'Crear Nuevo Evento',
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
                    onPressed: () => _showEventDialog(context),
                  ),
                ),
              ],
            ),
          ),

          // Lista de eventos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('eventos')
                  .orderBy('fecha', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final eventos = snapshot.data!.docs;

                if (eventos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay eventos creados',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu primer evento escolar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final evento = eventos[index];
                    final data = evento.data() as Map<String, dynamic>;
                    final fecha = (data['fecha'] as Timestamp).toDate();
                    final ahora = DateTime.now();
                    final esPasado = fecha.isBefore(ahora);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: esPasado 
                                  ? [Colors.grey.shade400, Colors.grey.shade600]
                                  : [Colors.green.shade400, Colors.green.shade600],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('d').format(fecha),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('MMM').format(fecha).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        title: Text(
                          data['titulo'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            decoration: esPasado ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (data['descripcion'] != null && 
                                  data['descripcion'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    data['descripcion'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _buildInfoChip(
                                    Icons.people,
                                    'Grados: ${(data['grados'] as List).join(", ")}',
                                    Colors.blue,
                                  ),
                                  if (data['hora'] != null && data['hora'].toString().isNotEmpty)
                                    _buildInfoChip(
                                      Icons.access_time,
                                      data['hora'],
                                      Colors.orange,
                                    ),
                                  if (data['lugar'] != null && data['lugar'].toString().isNotEmpty)
                                    _buildInfoChip(
                                      Icons.location_on,
                                      data['lugar'],
                                      Colors.red,
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
                                onPressed: () => _showEventDialog(context, evento),
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
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Row(
                                        children: [
                                          Icon(Icons.warning_amber, color: Colors.orange),
                                          const SizedBox(width: 12),
                                          const Text('Eliminar Evento'),
                                        ],
                                      ),
                                      content: const Text(
                                        '¿Estás seguro de eliminar este evento?\n\n'
                                        'Esta acción no se puede deshacer.',
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
                                    await evento.reference.delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text('Evento eliminado'),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
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

  Widget _buildEventStatCard(String title, String value, IconData icon, Color iconColor) {
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
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
                    'creadoEn': FieldValue.serverTimestamp(),
                  };

                  if (evento == null) {
                    await FirebaseFirestore.instance
                        .collection('eventos')
                        .add(data);
                  } else {
                    await evento.reference.update(data);
                  }

                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}