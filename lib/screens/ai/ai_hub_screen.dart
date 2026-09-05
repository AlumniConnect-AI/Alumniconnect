import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/theme/glass_card.dart';
import '../../widgets/theme/neon_button.dart';
import '../../widgets/theme/gradient_icon.dart';
import 'career_twin_screen.dart';
import 'career_gps_screen.dart';
import 'alumni_skill_screen.dart';

class AiHubScreen extends StatelessWidget {
  const AiHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            GradientIcon(icon: Icons.psychology, size: 24),
            SizedBox(width: 10),
            Text(
              "AI Intelligence Hub",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HERO WELCOME BANNER ─────────────────────────────────────
              GlassCard(
                padding: const EdgeInsets.all(22),
                borderColor: theme.dividerColor,
                backgroundColor: theme.cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppGradients.neonCyanPurple,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryNeon.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "AI CAREER HUB",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Four-Engine Intelligence",
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Accelerate your professional growth using our trained machine learning models for resume parsing, career roadmaps, skill gap analysis & semantic mentor matching.",
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                "Select AI Engine",
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // ── CARD 1: CAREER TWIN AI ─────────────────────────────────
              GlassCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CareerTwinScreen()),
                ),
                padding: const EdgeInsets.all(20),
                borderColor: theme.dividerColor,
                backgroundColor: theme.cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.biotech, color: AppColors.primary, size: 26),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            "MODEL 1 • ACTIVE",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "AI Career Twin Engine",
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Resume Matching & ATS Analysis. Analyze resumes against job postings, compute weighted ATS scores, and find career twins.",
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    NeonButton(
                      text: "Launch Career Twin Analysis",
                      icon: Icons.analytics_outlined,
                      gradient: AppGradients.neonCyanPurple,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CareerTwinScreen()),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── CARD 2: CAREER GPS AI ──────────────────────────────────
              GlassCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CareerGpsScreen()),
                ),
                padding: const EdgeInsets.all(20),
                borderColor: theme.dividerColor,
                backgroundColor: theme.cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.purpleSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.explore, color: AppColors.accentPurple, size: 26),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            "MODEL 2 • ACTIVE",
                            style: TextStyle(
                              color: AppColors.accentPurple,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "AI Career GPS Engine",
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Career Roadmap & Guidance. Predict target career roadmaps, generate 3-phase milestone timelines, and receive project guidance.",
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    NeonButton(
                      text: "Generate Career GPS Roadmap",
                      icon: Icons.map,
                      gradient: AppGradients.purplePink,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CareerGpsScreen()),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── CARD 3: AI SKILL GAP ANALYZER ──────────────────────────
              GlassCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlumniSkillScreen()),
                ),
                padding: const EdgeInsets.all(20),
                borderColor: theme.dividerColor,
                backgroundColor: theme.cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.assessment_outlined, color: Colors.orange, size: 26),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            "MODEL 3 • ACTIVE",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "AI Skill Gap Analyzer",
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Missing Skills & Learning Path. Identify critical missing technical skills against industry benchmark roles and generate phased upskilling plans.",
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    NeonButton(
                      text: "Analyze Skill Gaps",
                      icon: Icons.checklist_rtl,
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrangeAccent],
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AlumniSkillScreen()),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── CARD 4: AI MENTOR MATCH ────────────────────────────────
              GlassCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlumniSkillScreen()),
                ),
                padding: const EdgeInsets.all(20),
                borderColor: theme.dividerColor,
                backgroundColor: theme.cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentEmerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.handshake, color: AppColors.accentEmerald, size: 26),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentEmerald.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.6)),
                          ),
                          child: const Text(
                            "MODEL 4 • SBERT ACTIVE",
                            style: TextStyle(
                              color: AppColors.accentEmerald,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "AI Mentor Match Engine",
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Find the Best Alumni Mentor. Semantic SBERT matching connects you with alumni based on shared skills, interests, department, and career goals.",
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    NeonButton(
                      text: "Find My Alumni Mentor",
                      icon: Icons.diversity_3,
                      gradient: AppGradients.emeraldCyan,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AlumniSkillScreen()),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
