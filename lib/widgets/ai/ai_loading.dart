import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';

class AILoadingWidget extends StatefulWidget {
  const AILoadingWidget({super.key});

  @override
  State<AILoadingWidget> createState() => _AILoadingWidgetState();
}

class _AILoadingWidgetState extends State<AILoadingWidget> {
  int _stepIndex = 0;
  final List<String> _steps = [
    "Initializing Career Twin AI Engine...",
    "Extracting technical & soft skills...",
    "Computing TF-IDF semantic vector similarity...",
    "Computing weighted composite career score...",
    "Generating career recommendations & role matches...",
  ];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() {
          _stepIndex = i;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primarySoft,
          ),
          child: const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3.5,
          ),
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _steps[_stepIndex],
            key: ValueKey<int>(_stepIndex),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: theme.textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Analyzing skills & job requirements...",
          style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
        ),
        const SizedBox(height: 30),
        // Shimmer skeleton representation
        Shimmer.fromColors(
          baseColor: theme.cardColor,
          highlightColor: AppColors.primarySoft,
          child: Column(
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
