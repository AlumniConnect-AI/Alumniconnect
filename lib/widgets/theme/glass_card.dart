import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Reusable Glassmorphism Card with blur effect, gradient background,
/// glowing borders, and rounded corners.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double blurAmount;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 22.0,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
    this.blurAmount = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isDark
        ? AppColors.cardDark.withValues(alpha: 0.65)
        : AppColors.card.withValues(alpha: 0.85);

    final defaultBorder = borderColor ??
        (isDark
            ? AppColors.borderDark.withValues(alpha: 0.5)
            : AppColors.border.withValues(alpha: 0.6));

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? defaultBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: defaultBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: (borderColor ?? AppColors.primaryNeon).withValues(alpha: 0.08),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            splashColor: AppColors.primaryNeon.withValues(alpha: 0.15),
            highlightColor: AppColors.accentPurple.withValues(alpha: 0.1),
            child: content,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      child: content,
    );
  }
}
