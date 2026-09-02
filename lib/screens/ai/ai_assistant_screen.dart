import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/ai_provider.dart';
import '../../widgets/ai/ai_input.dart';
import '../../widgets/ai/ai_loading.dart';
import '../../widgets/ai/ai_result.dart';

class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiProvider = Provider.of<AIProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              "AI Career Twin",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reset",
            onPressed: () => aiProvider.reset(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 🔮 AI BANNER / HEADER ───────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      theme.cardColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Icon(
                        Icons.psychology,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Career Twin AI Engine",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Analyze your profile & skills against job postings using NLP & TF-IDF similarity algorithms.",
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 🔴 ERROR STATE DISPLAY ─────────────────────────────────────
              if (aiProvider.error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          aiProvider.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        onPressed: () => aiProvider.reset(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── ⏳ LOADING STATE ───────────────────────────────────────────
              if (aiProvider.isLoading)
                const AILoadingWidget()

              // ── 🏆 RESULT STATE ────────────────────────────────────────────
              else if (aiProvider.result != null)
                AIResultWidget(
                  result: aiProvider.result!,
                  onRetry: () => aiProvider.reset(),
                )

              // ── 📝 INPUT STATE ─────────────────────────────────────────────
              else
                AIInputWidget(
                  isLoading: aiProvider.isLoading,
                  onAnalyze: (profile, jd, exp) {
                    aiProvider.analyze(
                      profileText: profile,
                      jdText: jd,
                      requiredExpYears: exp,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
