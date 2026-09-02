import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';

class AIResultWidget extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onRetry;

  const AIResultWidget({
    super.key,
    required this.result,
    required this.onRetry,
  });

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final careerScoreData = result['career_score'] as Map<String, dynamic>? ?? {};
    final skillProfileData = result['skill_profile'] as Map<String, dynamic>? ?? {};

    final score = (careerScoreData['career_score'] as num?)?.toDouble() ?? 0.0;
    final tier = (careerScoreData['tier'] as String?) ?? 'N/A';
    final skillScore = (careerScoreData['skill_score'] as num?)?.toDouble() ?? 0.0;
    final semanticScore = (careerScoreData['semantic_score'] as num?)?.toDouble() ?? 0.0;
    final expScore = (careerScoreData['experience_score'] as num?)?.toDouble() ?? 0.0;
    final eduScore = (careerScoreData['education_score'] as num?)?.toDouble() ?? 0.0;

    final matchedSkills = List<String>.from(skillProfileData['matched_skills'] as List? ?? []);
    final missingSkills = List<String>.from(skillProfileData['missing_skills'] as List? ?? []);
    final skillStrengths = List<String>.from(skillProfileData['skill_strengths'] as List? ?? []);
    final suggestedRoles = (skillProfileData['suggested_roles'] as List? ?? []);
    final recommendations = List<String>.from(skillProfileData['recommendations'] as List? ?? []);
    final learningResources = (skillProfileData['learning_resources'] as List? ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 🏆 HERO SCORE CARD ─────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                "COMPOSITE CAREER SCORE",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    " / 100",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tier,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── 📊 COMPONENT BREAKDOWN METRICS ──────────────────────────────────
        _sectionTitle(context, "Scoring Breakdown"),
        const SizedBox(height: 10),
        Row(
          children: [
            _metricBox(context, "Skill Match", "${skillScore.toStringAsFixed(0)}%", Icons.checklist),
            const SizedBox(width: 8),
            _metricBox(context, "Semantic Sim", "${semanticScore.toStringAsFixed(0)}%", Icons.compare_arrows),
            const SizedBox(width: 8),
            _metricBox(context, "Experience", "${expScore.toStringAsFixed(0)}%", Icons.work_history),
            const SizedBox(width: 8),
            _metricBox(context, "Education", "${eduScore.toStringAsFixed(0)}%", Icons.school),
          ],
        ),

        const SizedBox(height: 24),

        // ── 🎯 SKILLS OVERLAP ANALYSIS ──────────────────────────────────────
        _sectionTitle(context, "Skill Analysis"),
        const SizedBox(height: 10),

        if (matchedSkills.isNotEmpty) ...[
          Text("Matched Skills", style: _subLabelStyle(theme)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: matchedSkills
                .map((s) => _skillChip(s, Colors.green.shade900, Colors.green.shade200, Icons.check_circle_outline))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],

        if (missingSkills.isNotEmpty) ...[
          Text("Missing Requirements", style: _subLabelStyle(theme)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: missingSkills
                .map((s) => _skillChip(s, Colors.red.shade900, Colors.red.shade200, Icons.error_outline))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],

        if (skillStrengths.isNotEmpty) ...[
          Text("Extra Candidate Strengths", style: _subLabelStyle(theme)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skillStrengths
                .map((s) => _skillChip(s, Colors.purple.shade900, Colors.purple.shade200, Icons.auto_awesome))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],

        const SizedBox(height: 16),

        // ── 🚀 SUGGESTED ROLES ──────────────────────────────────────────────
        if (suggestedRoles.isNotEmpty) ...[
          _sectionTitle(context, "Suggested Career Roles"),
          const SizedBox(height: 10),
          ...suggestedRoles.map((r) {
            final roleMap = r as Map<String, dynamic>;
            final roleTitle = roleMap['role'] as String? ?? '';
            final matchPct = (roleMap['match_percent'] as num?)?.toDouble() ?? 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      roleTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${matchPct.toStringAsFixed(0)}% Match",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // ── 💡 ACTIONABLE RECOMMENDATIONS ──────────────────────────────────
        if (recommendations.isNotEmpty) ...[
          _sectionTitle(context, "AI Recommendations"),
          const SizedBox(height: 10),
          ...recommendations.map(
            (rec) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                rec,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── 📚 LEARNING RESOURCES ──────────────────────────────────────────
        if (learningResources.isNotEmpty) ...[
          _sectionTitle(context, "Learning Resources for Gaps"),
          const SizedBox(height: 10),
          ...learningResources.map((res) {
            final resMap = res as Map<String, dynamic>;
            final skill = resMap['skill'] as String? ?? '';
            final url = resMap['resource'] as String? ?? '';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.school_outlined, color: AppColors.primary),
              title: Text("Learn $skill", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _openUrl(url),
            );
          }),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 24),

        // ── 🔄 RETRY / NEW ANALYSIS BUTTON ─────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            label: const Text(
              "Start New Analysis",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  TextStyle _subLabelStyle(ThemeData theme) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: theme.textTheme.bodyMedium?.color,
    );
  }

  Widget _metricBox(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _skillChip(String text, Color bg, Color textCol, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 14, color: textCol),
      label: Text(
        text,
        style: TextStyle(color: textCol, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      backgroundColor: bg,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
