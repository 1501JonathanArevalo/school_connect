import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentUtilities {
  // Estilos
  static const boldStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

  // Formateo de fechas
  static String formatTimestamp(Timestamp timestamp) {
    return DateFormat('d/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  // Íconos de archivo
  static Icon getFileIcon(String extension) {
    const iconMap = {
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
    return Icon(iconMap[extension.toLowerCase()] ?? Icons.insert_drive_file);
  }

  // Formato de tamaño de archivo
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}