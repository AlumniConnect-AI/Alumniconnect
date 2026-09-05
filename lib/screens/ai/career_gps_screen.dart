import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/career_gps_provider.dart';
import '../../widgets/theme/glass_card.dart';
import '../../widgets/theme/neon_button.dart';
import '../../widgets/theme/ai_section_header.dart';
import '../../widgets/theme/gradient_icon.dart';

class CareerGpsScreen extends StatefulWidget {
  const CareerGpsScreen({super.key});

  @override
  State<CareerGpsScreen> createState() => _CareerGpsScreenState();
}

class _CareerGpsScreenState extends State<CareerGpsScreen> {
  final _skillsController = TextEditingController(text: "Flutter, Dart, Firebase, Git");
  String _selectedRole = "Mobile App Developer (Flutter)";
  String _selectedEducation = "Bachelors";
  double _experienceYears = 1.5;

  final List<String> _roles = [
    "Mobile App Developer (Flutter)",
    "AI / ML Engineer",
    "Data Scientist",
    "Full-Stack Web Developer",
    "Backend Developer",
    "DevOps Engineer",
    "Cloud Architect",
  ];

  final List<String> _educationLevels = [
    "Bachelors",
    "Masters",
    "PhD",
    "Diploma",
  ];

  @override
  void dispose() {
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gpsProvider = Provider.of<CareerGPSProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            GradientIcon(icon: Icons.map, size: 22),
            SizedBox(width: 8),
            Text(
              "Career GPS Engine",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => gpsProvider.reset(),
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
              // ──  HERO BANNER ─────────────────────────────────────────────
              GlassCard(
                padding: const EdgeInsets.all(20),
                borderColor: AppColors.accentPurple.withValues(alpha: 0.5),
                backgroundColor: AppColors.cardDark.withValues(alpha: 0.8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppGradients.purplePink,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.explore, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "AI ROADMAP ENGINE",
                            style: TextStyle(
                              color: AppColors.accentPurple,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Personalized Career GPS",
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Predict career roadmaps, readiness scores & 3-phase skill gap milestones.",
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Error banner
              if (gpsProvider.error != null) ...[
                GlassCard(
                  borderColor: Colors.red,
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(gpsProvider.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ──  RESULT DISPLAY OR INPUT FORM ─────────────────────────────
              if (gpsProvider.isLoading)
                _buildLoadingState(theme)
              else if (gpsProvider.roadmap != null)
                _buildRoadmapResults(context, gpsProvider.roadmap!, () => gpsProvider.reset())
              else
                _buildInputForm(context, theme, gpsProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputForm(BuildContext context, ThemeData theme, CareerGPSProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target Role Dropdown
        Text("Target Career Role *", style: _labelStyle(theme)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              dropdownColor: theme.cardColor,
              items: _roles.map((r) {
                return DropdownMenuItem<String>(
                  value: r,
                  child: Text(r, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRole = val);
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Current Skills Field
        Text("Your Current Skills *", style: _labelStyle(theme)),
        const SizedBox(height: 6),
        TextField(
          controller: _skillsController,
          maxLines: 3,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
          decoration: InputDecoration(
            hintText: "Enter skills separated by commas (e.g. Python, SQL, Git, React)...",
            filled: true,
            fillColor: theme.cardColor,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Education & Experience
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Education Level", style: _labelStyle(theme)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedEducation,
                        isExpanded: true,
                        dropdownColor: theme.cardColor,
                        items: _educationLevels.map((e) {
                          return DropdownMenuItem<String>(
                            value: e,
                            child: Text(e, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedEducation = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Experience: ${_experienceYears.toStringAsFixed(1)} Yrs", style: _labelStyle(theme)),
                  Slider(
                    value: _experienceYears,
                    min: 0.0,
                    max: 10.0,
                    divisions: 20,
                    activeColor: AppColors.accentPurple,
                    onChanged: (val) => setState(() => _experienceYears = val),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        NeonButton(
          text: "Generate Career GPS Roadmap",
          icon: Icons.map_outlined,
          gradient: AppGradients.purplePink,
          isLoading: provider.isLoading,
          onPressed: () {
            provider.generateRoadmap(
              targetRole: _selectedRole,
              currentSkills: _skillsController.text.trim(),
              education: _selectedEducation,
              experienceYears: _experienceYears,
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const CircularProgressIndicator(color: AppColors.accentPurple, strokeWidth: 3.5),
        const SizedBox(height: 20),
        Text("Synthesizing Career GPS Roadmap...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
        const SizedBox(height: 6),
        Text("Analyzing skill dependency matrix & milestone phases", style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRoadmapResults(BuildContext context, Map<String, dynamic> data, VoidCallback onReset) {
    final theme = Theme.of(context);

    final role = data['target_role'] as String? ?? '';
    final score = (data['readiness_score'] as num?)?.toDouble() ?? 0.0;
    final tier = data['tier'] as String? ?? '';
    final skillGap = data['skill_gap'] as Map<String, dynamic>? ?? {};
    final acquired = List<String>.from(skillGap['acquired'] as List? ?? []);
    final missing = List<String>.from(skillGap['missing'] as List? ?? []);
    final phases = (data['phases'] as List? ?? []);
    final projects = (data['projects'] as List? ?? []);
    final nextAction = data['next_best_action'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ──  READINESS SCORE GAUGE ───────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AppGradients.purplePink,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurple.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text("TARGET ROLE: ${role.toUpperCase()}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text("${score.toStringAsFixed(0)}%", style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                child: Text(tier, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Next Best Action Banner
        if (nextAction.isNotEmpty) ...[
          GlassCard(
            borderColor: AppColors.primaryNeon,
            backgroundColor: AppColors.primarySoft,
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.primaryNeon),
                const SizedBox(width: 10),
                Expanded(child: Text(nextAction, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.bodyLarge?.color))),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ──  SKILL GAP ANALYSIS ──────────────────────────────────────────
        const AISectionHeader(title: "Skill Gap Analysis"),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Acquired Skills", style: _subStyle(theme)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: acquired.map((s) => _chip(s, Colors.green.shade900, Colors.green.shade200)).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Target Gap Skills", style: _subStyle(theme)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: missing.map((s) => _chip(s, Colors.red.shade900, Colors.red.shade200)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ──  3-PHASE TIMELINE ROADMAP ─────────────────────────────────────
        const AISectionHeader(title: "Sequenced Learning Roadmap"),
        const SizedBox(height: 12),

        ...phases.map((p) {
          final pMap = p as Map<String, dynamic>;
          final phaseTitle = pMap['phase'] as String? ?? '';
          final duration = pMap['duration'] as String? ?? '';
          final status = pMap['status'] as String? ?? '';
          final milestone = pMap['milestone'] as String? ?? '';
          final targetSkills = List<String>.from(pMap['target_skills'] as List? ?? []);

          return GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.accentPurple.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(duration, style: const TextStyle(color: AppColors.primaryNeon, fontSize: 12, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(10)),
                      child: Text(status, style: const TextStyle(color: AppColors.accentPurple, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(phaseTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(milestone, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: targetSkills.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    backgroundColor: theme.cardColor,
                  )).toList(),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 24),

        // ──  RECOMMENDED HANDS-ON PROJECTS ──────────────────────────────
        if (projects.isNotEmpty) ...[
          const AISectionHeader(title: "Target Project Portfolio"),
          const SizedBox(height: 12),
          ...projects.map((proj) {
            final projMap = proj as Map<String, dynamic>;
            final pTitle = projMap['title'] as String? ?? '';
            final pTech = projMap['tech'] as String? ?? '';
            final pDesc = projMap['description'] as String? ?? '';

            return GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.code, color: AppColors.primaryNeon, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(pTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(pDesc, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                  const SizedBox(height: 6),
                  Text("Stack: $pTech", style: const TextStyle(color: AppColors.accentPurple, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
        ],

        NeonButton(
          text: "Start New Roadmap Query",
          icon: Icons.refresh,
          gradient: AppGradients.neonCyanPurple,
          onPressed: onReset,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  TextStyle _labelStyle(ThemeData theme) => TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.textTheme.bodyMedium?.color);
  TextStyle _subStyle(ThemeData theme) => TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.bodyLarge?.color);

  Widget _chip(String text, Color bg, Color txt) => Chip(
    label: Text(text, style: TextStyle(color: txt, fontSize: 11, fontWeight: FontWeight.bold)),
    backgroundColor: bg,
    padding: EdgeInsets.zero,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}
