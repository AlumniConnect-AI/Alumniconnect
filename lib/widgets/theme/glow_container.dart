import 'package:flutter/material.dart';
import '../../config/theme.dart';

class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final double blurRadius;
  final double spreadRadius;
  final BorderRadius? borderRadius;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowColor,
    this.blurRadius = 18.0,
    this.spreadRadius = 1.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final color = glowColor ?? AppColors.primaryNeon;

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: child,
    );
  }
}
