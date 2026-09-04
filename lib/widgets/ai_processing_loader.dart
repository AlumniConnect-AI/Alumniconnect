import 'package:flutter/material.dart';
import '../config/theme.dart';

class AIProcessingLoader extends StatelessWidget {
  final int elapsedSeconds;
  final String loadingMessage;
  final Color primaryColor;

  const AIProcessingLoader({
    super.key,
    required this.elapsedSeconds,
    required this.loadingMessage,
    this.primaryColor = AppColors.primaryNeon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
              backgroundColor: primaryColor.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 16),
          // Elapsed seconds badge
          if (elapsedSeconds > 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${elapsedSeconds}s elapsed',
                style: TextStyle(
                  fontSize: 11,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Dynamic status message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              loadingMessage,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          if (elapsedSeconds > 15)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'The AI is hosted on Render free tier and may take '
                'up to 60s to wake up after inactivity. '
                'If it exceeds 60s, the offline engine kicks in automatically.',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
