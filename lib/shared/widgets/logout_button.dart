import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LogoutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: const Icon(Icons.logout, color: Colors.white, size: 22),
        ),
        tooltip: 'Cerrar sesión',
        onPressed: onPressed,
      ),
    );
  }
}
