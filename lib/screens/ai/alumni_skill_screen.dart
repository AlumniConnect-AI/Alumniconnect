import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../providers/alumni_skill_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/ai_processing_loader.dart';
import '../../services/meeting_service.dart';
import '../../widgets/theme/glass_card.dart';
import '../../widgets/theme/neon_button.dart';
import '../../widgets/theme/gradient_icon.dart';
import '../../widgets/theme/ai_section_header.dart';
import '../alumni/alumni_profile_screen.dart';
import '../chat/chat_screen.dart';

class AlumniSkillScreen extends StatefulWidget {
  const AlumniSkillScreen({super.key});

  @override
  State<AlumniSkillScreen> createState() => _AlumniSkillScreenState();
}

class _AlumniSkillScreenState extends State<AlumniSkillScreen>
    with TickerProviderStateMixin {
  String? _uploadedFilename;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Tracks which mentor UIDs have already received a connection request
  // so the button can be disabled/updated after first tap.
  final Set<String> _sentConnections = {};
  bool _connectingUid = false;

  // Category display names and colors
  static const Map<String, Map<String, dynamic>> _skillCategoryMeta = {
    'languages': {'label': 'Languages', 'color': Color(0xFF00E5FF)},
    'frameworks': {'label': 'Frameworks', 'color': Color(0xFF7C4DFF)},
    'databases': {'label': 'Databases', 'color': Color(0xFF00BFA5)},
    'biTools': {'label': 'BI Tools', 'color': Color(0xFFFF6D00)},
    'cloud': {'label': 'Cloud', 'color': Color(0xFF2979FF)},
    'aiMlTools': {'label': 'AI/ML', 'color': Color(0xFFE040FB)},
    'tools': {'label': 'Dev Tools', 'color': Color(0xFF69F0AE)},
    'softSkills': {'label': 'Soft Skills', 'color': Color(0xFFFFD740)},
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handlePdfUpload(
      BuildContext context, AlumniSkillProvider provider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() => _uploadedFilename = file.name);

        if (file.bytes == null || file.bytes!.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Could not read file. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        await provider.analyzeResumeBytes(
          pdfBytes: file.bytes!,
          filename: file.name,
        );

        if (context.mounted) {
          if (provider.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${provider.error}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 6),
              ),
            );
          } else {
            _fadeController.forward(from: 0);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Analyzed: ${file.name}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading resume: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AlumniSkillProvider>(context);

    // Start fade animation when results arrive
    if (provider.result != null && _fadeController.value == 0) {
      _fadeController.forward();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            GradientIcon(icon: Icons.diversity_3, size: 24),
            SizedBox(width: 10),
            Text(
              'Alumni Skill AI Matcher',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: () {
              setState(() => _uploadedFilename = null);
              _fadeController.reset();
              provider.reset();
            },
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
              // ── HERO BANNER ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF071A0F), Color(0xFF0A1A28), Color(0xFF071A14)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.accentEmerald.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentEmerald.withValues(alpha: 0.12),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            gradient: AppGradients.emeraldCyan,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.handshake, color: Colors.black, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ALUMNI SKILL AI ENGINE',
                                style: TextStyle(
                                  color: AppColors.accentEmerald,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Find the Best Alumni Mentor Using AI',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Upload your PDF resume to extract your skill profile, evaluate missing skills, '
                      'and rank recommended alumni mentors using SBERT semantic AI in real-time.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── UPLOAD INTERFACE ─────────────────────────────────────────
              if (provider.result == null && !provider.isLoading) ...[
                const AISectionHeader(title: 'Upload Your Profile'),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _handlePdfUpload(context, provider),
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.cardDark.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accentEmerald.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accentEmerald.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            color: AppColors.accentEmerald,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Select PDF Resume',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Supports Canva, Word, LinkedIn, and ATS PDFs',
                          style: TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_uploadedFilename != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        '📎 $_uploadedFilename',
                        style: const TextStyle(
                          color: AppColors.accentEmerald,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],

              // ── LOADING ──────────────────────────────────────────────────
              if (provider.isLoading) ...[
                const SizedBox(height: 40),
                AIProcessingLoader(
                  elapsedSeconds: provider.elapsedSeconds,
                  loadingMessage: provider.loadingMessage,
                  primaryColor: AppColors.accentEmerald,
                ),
                const SizedBox(height: 40),
              ],

              // ── RESULTS ──────────────────────────────────────────────────
              if (provider.result != null && !provider.isLoading)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildResults(context, theme, provider),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, ThemeData theme, AlumniSkillProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── CANDIDATE PROFILE SUMMARY ────────────────────────────────────
        const AISectionHeader(title: 'Candidate Profile Summary'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(18),
          borderColor: AppColors.accentEmerald.withValues(alpha: 0.25),
          child: Column(
            children: [
              _buildSummaryRow(context, '👤 Name', provider.candidateName),
              const Divider(height: 16),
              _buildSummaryRow(context, '🎓 Highest Degree', provider.candidateDegree),
              if (provider.candidateCollege.isNotEmpty) ...[
                const Divider(height: 16),
                _buildSummaryRow(context, '🏫 College', provider.candidateCollege),
              ],
              if (provider.candidateGraduationYear.isNotEmpty) ...[
                const Divider(height: 16),
                _buildSummaryRow(context, '📅 Graduation Year', provider.candidateGraduationYear),
              ],
              const Divider(height: 16),
              _buildSummaryRow(context, '🏢 Domain', provider.candidateDomain),
              const Divider(height: 16),
              _buildSummaryRow(context, '💼 Current Role', provider.candidateCurrentRole),
              const Divider(height: 16),
              _buildSummaryRowHighlighted(
                context,
                '⏱ Experience',
                provider.candidateExperienceDisplay, // Fixed — never shows 17 years
                AppColors.accentEmerald,
              ),
              if (provider.resumeScore > 0) ...[
                const Divider(height: 16),
                // ── RESUME READINESS SCORE (P2 fix: distinct label from Career Twin JD score) ──
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '📊 Resume Readiness Score',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Tooltip(
                                  message:
                                      'Domain benchmark score — measures how ready your\n'
                                      'resume is for industry roles in your field.\n'
                                      'This is NOT the same as the JD Match Score\n'
                                      'shown in Career Twin Engine (which requires a JD).',
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 13,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Domain benchmark vs. industry standards (no JD required)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${provider.resumeScore.toStringAsFixed(0)}% — ${provider.readinessLevel}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: provider.resumeScore >= 70
                                ? AppColors.accentEmerald
                                : (provider.resumeScore >= 50 ? Colors.orange : Colors.redAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── EXTRACTED SKILLS (CATEGORIZED NEON CHIPS) ────────────────────
        const AISectionHeader(title: 'Extracted Skills'),
        const SizedBox(height: 12),
        _buildCategorizedSkillChips(provider),

        const SizedBox(height: 28),

        // ── RANKED ALUMNI MATCHES ────────────────────────────────────────
        const AISectionHeader(title: 'Ranked Alumni Matches'),
        const SizedBox(height: 12),
        _buildAlumniMatchCards(context, theme, provider),

        const SizedBox(height: 28),

        // ── MENTORSHIP RECOMMENDATIONS ───────────────────────────────────
        const AISectionHeader(title: 'Mentorship Recommendations'),
        const SizedBox(height: 12),
        _buildMentorCards(context, theme, provider),

        const SizedBox(height: 24),

        // ── NETWORKING SUGGESTIONS ───────────────────────────────────────
        const AISectionHeader(title: 'Networking Suggestions'),
        const SizedBox(height: 12),
        _buildNetworkingCards(context, theme, provider),

        const SizedBox(height: 24),

        // ── SKILL GAP ANALYSIS ───────────────────────────────────────────
        const AISectionHeader(title: 'Skill Gap Analysis'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderColor: Colors.redAccent.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Missing Skills vs. Matched Alumni:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<String>.from(provider.result?['missingSkills'] ?? [])
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.1),
                                blurRadius: 6,
                              )
                            ],
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── PHASED SKILLING ROADMAP ──────────────────────────────────────
        const AISectionHeader(title: 'AI-Generated Skilling Roadmap'),
        const SizedBox(height: 12),
        _buildPhasedRoadmap(context, theme, provider),

        const SizedBox(height: 40),

        NeonButton(
          text: 'Upload New Resume',
          icon: Icons.refresh,
          gradient: AppGradients.emeraldCyan,
          onPressed: () {
            setState(() => _uploadedFilename = null);
            _fadeController.reset();
            provider.reset();
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── SKILL CHIPS (CATEGORIZED + NEON COLOR CODED) ──────────────────────────
  Widget _buildCategorizedSkillChips(AlumniSkillProvider provider) {
    final skillsByCategory = provider.skillsByCategory;
    if (skillsByCategory.isEmpty) {
      final flat = provider.extractedSkills;
      if (flat.isEmpty) return const Text('No skills detected.');
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: flat.map((s) => _neonChip(s, AppColors.accentEmerald)).toList(),
      );
    }

    final widgets = <Widget>[];
    for (final entry in skillsByCategory.entries) {
      if (entry.value.isEmpty) continue;
      final meta = _skillCategoryMeta[entry.key];
      final color = meta != null ? (meta['color'] as Color) : AppColors.accentEmerald;
      final label = meta != null ? (meta['label'] as String) : entry.key;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entry.value.map((s) => _neonChip(s, color)).toList(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _neonChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 6),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── RANKED ALUMNI MATCH CARDS ────────────────────────────────────────────
  Widget _buildAlumniMatchCards(
      BuildContext context, ThemeData theme, AlumniSkillProvider provider) {
    final alumni =
        List<Map<String, dynamic>>.from(provider.result?['alumniMatches'] ?? []);

    if (alumni.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.people_outline, color: Colors.white38, size: 40),
            const SizedBox(height: 12),
            Text(
              'No alumni matches found.\nEnsure alumni are registered in Firestore with skills.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alumni.take(5).length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final a = alumni[index];
        final name = a['name']?.toString() ?? 'Alumni';
        final company = a['company']?.toString() ?? '';
        final role = a['role']?.toString() ?? '';
        final matchPct = (a['matchPercentage'] as num?)?.toDouble() ?? 0.0;
        final photoUrl = a['photoUrl'] as String?;
        final matchingSkills = List<String>.from(a['matchingSkills'] ?? []);
        final matchReasons = List<String>.from(a['matchReasons'] ?? []);
        final expYears = (a['experienceYears'] as num?)?.toDouble() ?? 0.0;
        final gradYear = a['graduationYear']?.toString() ?? '';
        final rank = (a['rank'] as num?)?.toInt() ?? (index + 1);

        final scoreColor = matchPct >= 70
            ? AppColors.accentEmerald
            : (matchPct >= 50 ? Colors.orange : Colors.white54);

        return GlassCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlumniProfileScreen(userId: a['uid']?.toString() ?? ''),
            ),
          ),
          padding: const EdgeInsets.all(16),
          borderColor: AppColors.accentEmerald.withValues(alpha: 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Rank badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: AppGradients.emeraldCyan,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.accentEmerald.withValues(alpha: 0.2),
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.accentEmerald,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role.isNotEmpty && company.isNotEmpty
                              ? '$role at $company'
                              : company.isNotEmpty ? company : role,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Match percentage badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${matchPct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              // Metadata badges
              if (gradYear.isNotEmpty || expYears > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (gradYear.isNotEmpty)
                      _infoBadge('🎓 Class of $gradYear', Colors.purple),
                    if (gradYear.isNotEmpty && expYears > 0)
                      const SizedBox(width: 6),
                    if (expYears > 0)
                      _infoBadge(
                        '💼 ${expYears.toStringAsFixed(0)} yrs exp',
                        Colors.blue,
                      ),
                  ],
                ),
              ],

              if (matchReasons.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '💡 ${matchReasons.first}',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              if (matchingSkills.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Shared Skills:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentEmerald,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: matchingSkills
                      .take(5)
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentEmerald.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.accentEmerald.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 10,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _infoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── MENTOR RECOMMENDATION CARDS ──────────────────────────────────────────
  Widget _buildMentorCards(
      BuildContext context, ThemeData theme, AlumniSkillProvider provider) {
    final mentors = List<Map<String, dynamic>>.from(
        provider.result?['mentorshipRecommendations'] ?? []);

    if (mentors.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No mentors found. Alumni profiles with skills will appear here.',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
        ),
      );
    }

    return Column(
      children: mentors.map((m) {
        final name = m['mentorName']?.toString() ?? 'Mentor';
        final company = m['company']?.toString() ?? '';
        final role = m['role']?.toString() ?? '';
        final reason = m['reason']?.toString() ?? '';
        final photoUrl = m['photoUrl'] as String?;
        final matchPct = (m['matchPercentage'] as num?)?.toDouble() ?? 0.0;
        final expYears = (m['experienceYears'] as num?)?.toDouble() ?? 0.0;
        final availability = m['availability']?.toString() ?? 'Available';
        final sharedSkills = List<String>.from(m['sharedSkills'] ?? []);

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.accentEmerald.withValues(alpha: 0.25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.accentEmerald.withValues(alpha: 0.2),
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.accentEmerald,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (role.isNotEmpty || company.isNotEmpty)
                            Text(
                              role.isNotEmpty && company.isNotEmpty
                                  ? '$role at $company'
                                  : company.isNotEmpty ? company : role,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (matchPct > 0)
                          Text(
                            '${matchPct.toStringAsFixed(0)}% Match',
                            style: const TextStyle(
                              color: AppColors.accentEmerald,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '✅ $availability',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentEmerald.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.accentEmerald.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.accentEmerald, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodyMedium?.color,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (sharedSkills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: sharedSkills
                        .take(4)
                        .map((s) => _neonChip(s, AppColors.accentEmerald))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                // ── CONNECT + MESSAGE BUTTONS ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: StatefulBuilder(
                        builder: (ctx, setBtn) {
                          final mentorUid = m['uid']?.toString() ?? '';
                          final alreadySent = _sentConnections.contains(mentorUid);
                          return OutlinedButton.icon(
                            onPressed: alreadySent || mentorUid.isEmpty
                                ? null
                                : () async {
                                    try {
                                      final sent = await MeetingService
                                          .sendConnectionRequest(
                                        mentorUid: mentorUid,
                                        mentorName: name,
                                      );
                                      setState(() {
                                        _sentConnections.add(mentorUid);
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(sent
                                              ? '✅ Connection request sent to $name'
                                              : 'ℹ️ Request already sent to $name'),
                                          backgroundColor: sent
                                              ? AppColors.accentEmerald
                                              : Colors.orange,
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text('Failed to connect: $e'),
                                          backgroundColor: AppColors.error,
                                        ));
                                      }
                                    }
                                  },
                            icon: Icon(
                              alreadySent
                                  ? Icons.check_circle_outline
                                  : Icons.connect_without_contact,
                              size: 16,
                            ),
                            label: Text(alreadySent ? 'Request Sent' : 'Connect'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: alreadySent
                                  ? Colors.grey
                                  : AppColors.accentEmerald,
                              side: BorderSide(
                                  color: alreadySent
                                      ? Colors.grey.withValues(alpha: 0.4)
                                      : AppColors.accentEmerald
                                          .withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final mentorUid = m['uid']?.toString() ?? '';
                          if (mentorUid.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cannot open chat — mentor ID missing'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          try {
                            final chatId =
                                await MeetingService.getOrCreateChat(mentorUid);
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    chatId: chatId,
                                    peerId: mentorUid,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to open chat: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.message_outlined, size: 16),
                        label: const Text('Message'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryNeon,
                          side: BorderSide(
                              color: AppColors.primaryNeon.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── NETWORKING SUGGESTION CARDS ──────────────────────────────────────────
  Widget _buildNetworkingCards(
      BuildContext context, ThemeData theme, AlumniSkillProvider provider) {
    final suggestions = List<Map<String, dynamic>>.from(
        provider.result?['networkingSuggestions'] ?? []);

    if (suggestions.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Networking suggestions will appear here based on your skill matches.',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
        ),
      );
    }

    return Column(
      children: suggestions.map((s) {
        final name = s['name']?.toString() ?? 'Alumni';
        final company = s['company']?.toString() ?? '';
        final role = s['role']?.toString() ?? '';
        final reason = s['reason']?.toString() ?? '';
        final photoUrl = s['photoUrl'] as String?;
        final matchPct = (s['matchPercentage'] as num?)?.toDouble() ?? 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            borderColor: AppColors.primaryNeon.withValues(alpha: 0.2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryNeon.withValues(alpha: 0.15),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryNeon,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          if (matchPct > 0)
                            Text(
                              '${matchPct.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppColors.primaryNeon,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      if (role.isNotEmpty || company.isNotEmpty)
                        Text(
                          role.isNotEmpty && company.isNotEmpty
                              ? '$role at $company'
                              : company.isNotEmpty ? company : role,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      if (reason.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '💡 $reason',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color,
                            height: 1.3,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── PHASED MONTHLY SKILLING ROADMAP ──────────────────────────────────────
  Widget _buildPhasedRoadmap(
      BuildContext context, ThemeData theme, AlumniSkillProvider provider) {
    final roadmap = List<Map<String, dynamic>>.from(
        provider.result?['suggestedLearningPath'] ?? []);

    if (roadmap.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Skilling roadmap will appear after skill gap analysis.',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
        ),
      );
    }

    return Column(
      children: roadmap.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final phase = step['phase']?.toString() ?? 'Phase ${i + 1}';
        final skill = step['skill']?.toString() ?? '';
        final action = step['action']?.toString() ?? '';
        final difficulty = step['difficulty']?.toString() ?? '';
        final duration = step['duration']?.toString() ?? '';
        final reason = step['reason']?.toString() ?? '';

        final colors = [
          AppColors.primaryNeon,
          AppColors.accentEmerald,
          Colors.orange,
          Colors.purple,
          Colors.blue,
          Colors.teal,
        ];
        final color = colors[i % colors.length];

        final difficultyColors = {
          'Beginner': Colors.green,
          'Intermediate': Colors.orange,
          'Advanced': Colors.red,
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline dot
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (i < roadmap.length - 1)
                    Container(
                      width: 2,
                      height: 30,
                      color: color.withValues(alpha: 0.2),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  borderColor: color.withValues(alpha: 0.25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              phase,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (difficulty.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: (difficultyColors[difficulty] ?? Colors.grey)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                difficulty,
                                style: TextStyle(
                                  color: difficultyColors[difficulty] ?? Colors.grey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (duration.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '⏱ $duration',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        skill,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      if (reason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline, color: color, size: 13),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.8),
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── HELPER WIDGETS ────────────────────────────────────────────────────────
  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRowHighlighted(
      BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
