import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Estilos
const boldStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

// Formateo de fechas
String formatDate(Timestamp timestamp) {
  return DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000)
      .toString()
      .substring(0, 16);
}

// Íconos de archivo
Icon getFileIcon(String extension) {
  const icons = {
    'pdf': Icons.picture_as_pdf,
    'doc': Icons.description,
    'docx': Icons.description,
    'ppt': Icons.slideshow,
    'pptx': Icons.slideshow,
    'xls': Icons.table_chart,
    'xlsx': Icons.table_chart,
    'zip': Icons.archive,
    'jpg': Icons.image,
    'png': Icons.image,
  };
  return Icon(icons[extension] ?? Icons.insert_drive_file);
}