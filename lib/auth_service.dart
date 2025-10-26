import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:school_connect/login_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  

  // Método para obtener usuarios creados por el admin actual
Stream<QuerySnapshot> getUsers() {
  final userId = _auth.currentUser?.uid;
  if (userId == null) {
    throw Exception('Usuario no autenticado');
  }

  // Consulta simple sin ordenamiento que podría requerir índices
  return _firestore.collection('users')
      .where('role', isNotEqualTo: 'admin')
      .snapshots();
}

  // Método de inicio de sesión
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  // Método para obtener el rol del usuario
Stream<String?> get userRole {
  return _auth.authStateChanges().asyncMap((user) async {
    if (user == null) return null;
    DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null; // Verificar existencia del documento
    return doc['role'] as String?;
  });
}

  // Método para cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

Future<void> createUserWithRole({
  required String email,
  required String password,
  required String role,
  required Map<String, dynamic> userData,
  required BuildContext context,
}) async {
  try {
    final currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      throw Exception('No hay usuario autenticado');
    }

    print('🔧 Admin actual: ${currentUser.email}');
    print('📊 userData completo recibido: $userData');

    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    print('✅ Usuario creado en Auth: ${userCredential.user!.email}');

    // Crear el mapa de datos del usuario
    final Map<String, dynamic> userDataMap = {
      'uid': userCredential.user!.uid,
      'email': email.trim(),
      'role': role,
      'createdBy': currentUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Copiar el nombre si existe
    if (userData.containsKey('nombre')) {
      userDataMap['nombre'] = userData['nombre'];
    }

    print('🔧 Creando usuario con rol: $role');

    // Si es estudiante
    if (role == 'student') {
      // Extraer el grado de userData o studentInfo
      int gradeInt = 0;
      
      // Primero intentar obtener de 'grade' directo
      if (userData.containsKey('grade')) {
        final gradeValue = userData['grade'];
        print('📊 grade en userData: $gradeValue (tipo: ${gradeValue.runtimeType})');
        
        if (gradeValue is int) {
          gradeInt = gradeValue;
        } else if (gradeValue is String) {
          gradeInt = int.tryParse(gradeValue) ?? 0;
        } else if (gradeValue is double) {
          gradeInt = gradeValue.toInt();
        }
      }
      
      // Si no encontramos el grado o es 0, buscar en studentInfo
      if (gradeInt == 0 && userData.containsKey('studentInfo')) {
        final studentInfo = userData['studentInfo'] as Map<String, dynamic>?;
        if (studentInfo != null && studentInfo.containsKey('grado')) {
          final gradoValue = studentInfo['grado'];
          print('📊 grado en studentInfo: $gradoValue (tipo: ${gradoValue.runtimeType})');
          
          if (gradoValue is int) {
            gradeInt = gradoValue;
          } else if (gradoValue is String) {
            gradeInt = int.tryParse(gradoValue) ?? 0;
          } else if (gradoValue is double) {
            gradeInt = gradoValue.toInt();
          }
        }
      }
      
      print('📊 Grado final convertido: $gradeInt');
      
      // VALIDAR que el grado sea válido (1-12)
      if (gradeInt < 1 || gradeInt > 12) {
        // Eliminar el usuario recién creado
        try {
          await userCredential.user!.delete();
        } catch (e) {
          print('⚠️ No se pudo eliminar el usuario de Auth: $e');
        }
        throw Exception('❌ ERROR: El grado debe estar entre 1 y 12. Valor recibido: $gradeInt\n\nPor favor, seleccione un grado válido del menú desplegable.');
      }
      
      // Guardar el grado como número en el nivel superior
      userDataMap['grade'] = gradeInt;
      
      // Crear studentInfo con el grado como string
      final Map<String, dynamic> studentInfo = {
        'grado': gradeInt.toString(),
      };
      
      // Copiar otros campos de studentInfo si existen
      if (userData.containsKey('studentInfo')) {
        final originalStudentInfo = userData['studentInfo'] as Map<String, dynamic>;
        if (originalStudentInfo.containsKey('seccion')) {
          studentInfo['seccion'] = originalStudentInfo['seccion'];
        }
        if (originalStudentInfo.containsKey('nombrePadre')) {
          studentInfo['nombrePadre'] = originalStudentInfo['nombrePadre'];
        }
        if (originalStudentInfo.containsKey('telefonoPadre')) {
          studentInfo['telefonoPadre'] = originalStudentInfo['telefonoPadre'];
        }
      }
      
      userDataMap['studentInfo'] = studentInfo;
      
      print('📊 Datos finales del estudiante:');
      print('   ✅ grade: ${userDataMap['grade']} (${userDataMap['grade'].runtimeType})');
      print('   ✅ studentInfo.grado: ${userDataMap['studentInfo']['grado']}');
      print('   ✅ studentInfo completo: ${userDataMap['studentInfo']}');
      
      // Escribir en Firestore
      try {
        await _firestore.collection('users')
           .doc(userCredential.user!.uid)
           .set(userDataMap);
        
        print('✅ Documento de estudiante creado en Firestore');
      } catch (e) {
        print('❌ Error al crear documento: $e');
        // Eliminar el usuario de Auth si falla la creación del documento
        try {
          await userCredential.user!.delete();
        } catch (_) {}
        throw Exception('Error al guardar los datos del estudiante: $e');
      }
      
      // Agregar a materias del grado
      print('📚 Agregando estudiante a materias del grado $gradeInt');
      try {
        await _agregarEstudianteAMaterias(userCredential.user!.uid, gradeInt.toString());
      } catch (e) {
        print('⚠️ Error al agregar a materias: $e');
        // No eliminamos el usuario aquí, solo registramos el error
      }
      
    } else if (role == 'teacher') {
      // Profesor
      print('👨‍🏫 Creando profesor');
      
      final Map<String, dynamic> teacherInfo = {
        'materias': [],
        'titulo': '',
        'especialidad': '',
        'experiencia': '',
        'idiomas': [],
      };
      
      if (userData.containsKey('teacherInfo')) {
        final originalTeacherInfo = userData['teacherInfo'] as Map<String, dynamic>;
        teacherInfo['titulo'] = originalTeacherInfo['titulo'] ?? '';
        teacherInfo['especialidad'] = originalTeacherInfo['especialidad'] ?? '';
        teacherInfo['experiencia'] = originalTeacherInfo['experiencia'] ?? '';
        teacherInfo['idiomas'] = originalTeacherInfo['idiomas'] ?? [];
      }
      
      userDataMap['teacherInfo'] = teacherInfo;
      
      await _firestore.collection('users')
         .doc(userCredential.user!.uid)
         .set(userDataMap);

      print('✅ Documento de profesor creado');
    } else {
      // Otro rol
      await _firestore.collection('users')
         .doc(userCredential.user!.uid)
         .set(userDataMap);

      print('✅ Documento creado');
    }

    // Cerrar sesión del usuario recién creado
    await _auth.signOut();
    print('🔒 Sesión del nuevo usuario cerrada');

    print('✅ Usuario creado exitosamente con rol: $role');

  } on FirebaseAuthException catch (e) {
    print('❌ Error FirebaseAuth: ${e.code} - ${e.message}');
    throw FirebaseAuthException(code: e.code, message: e.message);
  } catch (e) {
    print('❌ Error general: $e');
    rethrow;
  }
}

  // Método para crear una nueva materia
  Future<void> createMateria(
    String nombre,
    String grado,
    String profesorId,
    List<String> estudiantes,
  ) async {
    try {
      // Obtener estudiantes del grado automáticamente
      final estudiantesDelGrado = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('grade', isEqualTo: int.parse(grado))
          .get();

      final estudiantesIds = estudiantesDelGrado.docs
          .map((doc) => doc.id)
          .toList();

      print('📚 Creando materia: $nombre para grado $grado');
      print('👥 Estudiantes encontrados: ${estudiantesIds.length}');
      print('👨‍🏫 Profesor asignado: $profesorId');

      // Crear la materia con los estudiantes del grado
      final materiaRef = await _firestore.collection('materias').add({
        'nombre': nombre,
        'grado': grado,
        'profesorId': profesorId,
        'estudiantes': estudiantesIds,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      print('✅ Materia creada con ID: ${materiaRef.id}');

      // Actualizar el profesor para agregar esta materia
      final profesorDoc = await _firestore.collection('users').doc(profesorId).get();
      
      if (profesorDoc.exists) {
        final profesorData = profesorDoc.data() as Map<String, dynamic>;
        
        // Si no existe teacherInfo, crearlo
        if (!profesorData.containsKey('teacherInfo')) {
          await _firestore.collection('users').doc(profesorId).update({
            'teacherInfo': {
              'materias': [materiaRef.id],
              'titulo': '',
              'especialidad': '',
              'experiencia': '',
              'idiomas': [],
            }
          });
        } else {
          // Si existe, solo agregar la materia al array
          await _firestore.collection('users').doc(profesorId).update({
            'teacherInfo.materias': FieldValue.arrayUnion([materiaRef.id])
          });
        }
        
        print('✅ Materia agregada al profesor');
      }

    } catch (e) {
      print('❌ Error al crear materia: $e');
      throw Exception('Error al crear materia: ${e.toString()}');
    }
  }

  // Método para obtener las materias de un profesor
  Stream<QuerySnapshot> getMateriasByProfesor(String profesorId) {
    return _firestore.collection('materias')
        .where('profesorId', isEqualTo: profesorId)
        .snapshots();
  }

  // Método para obtener las materias de un estudiante
  Stream<QuerySnapshot> getMateriasByEstudiante(String estudianteId) {
    return _firestore.collection('materias')
        .where('estudiantes', arrayContains: estudianteId)
        .snapshots();
  }

  // Método para obtener todas las materias (para el admin)
  Stream<QuerySnapshot> getAllMaterias() {
    return _firestore.collection('materias').snapshots();
  }

  // Método para eliminar una materia
  Future<void> deleteMateria(String materiaId) async {
    try {
      print('🗑️ Eliminando materia: $materiaId');
      
      // Obtener datos de la materia antes de eliminarla
      final materiaDoc = await _firestore.collection('materias').doc(materiaId).get();
      
      if (materiaDoc.exists) {
        final materiaData = materiaDoc.data() as Map<String, dynamic>;
        final profesorId = materiaData['profesorId'];
        
        // Eliminar la referencia de la materia del profesor
        if (profesorId != null) {
          await _firestore.collection('users').doc(profesorId).update({
            'teacherInfo.materias': FieldValue.arrayRemove([materiaId])
          });
          print('✅ Referencia removida del profesor');
        }
      }
      
      // Eliminar la materia
      await _firestore.collection('materias').doc(materiaId).delete();
      print('✅ Materia eliminada');
      
    } catch (e) {
      print('❌ Error eliminando materia: $e');
      throw Exception('Error al eliminar materia: ${e.toString()}');
    }
  }

  // Método para actualizar una materia
  Future<void> updateMateria(
    String materiaId,
    String nombre,
    String grado,
    String profesorId,
    List<String> estudiantes,
  ) async {
    try {
      print('📝 Actualizando materia: $materiaId');
      
      // Obtener la materia actual
      final materiaActual = await _firestore
          .collection('materias')
          .doc(materiaId)
          .get();

      final profesorAnterior = materiaActual.data()?['profesorId'];

      // Obtener estudiantes del grado automáticamente
      final estudiantesDelGrado = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('grade', isEqualTo: int.parse(grado))
          .get();

      final estudiantesIds = estudiantesDelGrado.docs
          .map((doc) => doc.id)
          .toList();

      print('👥 Estudiantes del grado: ${estudiantesIds.length}');

      // Actualizar la materia
      await _firestore.collection('materias').doc(materiaId).update({
        'nombre': nombre,
        'grado': grado,
        'profesorId': profesorId,
        'estudiantes': estudiantesIds,
      });

      // Si cambió el profesor, actualizar ambos
      if (profesorAnterior != null && profesorAnterior != profesorId) {
        print('🔄 Cambiando profesor de $profesorAnterior a $profesorId');
        
        // Remover de profesor anterior
        final profesorAnteriorDoc = await _firestore.collection('users').doc(profesorAnterior).get();
        if (profesorAnteriorDoc.exists) {
          await _firestore.collection('users').doc(profesorAnterior).update({
            'teacherInfo.materias': FieldValue.arrayRemove([materiaId])
          });
        }

        // Agregar al nuevo profesor
        final nuevoProfesorDoc = await _firestore.collection('users').doc(profesorId).get();
        if (nuevoProfesorDoc.exists) {
          final profesorData = nuevoProfesorDoc.data() as Map<String, dynamic>;
          
          if (!profesorData.containsKey('teacherInfo')) {
            await _firestore.collection('users').doc(profesorId).update({
              'teacherInfo': {
                'materias': [materiaId],
                'titulo': '',
                'especialidad': '',
                'experiencia': '',
                'idiomas': [],
              }
            });
          } else {
            await _firestore.collection('users').doc(profesorId).update({
              'teacherInfo.materias': FieldValue.arrayUnion([materiaId])
            });
          }
        }
      } else if (profesorAnterior == null) {
        // Si no había profesor, agregar al nuevo
        final nuevoProfesorDoc = await _firestore.collection('users').doc(profesorId).get();
        if (nuevoProfesorDoc.exists) {
          final profesorData = nuevoProfesorDoc.data() as Map<String, dynamic>;
          
          if (!profesorData.containsKey('teacherInfo')) {
            await _firestore.collection('users').doc(profesorId).update({
              'teacherInfo': {
                'materias': [materiaId],
                'titulo': '',
                'especialidad': '',
                'experiencia': '',
                'idiomas': [],
              }
            });
          } else {
            await _firestore.collection('users').doc(profesorId).update({
              'teacherInfo.materias': FieldValue.arrayUnion([materiaId])
            });
          }
        }
      }

      print('✅ Materia actualizada correctamente');

    } catch (e) {
      print('❌ Error al actualizar materia: $e');
      throw Exception('Error al actualizar materia: ${e.toString()}');
    }
  }

  // Método para obtener los estudiantes de un grado específico
  Future<QuerySnapshot> getEstudiantesByGrado(String grado) async {
    return await _firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('grade', isEqualTo: grado)
        .get();
  }

Future<void> actualizarGradoEstudiante(String estudianteId, String nuevoGrado) async {
  try {
    print('🔄 Actualizando grado del estudiante: $estudianteId');
    
    final estudianteDoc = await _firestore.collection('users').doc(estudianteId).get();
    
    if (!estudianteDoc.exists) {
      throw Exception('Estudiante no encontrado');
    }
    
    final data = estudianteDoc.data() as Map<String, dynamic>?;
    final gradoAnterior = data?['grade'];

    print('📊 Grado anterior: $gradoAnterior, Nuevo grado: $nuevoGrado');

    final nuevoGradoInt = int.parse(nuevoGrado);
    
    // Validar que el grado sea válido
    if (nuevoGradoInt < 1 || nuevoGradoInt > 12) {
      throw Exception('Grado inválido: $nuevoGradoInt. Debe estar entre 1 y 12.');
    }

    // Remover de materias antiguas
    if (gradoAnterior != null && gradoAnterior != 0) {
      await _removerEstudianteDeMaterias(estudianteId, gradoAnterior.toString());
    }

    // Actualizar el grado en el usuario - ASEGURAR AMBOS CAMPOS
    await _firestore.collection('users').doc(estudianteId).update({
      'grade': nuevoGradoInt, // Como número
      'studentInfo.grado': nuevoGrado, // Como string en studentInfo
    });

    // Agregar a nuevas materias
    await _agregarEstudianteAMaterias(estudianteId, nuevoGrado);

    print('✅ Grado actualizado correctamente');
    
  } catch (e) {
    print('❌ Error actualizando grado: $e');
    throw Exception('Error al actualizar el grado del estudiante: ${e.toString()}');
  }
}

Future<void> _removerEstudianteDeMaterias(String estudianteId, String grado) async {
  print('🗑️ Removiendo estudiante de materias del grado $grado');
  
  // Obtener todas las materias del grado anterior
  final materias = await _firestore
      .collection('materias')
      .where('grado', isEqualTo: grado)
      .get();

  print('📚 Materias encontradas: ${materias.docs.length}');

  // Remover el estudiante de cada materia
  if (materias.docs.isEmpty) {
    return;
  }
  final batch = _firestore.batch();
  for (final materia in materias.docs) {
    batch.update(
      materia.reference,
      {
        'estudiantes': FieldValue.arrayRemove([estudianteId]), 
      },
    );
    print('➖ Removiendo de materia: ${materia.data()['nombre']}');
  }
  
  await batch.commit();
  print('✅ Estudiante removido de ${materias.docs.length} materias');
}

Future<void> _agregarEstudianteAMaterias(String estudianteId, String grado) async {
  print('➕ Agregando estudiante a materias del grado $grado');
  try {
    // Obtener todas las materias del grado correspondiente
    final materiasSnapshot = await _firestore
        .collection('materias')
        .where('grado', isEqualTo: grado)
        .get();

    if (materiasSnapshot.docs.isEmpty) {
      print('📭 No hay materias disponibles para el grado $grado');
      return;
    }

    final batch = _firestore.batch();
    for (final materia in materiasSnapshot.docs) {
      batch.update(
        materia.reference,
        {
          'estudiantes': FieldValue.arrayUnion([estudianteId])
        },
      );
      print('➕ Agregando a materia: ${materia.data()['nombre']}');
    }
    
    await batch.commit();
    print('✅ Estudiante agregado a ${materiasSnapshot.docs.length} materias');

  } catch (e) {
    print('❌ Error agregando estudiante a materias: $e');
    throw Exception('Error al asignar estudiante a las materias');
  }
}
}