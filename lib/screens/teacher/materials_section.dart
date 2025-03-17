import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class MaterialsSection extends StatefulWidget {
  final String materiaId;

  const MaterialsSection({super.key, required this.materiaId});

  @override
  State<MaterialsSection> createState() => _MaterialsSectionState();
}

class _MaterialsSectionState extends State<MaterialsSection> {
  final _enlaceController = TextEditingController();
  final _maxFileSize = 50 * 1024 * 1024; // 50 MB
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> _uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        allowCompression: true,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        
        if (file.size > _maxFileSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El archivo excede el límite de 50MB')),
          );
          return;
        }

        File uploadFile = File(file.path!);
        String fileName = file.name;
        String extension = fileName.split('.').last.toLowerCase();

        // Subir a Firebase Storage
        Reference storageRef = _storage.ref()
          .child('materias/${widget.materiaId}/materiales/$fileName');
        
        await storageRef.putFile(uploadFile);
        String downloadURL = await storageRef.getDownloadURL();

        // Guardar metadatos en Firestore
        await _firestore
            .collection('materias')
            .doc(widget.materiaId)
            .collection('materiales')
            .add({
              'tipo': 'archivo',
              'nombre': fileName,
              'url': downloadURL,
              'formato': extension,
              'tamaño': file.size,
              'fechaSubida': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir archivo: ${e.toString()}')),
      );
    }
  }

  void _showAddLinkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Enlace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _enlaceController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://ejemplo.com',
                prefixIcon: Icon(Icons.link),
              ),
              validator: (value) {
                if (value == null || value.isEmpty || !value.startsWith('http')) {
                  return 'Ingrese un enlace válido';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_enlaceController.text.isNotEmpty) {
                await _firestore
                    .collection('materias')
                    .doc(widget.materiaId)
                    .collection('materiales')
                    .add({
                      'tipo': 'enlace',
                      'nombre': _enlaceController.text,
                      'enlace': _enlaceController.text,
                      'fechaSubida': FieldValue.serverTimestamp(),
                    });
                Navigator.pop(context);
                _enlaceController.clear();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon(String format) {
    final iconMap = {
      'pdf': Icons.picture_as_pdf,
      'doc': Icons.description,
      'docx': Icons.description,
      'ppt': Icons.slideshow,
      'pptx': Icons.slideshow,
      'xls': Icons.table_chart,
      'xlsx': Icons.table_chart,
      'zip': Icons.archive,
      'jpg': Icons.image,
      'jpeg': Icons.image,
      'png': Icons.image,
      'mp4': Icons.videocam,
    };

    return Icon(
      iconMap[format] ?? Icons.insert_drive_file,
      color: Colors.blue,
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Subir Archivo'),
                onPressed: _uploadFile,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('Agregar Enlace'),
                onPressed: _showAddLinkDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('materias')
                .doc(widget.materiaId)
                .collection('materiales')
                .orderBy('fechaSubida', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: data['tipo'] == 'archivo'
                          ? _buildFileIcon(data['formato'])
                          : const Icon(Icons.link, color: Colors.blue),
                      title: Text(data['nombre']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['tipo'] == 'archivo')
                            Text(
                              '${_formatFileSize(data['tamaño'])} - ${data['formato']?.toUpperCase()}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          Text(
                            DateFormat('dd MMM yyyy - HH:mm').format(
                              (data['fechaSubida'] as Timestamp).toDate(),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          // Eliminar de Firestore y Storage si es archivo
                          if (data['tipo'] == 'archivo') {
                            await _storage.refFromURL(data['url']).delete();
                          }
                          await doc.reference.delete();
                        },
                      ),
                      onTap: () {
                        if (data['tipo'] == 'enlace') {
                          launchUrl(Uri.parse(data['enlace']));
                        } else {
                          launchUrl(Uri.parse(data['url']));
                        }
                      },
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
}