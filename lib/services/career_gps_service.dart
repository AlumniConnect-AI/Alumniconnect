import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// CareerGPSService bridges the Flutter app with the Career GPS AI engine
/// running inside the unified Python FastAPI server (ai-module/api/main.py).
///
/// Primary strategy: POST /career-gps/analyze with cached CandidateProfile.
/// Fallback strategy: native Dart roadmap generation (offline mode).
///
/// The server reads the CandidateProfile.allSkills and primaryDomain to
/// auto-detect the best target role if not explicitly provided.
class CareerGPSService {
  static final CareerGPSService _instance = CareerGPSService._internal();
  factory CareerGPSService() => _instance;
  CareerGPSService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Base URL configured via ApiConfig
  String get apiBaseUrl => ApiConfig.baseUrl;

  // ── Career Skills Matrix (fallback only) ──────────────────────────────────
  static const Map<String, List<String>> _careerSkillsMatrix = {
    'Mobile App Developer (Flutter)': [
      'flutter', 'dart', 'firebase', 'supabase', 'git', 'android', 'ios', 'state management'
    ],
    'AI / ML Engineer': [
      'python', 'machine learning', 'deep learning', 'tensorflow', 'pytorch', 'nlp', 'scikit-learn', 'git'
    ],
    'Data Scientist': [
      'python', 'machine learning', 'scikit-learn', 'sql', 'data visualization', 'git'
    ],
    'Full-Stack Web Developer': [
      'html', 'css', 'javascript', 'react', 'nodejs', 'express', 'mongodb', 'postgresql', 'git'
    ],
    'Backend Developer': [
      'python', 'django', 'fastapi', 'postgresql', 'docker', 'redis', 'git'
    ],
    'DevOps Engineer': [
      'docker', 'kubernetes', 'aws', 'gcp', 'ci/cd', 'linux', 'git'
    ],
    'Cloud Architect': [
      'aws', 'azure', 'gcp', 'docker', 'kubernetes', 'terraform', 'security'
    ],
  };

  static const Map<String, List<Map<String, String>>> _recommendedProjects = {
    'Mobile App Developer (Flutter)': [
      {
        'title': 'AI Career Twin Mobile Client',
        'tech': 'Flutter, Dart, Firebase, Supabase, Provider',
        'level': 'Advanced',
        'description': 'Build a responsive cross-platform app with real-time Firestore sync & AI analysis integration.'
      },
      {
        'title': 'Real-Time Offline-First Chat & Social App',
        'tech': 'Flutter, SQLite, WebSockets, Firebase Auth',
        'level': 'Intermediate',
        'description': 'Develop a secure messaging client with local caching, media upload, and background notifications.'
      },
    ],
    'AI / ML Engineer': [
      {
        'title': 'NLP Resume & Skill Gap Analyzer Engine',
        'tech': 'Python, TF-IDF, Scikit-learn, FastAPI, PyTorch',
        'level': 'Advanced',
        'description': 'Build an API service computing semantic vector similarity and personalized skill roadmaps.'
      },
    ],
    'Data Scientist': [
      {
        'title': 'Predictive Alumni Network Analytics Dashboard',
        'tech': 'Python, Pandas, Scikit-learn, Streamlit, SQL',
        'level': 'Intermediate',
        'description': 'Create an interactive analytics app predicting career trajectory and salary benchmarks.'
      },
    ],
  };

