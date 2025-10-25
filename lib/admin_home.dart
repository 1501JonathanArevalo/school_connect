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

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Fecha desconocida';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
    } catch (e) {
      return 'Fecha desconocida';
    }
  }

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
      builder: (context) => AlertDialog(
        title: const Text('🎲 Crear Usuarios de Prueba'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona cuántos usuarios crear:'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.school),
              label: const Text('5 Estudiantes'),
              onPressed: () {
                Navigator.pop(context);
                _createRandomUsers(true, 5);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.school),
              label: const Text('10 Estudiantes'),
              onPressed: () {
                Navigator.pop(context);
                _createRandomUsers(true, 10);
              },
            ),
                        const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.school),
              label: const Text('100 Estudiantes'),
              onPressed: () {
                Navigator.pop(context);
                _createRandomUsers(true, 100);
              },
            ),
            const Divider(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text('3 Profesores'),
              onPressed: () {
                Navigator.pop(context);
                _createRandomUsers(false, 3);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text('5 Profesores'),
              onPressed: () {
                Navigator.pop(context);
                _createRandomUsers(false, 5);
              },
            ),
                        const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text('25 Profesores'),
              onPressed: () {
                Navigator.pop(context);
                _createRandomUsers(false, 25);
              },
            ),
            const Divider(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              label: const Text(
                'Eliminar todos los de prueba',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteAllTestUsers();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTab() {
    print('🔍 Iniciando _buildUserTab');

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

        return ListView(
          children: [
            // Sección de Profesores
            ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.person, color: Colors.blue),
              title: Text(
                'Profesores (${teachers.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              children: teachers.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No hay profesores registrados',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ]
                  : teachers.map((userDoc) {
                      try {
                        if (!userDoc.exists) return const SizedBox.shrink();
                        final user = userDoc.data() as Map<String, dynamic>?;
                        if (user == null || !user.containsKey('email')) {
                          print('⚠️ Documento profesor ${userDoc.id} sin datos válidos');
                          return const SizedBox.shrink();
                        }
                        return _buildUserCard(user);
                      } catch (e) {
                        print('❌ Error construyendo card profesor ${userDoc.id}: $e');
                        return const SizedBox.shrink();
                      }
                    }).toList(),
            ),
            const Divider(height: 1),
            // Sección de Estudiantes agrupados por curso
            ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.school, color: Colors.green),
              title: Text(
                'Estudiantes (${students.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              children: students.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No hay estudiantes registrados',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ]
                  : sortedGrades.map((grade) {
                      final gradeStudents = studentsByGrade[grade] ?? [];
                      return ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            grade == 0 ? '?' : '$grade',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        title: Text(
                          grade == 0 
                              ? 'Sin grado asignado (${gradeStudents.length})'
                              : 'Grado $grade (${gradeStudents.length})',
                          style: const TextStyle(fontSize: 16),
                        ),
                        children: gradeStudents.map((userDoc) {
                          try {
                            if (!userDoc.exists) return const SizedBox.shrink();
                            final user = userDoc.data() as Map<String, dynamic>?;
                            if (user == null || !user.containsKey('email')) {
                              print('⚠️ Documento estudiante ${userDoc.id} sin datos válidos');
                              return const SizedBox.shrink();
                            }
                            return _buildUserCard(user);
                          } catch (e) {
                            print('❌ Error construyendo card estudiante ${userDoc.id}: $e');
                            return const SizedBox.shrink();
                          }
                        }).toList(),
                      );
                    }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isTestUser ? Colors.orange.shade50 : null,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: role == 'student' ? Colors.green : Colors.blue,
              child: Icon(
                role == 'student' ? Icons.school : Icons.person,
                color: Colors.white,
              ),
            ),
            if (isTestUser)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.science,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(nombre),
            ),
            if (isTestUser)
              const Chip(
                label: Text('TEST', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.orange,
                labelPadding: EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user['email']}'),
            if (role == 'student' && user.containsKey('grade') && user['grade'] != null)
              Text('Curso: Grado ${user['grade']}'),
            if (user.containsKey('createdAt'))
              Text('Creado: ${_formatDate(user['createdAt'])}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                try {
                  // Limpiar datos del usuario antes de editar
                  final userDataCopy = _cleanUserData(user);
                  
                  final result = await showDialog(
                    context: context,
                    builder: (context) => UserFormDialog.edit(user: userDataCopy),
                  );
                  
                  if (result == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Usuario actualizado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error al editar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteUser(user['uid']?.toString() ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Cambiar de 2 a 3
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Administrador'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_add), text: 'Usuarios'),
              Tab(icon: Icon(Icons.school), text: 'Materias'),
              Tab(icon: Icon(Icons.event), text: 'Eventos'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.science),
              tooltip: 'Crear usuarios de prueba',
              onPressed: _showRandomUsersDialog,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _cerrarSesion(context),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.school),
                        label: const Text('Crear Estudiante'),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => UserFormDialog(isStudent: true),
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person),
                        label: const Text('Crear Profesor'),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => UserFormDialog(isStudent: false),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildUserTab()),
              ],
            ),
            SubjectForm(authService: _authService),
            _EventsTab(), // Nueva pestaña
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

              final eventos = snapshot.data!.docs;

              if (eventos.isEmpty) {
                return const Center(child: Text('No hay eventos creados'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: eventos.length,
                itemBuilder: (context, index) {
                  final evento = eventos[index];
                  final data = evento.data() as Map<String, dynamic>;
                  final fecha = (data['fecha'] as Timestamp).toDate();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(
                          DateFormat('d').format(fecha),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(data['titulo']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['descripcion'] ?? ''),
                          Text('Grados: ${(data['grados'] as List).join(", ")}'),
                          Text(DateFormat('d MMMM yyyy').format(fecha)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Eliminar evento'),
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
                            await evento.reference.delete();
                          }
                        },
                      ),
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