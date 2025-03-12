import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentDetailsScreen extends StatelessWidget {
  final String studentId;

  const StudentDetailsScreen({super.key, required this.studentId});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No disponible';
    return DateFormat('dd/MM/yyyy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Estudiante'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Estudiante no encontrado'));
          }

          final studentData = snapshot.data!.data() as Map<String, dynamic>;
          final studentInfo = studentData['studentInfo'] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Información Personal'),
                _buildDetailRow('Nombre completo', studentData['nombre'] ?? 'No disponible'),
                _buildDetailRow('Tipo de documento', studentData['tipoDocumento'] ?? 'No disponible'),
                _buildDetailRow('Número de documento', studentData['numeroDocumento'] ?? 'No disponible'),
                _buildDetailRow('Fecha de nacimiento', _formatDate(studentData['fechaNacimiento'])),
                _buildDetailRow('Dirección', studentData['direccion'] ?? 'No disponible'),
                _buildDetailRow('Teléfono/Celular', studentData['telefono'] ?? 'No disponible'),

                _buildSectionTitle('Información Académica'),
                _buildDetailRow('Grado', studentInfo['grado']?.toString() ?? 'No disponible'),
                _buildDetailRow('Colegio anterior', studentInfo['colegio_anterior'] ?? 'No disponible'),

                _buildSectionTitle('Información Médica'),
                _buildDetailRow('Alergias/Condiciones', studentInfo['medico']?['alergias'] ?? 'No registra'),
                _buildDetailRow('Seguro médico', studentInfo['medico']?['seguro'] ?? 'No registra'),

                _buildSectionTitle('Tutores/Representantes'),
                ..._buildTutoresList(studentInfo['tutores']),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(),
        ],
      ),
    );
  }

  List<Widget> _buildTutoresList(List<dynamic>? tutores) {
    if (tutores == null || tutores.isEmpty) {
      return [
        const Text('No hay tutores registrados', style: TextStyle(color: Colors.grey))
      ];
    }

    return tutores.map<Widget>((tutor) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTutorDetail('Nombre', tutor['nombre']),
              _buildTutorDetail('Parentesco', tutor['parentesco']),
              _buildTutorDetail('Documento', tutor['documento']),
              _buildTutorDetail('Ocupación', tutor['ocupacion']),
              _buildTutorDetail('Teléfono', tutor['telefono']),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTutorDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}