  Future<void> initializeModel() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isInitialized = true;
  }

  // ── Primary: Generate Roadmap from CandidateProfile (Python backend) ───────
  /// Sends the full CandidateProfile JSON (from /resume/upload) to the Career GPS engine.
  /// The Python model reads allSkills, primaryDomain, totalExperienceYears, education
  /// and generates a data-driven roadmap — not hardcoded Dart logic.
  Future<Map<String, dynamic>> generateRoadmapFromProfile({
    required Map<String, dynamic> candidateProfile,
    String? targetRole,
  }) async {
    if (!_isInitialized) await initializeModel();

    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/career-gps/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'profile': candidateProfile,
              'target_role': targetRole,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['roadmap'] as Map<String, dynamic>;
        }
        throw Exception(data['detail'] ?? 'Career GPS server returned error.');
      }
      throw Exception('Career GPS API error: ${response.statusCode}');
    } on TimeoutException {
      throw Exception('Career GPS request timed out. Check server at $apiBaseUrl');
    } on http.ClientException {
      // Fall through to native engine
      return _generateNative(
        targetRole ?? 'Full-Stack Web Developer',
        (candidateProfile['allSkills'] as List?)?.join(', ') ?? '',
        'Bachelors',
        (candidateProfile['totalExperienceYears'] as num?)?.toDouble() ?? 1.0,
      );
    }
  }

  // ── Legacy: Generate Roadmap from text inputs ───────────────────────────────
  /// Used by the Career GPS screen's manual text input form.
  /// Routes to Python backend first; falls back to native Dart engine.
  Future<Map<String, dynamic>> generateRoadmap({
    required String targetRole,
    required String currentSkillsText,
    String education = 'Bachelors',
    double experienceYears = 1.0,
  }) async {
    if (!_isInitialized) await initializeModel();

    // Build a minimal profile dict for the Python engine
    final skillsList = currentSkillsText
        .split(RegExp(r'[,;\n]'))
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();

    final syntheticProfile = {
      'allSkills': skillsList,
      'all_skills': skillsList,
      'primaryDomain': _guessDomain(targetRole),
      'primary_domain': _guessDomain(targetRole),
      'totalExperienceYears': experienceYears,
      'experience': {'total_years': experienceYears},
      'education': _mapEducation(education),
    };

    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/career-gps/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'profile': syntheticProfile,
              'target_role': targetRole,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final roadmap = data['roadmap'] as Map<String, dynamic>;
          // Normalize field names for the Flutter UI
          return _normalizeRoadmap(roadmap, targetRole);
        }
      }
    } catch (_) {
      // Fall through to native engine
    }

    return _generateNative(targetRole, currentSkillsText, education, experienceYears);
  }

  // ── Native Fallback Engine ─────────────────────────────────────────────────
  Map<String, dynamic> _generateNative(
    String targetRole,
    String currentSkillsText,
    String education,
    double experienceYears,
  ) {
    final userSkillSet = currentSkillsText
        .toLowerCase()
        .split(RegExp(r'[,;\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    final reqSkills = _careerSkillsMatrix[targetRole] ?? [
      'python', 'git', 'problem solving', 'system design', 'agile'
    ];

    final matched = <String>[];
    final missing = <String>[];

    for (final skill in reqSkills) {
      bool found = false;
      for (final uSkill in userSkillSet) {
        if (uSkill.contains(skill) || skill.contains(uSkill)) {
          found = true;
          break;
        }
      }
      if (found) matched.add(skill);
      else missing.add(skill);
    }

    final skillMatchRatio = reqSkills.isNotEmpty ? matched.length / reqSkills.length : 0.0;
    final expRatio = min(1.0, experienceYears / 3.0);
    double eduWeight = 0.7;
    if (education.toLowerCase().contains('master')) eduWeight = 0.85;
    if (education.toLowerCase().contains('phd')) eduWeight = 1.0;

    final rawScore = (skillMatchRatio * 0.55) + (expRatio * 0.25) + (eduWeight * 0.20);
    final readinessScore = double.parse((rawScore * 100).toStringAsFixed(1));

    String tier;
    if (readinessScore >= 80) tier = "Ready to Apply ";
    else if (readinessScore >= 65) tier = "Near Ready ";
    else if (readinessScore >= 45) tier = "Developing Skills ";
    else tier = "Getting Started ";

    final p1Skills = missing.take((missing.length / 2).ceil()).toList();
    final p2Skills = missing.skip(p1Skills.length).toList();

    final phases = [
      {
        'phase': 'Phase 1: Foundations & Essential Skills',
        'duration': 'Weeks 1 – 4',
        'status': p1Skills.isEmpty ? 'Completed ': 'In Progress ',
        'target_skills': p1Skills.isEmpty ? ['Core Fundamentals Review'] : p1Skills,
        'milestone': 'Master fundamental toolchains and core language concepts.',
      },
      {
        'phase': 'Phase 2: Core Engineering & Architecture',
        'duration': 'Weeks 5 – 8',
        'status': 'Upcoming ',
        'target_skills': p2Skills.isEmpty ? ['Advanced Design Patterns'] : p2Skills,
        'milestone': 'Build complex module implementations & system designs.',
      },
      {
        'phase': 'Phase 3: Production Deployment & Portfolio',
        'duration': 'Weeks 9 – 12',
        'status': 'Future ',
        'target_skills': ['CI/CD', 'Production Monitoring', 'Portfolio Project'],
        'milestone': 'Deploy scalable project live and optimize for technical interviews.',
      },
    ];

    final projects = _recommendedProjects[targetRole] ?? [
      {
        'title': 'Scalable End-to-End Enterprise Solution',
        'tech': reqSkills.take(4).join(', '),
        'level': 'Advanced',
        'description': 'Architect a production-grade system with full CI/CD, unit tests, and live deployment.'
      }
    ];

    final certs = [
      'Google Cloud Professional Cloud Architect / Associate Engineer',
      'AWS Certified Developer / Solutions Architect',
      'Meta Professional Engineering Certification',
    ];

    final nextBestAction = missing.isNotEmpty
        ? "Priority Focus: Build hands-on mastery in ${missing.first} over the next 2 weeks."
        : "You are fully aligned! Prepare your resume & target top company interviews.";

    return {
      'target_role': targetRole,
      'readiness_score': readinessScore,
      'tier': tier,
      'skill_gap': {
        'acquired': matched,
        'required': reqSkills,
        'missing': missing,
      },
      'phases': phases,
      'projects': projects,
      'certifications': certs,
      'next_best_action': nextBestAction,
    };
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _guessDomain(String role) {
    if (role.contains('Flutter') || role.contains('Mobile')) return 'Mobile Development';
    if (role.contains('AI') || role.contains('ML')) return 'AI / ML';
    if (role.contains('Data')) return 'Data Analytics';
    if (role.contains('Full')) return 'Web Development';
    if (role.contains('DevOps') || role.contains('Cloud')) return 'Infrastructure';
    return 'Software Development';
  }

  List<String> _mapEducation(String education) {
    final lower = education.toLowerCase();
    if (lower.contains('phd')) return ['phd'];
    if (lower.contains('master')) return ['masters'];
    if (lower.contains('bachelor')) return ['bachelors'];
    if (lower.contains('diploma')) return ['diploma'];
    return ['bachelors'];
  }

  /// Normalizes Python model output field names to match Flutter UI expectations.
  Map<String, dynamic> _normalizeRoadmap(Map<String, dynamic> roadmap, String targetRole) {
    // Python model returns 'timelineRoadmap' — map to 'phases' for UI
    if (!roadmap.containsKey('phases') && roadmap.containsKey('timelineRoadmap')) {
      final timeline = roadmap['timelineRoadmap'] as List?;
      if (timeline != null) {
        roadmap['phases'] = timeline.map((t) {
          final m = t as Map<String, dynamic>;
          return {
            'phase': m['phase'] ?? m['timeframe'] ?? '',
            'duration': m['timeframe'] ?? '',
            'status': 'In Progress ',
            'target_skills': m['focus_skills'] ?? [],
            'milestone': m['milestone'] ?? '',
          };
        }).toList();
      }
    }

    // Normalize skill gap
    if (!roadmap.containsKey('skill_gap') && roadmap.containsKey('skillGap')) {
      roadmap['skill_gap'] = roadmap['skillGap'];
    }

    // Normalize readiness score
    if (!roadmap.containsKey('readiness_score') && roadmap.containsKey('readinessScore')) {
      roadmap['readiness_score'] = roadmap['readinessScore'];
    }

    // Normalize target role
    if (!roadmap.containsKey('target_role') && roadmap.containsKey('targetRole')) {
      roadmap['target_role'] = roadmap['targetRole'];
    }

    // Normalize projects
    if (!roadmap.containsKey('projects') && roadmap.containsKey('recommendedProjects')) {
      roadmap['projects'] = roadmap['recommendedProjects'];
    }

    // Ensure next_best_action exists
    roadmap['next_best_action'] ??= roadmap['personalizedAdvice'] ?? '';

    return roadmap;
  }
}
