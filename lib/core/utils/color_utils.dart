import 'package:flutter/material.dart';

class ColorUtils {
  static MaterialColor getMateriaColor(String materiaNombre) {
    final hash = materiaNombre.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
      Colors.lime,
      Colors.deepPurple,
    ];
    return colors[hash.abs() % colors.length];
  }
}
