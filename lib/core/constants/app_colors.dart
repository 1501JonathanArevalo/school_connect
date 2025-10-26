import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF7B5FCE);
  static const primaryLight = Color(0xFF9575CD);
  static const primaryLighter = Color(0xFFB39DDB);
  
  static const success = Colors.green;
  static const error = Colors.red;
  static const warning = Colors.orange;
  static const info = Colors.blue;
  
  // Gradients
  static final primaryGradient = LinearGradient(
    colors: [primary, primaryLight, primaryLighter],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static final headerGradient = LinearGradient(
    colors: [primary, primaryLight],
  );
}
