import 'package:flutter/material.dart';
import '../../config/theme.dart';

class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient? gradient;

  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final activeGradient = gradient ?? AppGradients.neonCyanPurple;

    return ShaderMask(
      shaderCallback: (bounds) => activeGradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
      ),
    );
  }
}
