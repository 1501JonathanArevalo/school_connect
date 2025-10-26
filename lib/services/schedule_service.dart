import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener horarios ocupados para un grado específico
  static Future<List<Map<String, String>>> getOccupiedSchedules(
    String grado, {
    String? excludeMateriaId,
  }) async {
    try {
      final materiasSnapshot = await _firestore
          .collection('materias')
          .where('grado', isEqualTo: grado)
          .get();

      final List<Map<String, String>> occupied = [];

      for (var materia in materiasSnapshot.docs) {
        // Excluir la materia actual si se está editando
        if (excludeMateriaId != null && materia.id == excludeMateriaId) {
          continue;
        }

        final data = materia.data();
        final horarios = data['horarios'] as List<dynamic>?;
        final nombre = data['nombre'] as String;

        if (horarios != null && horarios.isNotEmpty) {
          for (var horario in horarios) {
            occupied.add({
              'horario': horario.toString(),
              'nombre': nombre,
              'materiaId': materia.id,
            });
          }
        }
      }

      return occupied;
    } catch (e) {
      print('Error obteniendo horarios ocupados: $e');
      return [];
    }
  }

  /// Validar que no haya conflictos de horarios
  static Future<bool> validateSchedules(
    List<String> newSchedules,
    String grado, {
    String? excludeMateriaId,
  }) async {
    try {
      final occupied = await getOccupiedSchedules(
        grado,
        excludeMateriaId: excludeMateriaId,
      );
      
      final occupiedSlots = occupied.map((o) => o['horario']).toSet();

      for (var schedule in newSchedules) {
        if (occupiedSlots.contains(schedule)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error validando horarios: $e');
      return false;
    }
  }

  /// Formatear horario para mostrar
  static String formatSchedule(String schedule) {
    try {
      final parts = schedule.split('-');
      if (parts.length >= 2) {
        final dia = parts[0];
        final hora = parts[1];
        return '$dia $hora';
      }
      return schedule;
    } catch (e) {
      return schedule;
    }
  }

  /// Obtener horarios de un estudiante
  static Future<List<Map<String, dynamic>>> getStudentSchedule(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        print('Usuario no encontrado');
        return [];
      }

      final userData = userDoc.data();
      if (userData == null) {
        print('Datos de usuario null');
        return [];
      }

      final grado = userData['grade'];
      if (grado == null) {
        print('Grado no encontrado para el usuario');
        return [];
      }

      // Convertir grado a string para la comparación
      final gradoStr = grado.toString();

      final materiasSnapshot = await _firestore
          .collection('materias')
          .where('grado', isEqualTo: gradoStr)
          .get();

      final List<Map<String, dynamic>> schedule = [];

      for (var materia in materiasSnapshot.docs) {
        final data = materia.data();
        final horarios = data['horarios'] as List<dynamic>?;
        final nombre = data['nombre'] as String?;

        if (horarios != null && horarios.isNotEmpty && nombre != null) {
          for (var horario in horarios) {
            schedule.add({
              'horario': horario.toString(),
              'nombre': nombre,
              'materiaId': materia.id,
              'grado': gradoStr,
            });
          }
        }
      }

      return schedule;
    } catch (e) {
      print('Error obteniendo horario del estudiante: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Obtener resumen de horarios por día
  static Map<String, List<Map<String, dynamic>>> groupSchedulesByDay(
    List<Map<String, dynamic>> schedules,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'Lunes': [],
      'Martes': [],
      'Miércoles': [],
      'Jueves': [],
      'Viernes': [],
    };

    for (var schedule in schedules) {
      final horario = schedule['horario'] as String;
      final parts = horario.split('-');
      
      if (parts.isNotEmpty) {
        final dia = parts[0];
        if (grouped.containsKey(dia)) {
          grouped[dia]!.add(schedule);
        }
      }
    }

    // Ordenar cada día por hora
    grouped.forEach((dia, horarios) {
      horarios.sort((a, b) {
        final horaA = (a['horario'] as String).split('-').last;
        final horaB = (b['horario'] as String).split('-').last;
        return horaA.compareTo(horaB);
      });
    });

    return grouped;
  }

  /// Contar clases por día
  static Map<String, int> countClassesPerDay(List<Map<String, dynamic>> schedules) {
    final Map<String, int> counts = {
      'Lunes': 0,
      'Martes': 0,
      'Miércoles': 0,
      'Jueves': 0,
      'Viernes': 0,
    };

    for (var schedule in schedules) {
      final horario = schedule['horario'] as String;
      final parts = horario.split('-');
      
      if (parts.isNotEmpty) {
        final dia = parts[0];
        if (counts.containsKey(dia)) {
          counts[dia] = counts[dia]! + 1;
        }
      }
    }

    return counts;
  }
}
