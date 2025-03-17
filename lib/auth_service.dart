import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html; // Para usar window.location.reload()
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si es una aplicación web
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

  return _firestore.collection('users')
      .where('createdBy', isEqualTo: userId)
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
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final userDataMap = Map<String, dynamic>.from(userData);
    
    userDataMap.addAll({
      'uid': userCredential.user!.uid,
      'email': email,
      'role': role,
      'createdBy': _auth.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (role == 'student' && userDataMap['studentInfo'] != null) {
      final grado = userDataMap['studentInfo']['grado'];
      userDataMap['grade'] = grado;
      await _agregarEstudianteAMaterias(userCredential.user!.uid, grado);
    }

    // Paso 1: Escribir en Firestore
    await _firestore.collection('users')
       .doc(userCredential.user!.uid)
       .set(userDataMap);

    // Paso 2: Esperar confirmación del servidor
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .get(GetOptions(source: Source.server)); // Forzar lectura desde servidor

    // Paso 3: Redireccionar
    if (kIsWeb) {
      html.window.location.reload();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }

  } on FirebaseAuthException catch (e) {
    throw FirebaseAuthException(code: e.code, message: e.message);
  } catch (e) {
    throw Exception('Error al crear usuario: ${e.toString()}');
  }
}

Future<void> _agregarEstudianteAMaterias(String estudianteId, String grado) async {
  try {
    final materiasSnapshot = await _firestore
        .collection('materias')
        .where('grado', isEqualTo: grado)
        .get();

    final batch = _firestore.batch();
    
    for (final materia in materiasSnapshot.docs) {
      final materiaRef = _firestore.collection('materias').doc(materia.id);
      batch.update(materiaRef, {
        'estudiantes': FieldValue.arrayUnion([estudianteId])
      });
    }
    
    await batch.commit();
  } catch (e) {
    print('Error agregando estudiante a materias: $e');
    throw Exception('Error al asignar estudiante a las materias');
  }
}

Future<void> actualizarGradoEstudiante(String estudianteId, String nuevoGrado) async {
  try {
    final estudianteDoc = await _firestore.collection('users').doc(estudianteId).get();
    final gradoAnterior = estudianteDoc['grade'];

    // Remover de materias antiguas
    if (gradoAnterior != null) {
      await _removerEstudianteDeMaterias(estudianteId, gradoAnterior);
    }

    // Agregar a nuevas materias
    await _agregarEstudianteAMaterias(estudianteId, nuevoGrado);

    // Actualizar el grado en el usuario
    await _firestore.collection('users').doc(estudianteId).update({
      'grade': nuevoGrado,
    });
    
  } catch (e) {
    print('Error actualizando grado: $e');
    throw Exception('Error al actualizar el grado del estudiante');
  }
}
Future<void> _removerEstudianteDeMaterias(String estudianteId, String grado) async {
  // Obtener todas las materias del grado anterior
  final materias = await _firestore
      .collection('materias')
      .where('grado', isEqualTo: grado)
      .get();

  // Remover el estudiante de cada materia
  for (final materia in materias.docs) {
    await _firestore
        .collection('materias')
        .doc(materia.id)
        .update({
          'estudiantes': FieldValue.arrayRemove([estudianteId]),
        });
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
      await _firestore.collection('materias').add({
        'nombre': nombre,
        'grado': grado,
        'profesorId': profesorId,
        'estudiantes': estudiantes,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
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
    await _firestore.collection('materias').doc(materiaId).delete();
  }

  // Método para actualizar una materia
  Future<void> updateMateria(
    String materiaId,
    String nombre,
    String grado,
    String profesorId,
    List<String> estudiantes,
  ) async {
    await _firestore.collection('materias').doc(materiaId).update({
      'nombre': nombre,
      'grado': grado,
      'profesorId': profesorId,
      'estudiantes': estudiantes,
    });
  }

  // Método para obtener los estudiantes de un grado específico
  Future<QuerySnapshot> getEstudiantesByGrado(String grado) async {
    return await _firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('grade', isEqualTo: grado)
        .get();
  }
}