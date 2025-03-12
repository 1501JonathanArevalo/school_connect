import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:school_connect/auth_service.dart';

class UserFormDialog extends StatefulWidget {
  final bool isStudent;
  final Map<String, dynamic>? user;

  const UserFormDialog({
    super.key,
    required this.isStudent,
    this.user,
  });

  factory UserFormDialog.edit({required Map<String, dynamic> user}) {
    return UserFormDialog(
      isStudent: user['role'] == 'student',
      user: user,
    );
  }

  @override
  _UserFormDialogState createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _docNumberController = TextEditingController();
  String _selectedDocType = 'Cédula';
  DateTime? _selectedBirthDate;
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedGrade = '5';
  final _previousSchoolController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _insuranceController = TextEditingController();
  List<Map<String, dynamic>> _tutores = [];
  final _titleController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _experienceController = TextEditingController();
  final _languagesController = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _initializeForm();
    }
  }

void _initializeForm() {
  final user = Map<String, dynamic>.from(widget.user!); // Convertir a Map<String, dynamic>
  _emailController.text = user['email'] ?? '';
  _nameController.text = user['nombre'] ?? '';
  _selectedDocType = user['tipoDocumento'] ?? 'Cédula';
  _docNumberController.text = user['numeroDocumento'] ?? '';
  _addressController.text = user['direccion'] ?? '';
  _phoneController.text = user['telefono'] ?? '';
  
  if (widget.isStudent) {
    _selectedGrade = user['studentInfo']['grado'] ?? '5';
    _previousSchoolController.text = user['studentInfo']['colegio_anterior'] ?? '';
    _allergiesController.text = user['studentInfo']['medico']['alergias'] ?? '';
    _insuranceController.text = user['studentInfo']['medico']['seguro'] ?? '';
    _tutores = List<Map<String, dynamic>>.from(user['studentInfo']['tutores'] ?? []);
  } else {
    _titleController.text = user['teacherInfo']['titulo'] ?? '';
    _specialtyController.text = user['teacherInfo']['especialidad'] ?? '';
    _experienceController.text = user['teacherInfo']['experiencia'] ?? '';
    _languagesController.text = (user['teacherInfo']['idiomas'] ?? []).join(',');
  }
}

  Widget _buildTutorForm(int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Text('Tutor ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(() => _tutores.removeAt(index)),
                ),
              ],
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nombre completo'),
              onChanged: (v) => _tutores[index]['nombre'] = v,
              initialValue: _tutores[index]['nombre'],
            ),
            DropdownButtonFormField<String>(
              value: _tutores[index]['parentesco'],
              items: ['Padre', 'Madre', 'Tutor', 'Otro']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _tutores[index]['parentesco'] = v!),
              decoration: const InputDecoration(labelText: 'Parentesco'),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Documento'),
              onChanged: (v) => _tutores[index]['documento'] = v,
              initialValue: _tutores[index]['documento'],
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Ocupación'),
              onChanged: (v) => _tutores[index]['ocupacion'] = v,
              initialValue: _tutores[index]['ocupacion'],
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
              onChanged: (v) => _tutores[index]['telefono'] = v,
              initialValue: _tutores[index]['telefono'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) return 'Este campo es obligatorio';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null 
          ? 'Registrar ${widget.isStudent ? 'Estudiante' : 'Profesor'}'
          : 'Editar Usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información Básica'),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: _requiredValidator,
                keyboardType: TextInputType.emailAddress,
                enabled: widget.user == null,
              ),
              if (widget.user == null)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: _requiredValidator,
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombres completos'),
                validator: _requiredValidator,
              ),
              DropdownButtonFormField<String>(
                value: _selectedDocType,
                items: ['Cédula', 'Tarjeta de Identidad', 'Pasaporte']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDocType = v!),
                decoration: const InputDecoration(labelText: 'Tipo de documento'),
              ),
              TextFormField(
                controller: _docNumberController,
                decoration: const InputDecoration(labelText: 'Número de documento'),
                validator: _requiredValidator,
                keyboardType: TextInputType.number,
              ),
              ListTile(
                title: Text(_selectedBirthDate == null 
                    ? 'Seleccionar fecha de nacimiento' 
                    : 'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedBirthDate ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedBirthDate = date);
                  }
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Dirección de residencia'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono/Celular'),
                keyboardType: TextInputType.phone,
              ),

              if (widget.isStudent) ...[
                _buildSectionTitle('Información Académica'),
                DropdownButtonFormField<String>(
                  value: _selectedGrade,
                  items: List.generate(12, (i) => (i + 1).toString())
                      .map((g) => DropdownMenuItem(value: g, child: Text('Grado $g')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGrade = v!),
                  decoration: const InputDecoration(labelText: 'Grado'),
                ),
                TextFormField(
                  controller: _previousSchoolController,
                  decoration: const InputDecoration(labelText: 'Colegio anterior'),
                ),

                _buildSectionTitle('Tutores/Representantes'),
                Column(
                  children: [
                    ..._tutores.asMap().entries.map((entry) => _buildTutorForm(entry.key)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar otro tutor'),
                      onPressed: () => setState(() {
                        _tutores.add({
                          'nombre': '',
                          'documento': '',
                          'parentesco': 'Padre',
                          'ocupacion': '',
                          'telefono': ''
                        });
                      }),
                    ),
                  ],
                ),

                _buildSectionTitle('Información Médica'),
                TextFormField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(labelText: 'Alergias/condiciones médicas'),
                ),
                TextFormField(
                  controller: _insuranceController,
                  decoration: const InputDecoration(labelText: 'Seguro médico'),
                ),
              ]
              else ...[
                _buildSectionTitle('Información Profesional'),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Título académico'),
                  validator: _requiredValidator,
                ),
                TextFormField(
                  controller: _specialtyController,
                  decoration: const InputDecoration(labelText: 'Especialidad'),
                  validator: _requiredValidator,
                ),
                TextFormField(
                  controller: _experienceController,
                  decoration: const InputDecoration(labelText: 'Años de experiencia'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _languagesController,
                  decoration: const InputDecoration(labelText: 'Idiomas (separados por coma)'),
                ),
              ],

              _buildSectionTitle('Autorizaciones'),
              CheckboxListTile(
                title: const Text('Acepto los términos y condiciones'),
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v!),
                controlAffinity: ListTileControlAffinity.leading,
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              if (widget.isStudent && _tutores.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debe agregar al menos un tutor')));
                return;
              }
              
              if (!_acceptedTerms) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debe aceptar los términos y condiciones')));
                return;
              }

              final userData = {
                'nombre': _nameController.text,
                'tipoDocumento': _selectedDocType,
                'numeroDocumento': _docNumberController.text,
                'fechaNacimiento': Timestamp.fromDate(_selectedBirthDate ?? DateTime.now()),
                'direccion': _addressController.text,
                'telefono': _phoneController.text,
                'role': widget.isStudent ? 'student' : 'teacher',
                '${widget.isStudent ? 'student' : 'teacher'}Info': widget.isStudent 
                    ? {
                        'grado': _selectedGrade,
                        'colegio_anterior': _previousSchoolController.text,
                        'tutores': _tutores,
                        'medico': {
                          'alergias': _allergiesController.text,
                          'seguro': _insuranceController.text
                        }
                      }
                    : {
                        'titulo': _titleController.text,
                        'especialidad': _specialtyController.text,
                        'experiencia': _experienceController.text,
                        'idiomas': _languagesController.text.split(','),
                        'materias': []
                      }
              };

              try {
                if (widget.user == null) {
                  await AuthService().createUserWithRole(
                    email: _emailController.text,
                    password: _passwordController.text,
                    role: widget.isStudent ? 'student' : 'teacher',
                    userData: userData,
                    context: context,
                  );
                } else {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.user!['uid'])
                      .update(userData);
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')));
              }
            }
          },
          child: const Text('Guardar'),
        )
      ],
    );
  }
}