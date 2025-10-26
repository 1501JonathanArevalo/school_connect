import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';

class ActionButtonGroup extends StatelessWidget {
  final List<ActionButtonData> buttons;

  const ActionButtonGroup({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: buttons.map((button) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: button != buttons.last ? 12 : 0,
              ),
              child: ElevatedButton.icon(
                icon: Icon(button.icon, size: 20),
                label: Text(button.label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: button.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  elevation: 0,
                ),
                onPressed: button.onPressed,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ActionButtonData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  ActionButtonData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
}
