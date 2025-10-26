import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GradientHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const GradientHeader({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.headerGradient),
      child: child,
    );
  }
}
