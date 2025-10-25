import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_connect/auth_service.dart';
import 'package:school_connect/login_screen.dart';
import 'subjects_screen.dart';
import 'dart:html' as html;

class GradesScreen extends StatelessWidget {
  final String teacherId;

  const GradesScreen({super.key, required this.teacherId});

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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('materias')
                  .where('profesorId', isEqualTo: teacherId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(height: 100);
                }

                final materias = snapshot.data!.docs;
                final totalMaterias = materias.length;

                // Contar grados únicos
                final gradosUnicos = materias
                    .map((m) => (m.data() as Map)['grado'])
                    .toSet()
                    .length;

                // Contar total de estudiantes
                int totalEstudiantes = 0;
                for (var materia in materias) {
                  final data = materia.data() as Map<String, dynamic>;
                  totalEstudiantes += (data['estudiantes'] as List?)?.length ?? 0;
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Mis Materias',
                        totalMaterias.toString(),
                        Icons.book,
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Grados',
                        gradosUnicos.toString(),
                        Icons.school,
                        Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Estudiantes',
                        totalEstudiantes.toString(),
                        Icons.people,
                        Colors.blueAccent,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Lista de grados
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('materias')
                  .where('profesorId', isEqualTo: teacherId)
                  .snapshots(),
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
                          'No tienes materias asignadas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contacta al administrador',
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectsScreen(
                materiaId: materia.id,
                materiaNombre: nombre,
                grade: data['grado'].toString(),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono de materia
                Container(
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
                const SizedBox(width: 16),
                // Información de la materia
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                // Icono de navegación
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _cerrarSesion(BuildContext context, AuthService authService) async {
  try {
    await authService.signOut();
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