import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../providers/ai_provider.dart';
import '../../providers/ai_session_cache.dart';
import '../../widgets/theme/glass_card.dart';
import '../../widgets/theme/neon_button.dart';
import '../../widgets/theme/gradient_icon.dart';
import '../../widgets/theme/ai_section_header.dart';
import 'alumni_skill_screen.dart';

/// Career Twin Screen — Premium AI-powered Resume vs JD Career Twin matcher.
///
/// Upload PDF resume + paste a job description →
/// Animated match score ring, Career Twin match card, placement readiness breakdown.
class CareerTwinScreen extends StatefulWidget {
  const CareerTwinScreen({super.key});

  @override
  State<CareerTwinScreen> createState() => _CareerTwinScreenState();
}

class _CareerTwinScreenState extends State<CareerTwinScreen>
    with TickerProviderStateMixin {
  final _jdController = TextEditingController();
  final _expController = TextEditingController(text: '0');

  String? _uploadedFilename;
  Uint8List? _uploadedBytes;

  late AnimationController _scoreRingController;
  late AnimationController _pulseController;
  late Animation<double> _scoreRingAnimation;
  late Animation<double> _pulseAnimation;

  final AISessionCache _cache = AISessionCache();

  @override
  void initState() {
    super.initState();
    _scoreRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scoreRingAnimation = CurvedAnimation(
      parent: _scoreRingController,
      curve: Curves.easeOutCubic,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _jdController.dispose();
    _expController.dispose();
    _scoreRingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _uploadedFilename = file.name;
          _uploadedBytes = file.bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _runAnalysis(AIProvider provider) async {
    if (_uploadedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your PDF resume first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_jdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste a job description.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final reqYears = double.tryParse(_expController.text.trim()) ?? 0.0;

    await provider.analyzeFromPdf(
      pdfBytes: _uploadedBytes!,
      filename: _uploadedFilename ?? 'resume.pdf',
      jdText: _jdController.text.trim(),
      requiredExpYears: reqYears,
    );

    // Start score ring animation after results load
    if (provider.result != null) {
      _scoreRingController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AIProvider>(context);

    // Auto-start animation when results arrive
    if (provider.result != null && !_scoreRingController.isAnimating &&
        _scoreRingController.value == 0) {
      _scoreRingController.forward();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            GradientIcon(icon: Icons.biotech, size: 24),
            SizedBox(width: 10),
            Text(
              'AI Career Twin Engine',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: () {
              setState(() {
                _uploadedFilename = null;
                _uploadedBytes = null;
                _scoreRingController.reset();
              });
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
              // ── PREMIUM HERO BANNER ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A0F1E), Color(0xFF1A0A2E), Color(0xFF0A1628)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primaryNeon.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNeon.withValues(alpha: 0.15),
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
                          decoration: BoxDecoration(
                            gradient: AppGradients.neonCyanPurple,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryNeon.withValues(alpha: 0.4),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.biotech, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI CAREER TWIN ENGINE',
                                style: TextStyle(
                                  color: AppColors.primaryNeon,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Find Your Alumni Career Twin',
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Upload your resume and discover alumni with similar career journeys. '
                      'Get personalized skills, certifications, projects, mentorship recommendations, '
                      'and placement readiness powered by AI.',
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

              // ── ERROR BANNER ────────────────────────────────────────────────
              if (provider.error != null) ...[
                GlassCard(
                  borderColor: Colors.red,
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── LOADING ─────────────────────────────────────────────────────
              if (provider.isLoading) ...[
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryNeon,
                          strokeWidth: 3,
                          backgroundColor: AppColors.primaryNeon.withValues(alpha: 0.15),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Analyzing Career Match…',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primaryNeon,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Parsing resume → extracting skills → computing match score',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ]

              // ── RESULTS ─────────────────────────────────────────────────────
              else if (provider.result != null) ...[
                _buildPremiumResults(context, theme, provider),
              ]

              // ── INPUT FORM ──────────────────────────────────────────────────
              else ...[
                _buildInputForm(context, theme, provider),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputForm(BuildContext context, ThemeData theme, AIProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // If cached profile exists, show it
        if (_cache.hasProfile) ...[
          GlassCard(
            borderColor: AppColors.accentEmerald.withValues(alpha: 0.3),
            backgroundColor: AppColors.accentEmerald.withValues(alpha: 0.05),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.accentEmerald, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '✅ Using cached profile: ${_cache.candidateName} | ${_cache.candidateDomain}',
                    style: const TextStyle(
                      color: AppColors.accentEmerald,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Step 1: PDF Upload
        const AISectionHeader(title: 'Step 1 — Upload PDF Resume'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickPdf,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _uploadedFilename == null ? 1.0 : 1.0,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.cardDark.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _uploadedFilename != null
                        ? AppColors.accentEmerald.withValues(alpha: 0.7)
                        : AppColors.primaryNeon.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: _uploadedFilename != null
                      ? [
                          BoxShadow(
                            color: AppColors.accentEmerald.withValues(alpha: 0.15),
                            blurRadius: 16,
                          )
                        ]
                      : null,
                ),
                child: _uploadedFilename != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.accentEmerald, size: 36),
                          const SizedBox(width: 14),
                          Flexible(
                            child: Text(
                              _uploadedFilename!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentEmerald,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file_outlined,
                            color: AppColors.primaryNeon.withValues(alpha: 0.7),
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap to select PDF Resume',
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ATS, Canva, Word, LinkedIn PDF formats supported',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Step 2: JD
        const AISectionHeader(title: 'Step 2 — Paste Job Description'),
        const SizedBox(height: 12),
        TextField(
          controller: _jdController,
          maxLines: 6,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Paste the full job description here…',
            filled: true,
            fillColor: theme.cardColor,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryNeon, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Text(
              'Required Experience (years):',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 60,
              child: TextField(
                controller: _expController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryNeon),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        NeonButton(
          text: 'Find My Career Twin',
          icon: Icons.biotech_outlined,
          gradient: AppGradients.neonCyanPurple,
          isLoading: provider.isLoading,
          onPressed: () => _runAnalysis(provider),
        ),

        const SizedBox(height: 12),
        Center(
          child: Text(
            '⚡ Requires AI server at port 8000 — run start_ai_server.bat',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumResults(
      BuildContext context, ThemeData theme, AIProvider provider) {
    final result = provider.result!;
    final analysis = result['analysis'] as Map<String, dynamic>? ?? result;

    final matchScore = (analysis['matchScore'] as num?)?.toDouble() ??
        (result['career_score'] as Map<String, dynamic>?)?['career_score']
            as double? ??
        0.0;
    final tier = analysis['tier'] as String? ?? '';
    final matchedSkills = List<String>.from(
      analysis['matchedSkills'] as List? ??
          (result['skill_profile'] as Map<String, dynamic>?)?['matched_skills']
              as List? ??
          [],
    );
    final missingSkills = List<String>.from(
      analysis['missingSkills'] as List? ??
          (result['skill_profile'] as Map<String, dynamic>?)?['missing_skills']
              as List? ??
          [],
    );
    final recommendations = List<String>.from(
      analysis['recommendations'] as List? ??
          (result['skill_profile'] as Map<String, dynamic>?)?['recommendations']
              as List? ??
          [],
    );
    final atsScore = (analysis['atsScore'] as num?)?.toDouble();
    final atsBreakdown = analysis['atsBreakdown'] as Map<String, dynamic>?;

    final scoreColor = matchScore >= 75
        ? AppColors.accentEmerald
        : (matchScore >= 55 ? Colors.orange : Colors.redAccent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── YOUR CAREER TWIN MATCH ──────────────────────────────────────────
        const AISectionHeader(title: '🧬 YOUR CAREER TWIN MATCH'),
        const SizedBox(height: 16),

        // Large animated score ring
        Center(
          child: AnimatedBuilder(
            animation: _scoreRingAnimation,
            builder: (context, _) {
              final animatedScore = matchScore * _scoreRingAnimation.value;
              return SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background glow
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: scoreColor.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    // Score ring
                    CustomPaint(
                      size: const Size(200, 200),
                      painter: _ScoreRingPainter(
                        score: animatedScore / 100.0,
                        color: scoreColor,
                        backgroundColor:
                            scoreColor.withValues(alpha: 0.1),
                      ),
                    ),
                    // Score text
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${animatedScore.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: scoreColor,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: scoreColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            tier,
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // ── PLACEMENT READINESS BREAKDOWN ───────────────────────────────────
        if (atsBreakdown != null) ...[
          const AISectionHeader(title: '📊 Placement Readiness Breakdown'),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(18),
            borderColor: AppColors.primaryNeon.withValues(alpha: 0.2),
            child: Column(
              children: [
                if (atsScore != null)
                  _buildReadinessRow('ATS Score', atsScore, AppColors.primaryNeon),
                _buildReadinessRow(
                  'Skills Match',
                  (atsBreakdown['skill_match_score'] as num?)?.toDouble() ?? 0.0,
                  AppColors.accentEmerald,
                ),
                _buildReadinessRow(
                  'Experience',
                  (atsBreakdown['experience_score'] as num?)?.toDouble() ?? 0.0,
                  Colors.orange,
                ),
                _buildReadinessRow(
                  'Education',
                  (atsBreakdown['education_score'] as num?)?.toDouble() ?? 0.0,
                  Colors.purple,
                ),
                _buildReadinessRow(
                  'Projects & Portfolio',
                  (atsBreakdown['projects_score'] as num?)?.toDouble() ?? 0.0,
                  Colors.cyan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── MATCHED SKILLS ────────────────────────────────────────────────────
        if (matchedSkills.isNotEmpty) ...[
          const AISectionHeader(title: '✅ Matched Skills'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: matchedSkills
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade900.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade400),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.15),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          color: Colors.green.shade200,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],

        // ── MISSING SKILLS ───────────────────────────────────────────────────
        if (missingSkills.isNotEmpty) ...[
          const AISectionHeader(title: '❌ Skill Gaps to Bridge'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: missingSkills
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade400),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          color: Colors.red.shade200,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],

        // ── AI RECOMMENDATIONS ───────────────────────────────────────────────
        if (recommendations.isNotEmpty) ...[
          const AISectionHeader(title: '💡 AI Career Growth Plan'),
          const SizedBox(height: 10),
          ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  borderColor: AppColors.primaryNeon.withValues(alpha: 0.2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.bolt, color: AppColors.primaryNeon, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rec,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 20),
        ],

        // ── CTA: NAVIGATE TO MENTOR MATCH ────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1040), Color(0xFF0A2040)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentEmerald.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              const Text(
                '🎯 Find Your Alumni Mentor',
                style: TextStyle(
                  color: AppColors.accentEmerald,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Match with alumni who walked the same career path and can guide your journey.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              NeonButton(
                text: 'Go to Alumni Mentor Match →',
                icon: Icons.diversity_3,
                gradient: AppGradients.emeraldCyan,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AlumniSkillScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        NeonButton(
          text: 'Analyze Another Resume',
          icon: Icons.refresh,
          gradient: AppGradients.neonCyanPurple,
          onPressed: () {
            setState(() {
              _uploadedFilename = null;
              _uploadedBytes = null;
              _scoreRingController.reset();
            });
            provider.reset();
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildReadinessRow(String label, double score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _scoreRingAnimation,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score / 100.0) * _scoreRingAnimation.value,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the animated circular score ring.
class _ScoreRingPainter extends CustomPainter {
  final double score; // 0.0 to 1.0
  final Color color;
  final Color backgroundColor;

  _ScoreRingPainter({
    required this.score,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Score arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Add glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final sweepAngle = 2 * math.pi * score;
    const startAngle = -math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color;
}
