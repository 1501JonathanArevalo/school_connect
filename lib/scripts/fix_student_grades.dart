import 'package:cloud_firestore/cloud_firestore.dart';

class FixStudentGrades {
  static final _firestore = FirebaseFirestore.instance;

  /// Corrige los grados de todos los estudiantes existentes
  static Future<void> fixAllStudentGrades() async {
    print('🔧 Iniciando corrección de grados...');
    
    try {
      // Obtener todos los estudiantes
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      print('📊 Estudiantes encontrados: ${studentsSnapshot.docs.length}');

      int fixed = 0;
      int errors = 0;

      for (var doc in studentsSnapshot.docs) {
        try {
          final data = doc.data();
          final currentGrade = data['grade'];
          
          print('\n👤 Estudiante: ${data['nombre']} (${doc.id})');
          print('   Grade actual: $currentGrade (${currentGrade.runtimeType})');

          // Si el grade es 0 o null, intentar obtenerlo de studentInfo
          if (currentGrade == 0 || currentGrade == null) {
            final studentInfo = data['studentInfo'] as Map<String, dynamic>?;
            final gradoString = studentInfo?['grado'];
            
            print('   studentInfo.grado: $gradoString');

            // Si studentInfo.grado también es "0", este estudiante necesita asignación manual
            if (gradoString == "0" || gradoString == null || gradoString.isEmpty) {
              print('   ⚠️ Este estudiante necesita asignación manual de grado');
              errors++;
              continue;
            }

            // Convertir el grado de string a int
            final gradeInt = int.tryParse(gradoString) ?? 0;
            
            if (gradeInt > 0 && gradeInt <= 12) {
              await doc.reference.update({
                'grade': gradeInt,
                'studentInfo.grado': gradeInt.toString(),
              });
              
              print('   ✅ Grado actualizado a: $gradeInt');
              fixed++;
            } else {
              print('   ❌ Grado inválido: $gradeInt');
              errors++;
            }
          } else {
            // Asegurar que ambos campos estén sincronizados
            final gradeInt = currentGrade is int ? currentGrade : int.tryParse(currentGrade.toString()) ?? 0;
            
            if (gradeInt > 0) {
              await doc.reference.update({
                'grade': gradeInt,
                'studentInfo.grado': gradeInt.toString(),
              });
              
              print('   ✅ Grado sincronizado: $gradeInt');
              fixed++;
            }
          }
        } catch (e) {
          print('   ❌ Error procesando estudiante ${doc.id}: $e');
          errors++;
        }
      }

      print('\n📊 Resumen:');
      print('   ✅ Corregidos: $fixed');
      print('   ❌ Errores: $errors');
      print('   📝 Total: ${studentsSnapshot.docs.length}');
      
    } catch (e) {
      print('❌ Error general: $e');
      rethrow;
    }
  }

  /// Asigna un grado específico a un estudiante
  static Future<void> assignGradeToStudent(String studentId, int grade) async {
    if (grade < 1 || grade > 12) {
      throw Exception('El grado debe estar entre 1 y 12');
    }

    print('🔧 Asignando grado $grade al estudiante $studentId');

    try {
      // Actualizar el estudiante
      await _firestore.collection('users').doc(studentId).update({
        'grade': grade,
        'studentInfo.grado': grade.toString(),
      });

      // Agregar a materias del grado
      final materiasSnapshot = await _firestore
          .collection('materias')
          .where('grado', isEqualTo: grade.toString())
          .get();

      final batch = _firestore.batch();
      for (var materia in materiasSnapshot.docs) {
        batch.update(materia.reference, {
          'estudiantes': FieldValue.arrayUnion([studentId])
        });
      }
      await batch.commit();

      print('✅ Grado asignado correctamente');
      print('📚 Agregado a ${materiasSnapshot.docs.length} materias');

    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }
}
