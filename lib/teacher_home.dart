import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:school_connect/auth_service.dart';
import 'package:school_connect/login_screen.dart';
import 'dart:html' as html;
import 'screens/teacher/grades_screen.dart';

class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final AuthService authService = AuthService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Color(0xFF7B5FCE), // Mismo púrpura institucional
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 80,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Panel Profesor',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'School Connect',
                    style: TextStyle(
                      fontSize: 13,
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
            preferredSize: const Size.fromHeight(56),
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
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
                tabs: [
                  Tab(
                    icon: Icon(Icons.class_, size: 24),
                    height: 56,
                    text: 'Mis Clases',
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
              margin: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout, color: Colors.white, size: 22),
                ),
                tooltip: 'Cerrar sesión',
                onPressed: () => _cerrarSesion(context, authService),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            GradesScreen(teacherId: userId),
            _TeacherEventsTab(teacherId: userId),
          ],
        ),
      ),
    );
  }

  void _cerrarSesion(BuildContext context, AuthService authService) async {
    try {
      await authService.signOut();
      if (kIsWeb) {
        html.window.location.reload();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }
}

class _TeacherEventsTab extends StatelessWidget {
  final String teacherId;

  const _TeacherEventsTab({required this.teacherId});

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
                  stream: FirebaseFirestore.instance.collection('eventos').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(height: 100);
                    }

                    final eventos = snapshot.data!.docs;
                    final misEventos = eventos.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['creadoPor'] == teacherId;
                    }).length;

                    final now = DateTime.now();
                    final proximosEventos = eventos.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final fecha = (data['fecha'] as Timestamp).toDate();
                      return fecha.isAfter(now) && 
                             (data['creadoPor'] == teacherId || !data.containsKey('creadoPor'));
                    }).length;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildEventStatCard(
                            'Mis Eventos',
                            misEventos.toString(),
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
                            'Total',
                            eventos.length.toString(),
                            Icons.calendar_today,
                            Colors.blueAccent,
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
                    final esCreador = data['creadoPor'] == teacherId;

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
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                data['titulo'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  decoration: esPasado ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            if (!esCreador)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
                              if (data['descripcion']?.isNotEmpty ?? false)
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
                                  if (data['hora']?.isNotEmpty ?? false)
                                    _buildInfoChip(
                                      Icons.access_time,
                                      data['hora'],
                                      Colors.orange,
                                    ),
                                  if (data['lugar']?.isNotEmpty ?? false)
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
                        trailing: esCreador ? Row(
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
                                onPressed: () => _deleteEvent(context, evento),
                              ),
                            ),
                          ],
                        ) : null,
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
            textAlign: TextAlign.center,
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
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.event,
                            color: Colors.purple.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            evento == null ? 'Crear Evento' : 'Editar Evento',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Formulario
                    TextFormField(
                      controller: tituloController,
                      decoration: InputDecoration(
                        labelText: 'Título del evento',
                        hintText: 'Ej: Reunión de padres',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Ingrese un título' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descripcionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('es', 'ES'),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha del evento',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('EEEE, d \'de\' MMMM yyyy').format(selectedDate),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.edit, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: horaController,
                      decoration: InputDecoration(
                        labelText: 'Hora (opcional)',
                        hintText: 'Ej: 10:00 AM',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: lugarController,
                      decoration: InputDecoration(
                        labelText: 'Lugar (opcional)',
                        hintText: 'Ej: Auditorio',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people, color: Colors.grey.shade700),
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
                          const SizedBox(height: 12),
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
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Selecciona al menos un grado',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

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
                              if (formKey.currentState!.validate() && selectedGrados.isNotEmpty) {
                                final data = {
                                  'titulo': tituloController.text.trim(),
                                  'descripcion': descripcionController.text.trim(),
                                  'fecha': Timestamp.fromDate(selectedDate),
                                  'hora': horaController.text.trim(),
                                  'lugar': lugarController.text.trim(),
                                  'grados': selectedGrados,
                                  'creadoPor': teacherId,
                                  'creadoEn': FieldValue.serverTimestamp(),
                                };

                                try {
                                  if (evento == null) {
                                    await FirebaseFirestore.instance
                                        .collection('eventos')
                                        .add(data);
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text('Evento creado exitosamente'),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  } else {
                                    await evento.reference.update(data);
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text('Evento actualizado'),
                                          ],
                                        ),
                                        backgroundColor: Colors.blue,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }

                                  Navigator.pop(context);
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
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7B5FCE),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(evento == null ? 'Crear' : 'Guardar'),
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

  Future<void> _deleteEvent(BuildContext context, DocumentSnapshot evento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      try {
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