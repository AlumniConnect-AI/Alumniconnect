import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'mentor_match_service.dart';

/// AlumniSkillService integrates:
/// 1. Python /alumni-skill/analyze (domain-aware SkillGapAnalyzer)
/// 2. MentorMatchService (SBERT mentor ranking via Firestore + /mentor-match/analyze)
/// 3. Builds unified analysis result for the AlumniSkillScreen
class AlumniSkillService {
  static final AlumniSkillService _instance = AlumniSkillService._internal();
  factory AlumniSkillService() => _instance;
  AlumniSkillService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String get apiBaseUrl => ApiConfig.baseUrl;

  final MentorMatchService _mentorMatchService = MentorMatchService();

  /// Domain → Benchmark role ID mapping for the Python SkillGapAnalyzer.
  /// Ensures a Data Analytics resume gets data-relevant missing skills.
  static const Map<String, String> _domainToRoleId = {
    'Data Analytics & BI': 'data_scientist',
    'AI / Machine Learning': 'ai_ml_engineer',
    'Cloud Engineering': 'cloud_devops_engineer',
    'Mobile App Development': 'mobile_developer',
    'Software Engineering': 'backend_engineer',
    'Software Development': 'backend_engineer',
  };

  Future<void> initializeModel() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isInitialized = true;
  }

  /// Full unified analysis pipeline:
  ///
  /// 1. Domain-aware Python Skill Gap Analysis → real, relevant missing skills
  /// 2. SBERT Mentor Match → ranked alumni ordered by semantic similarity
  /// 3. Build mentorship recommendations, networking suggestions, phased roadmap
  Future<Map<String, dynamic>> analyzeAndMatchAlumni({
    required List<String> candidateSkills,
    required String candidateDomain,
    required double candidateExperience,
    required Map<String, dynamic> candidateProfile,
    String candidateName = 'Student',
    String? targetRole,
  }) async {
    if (!_isInitialized) await initializeModel();

    if (candidateSkills.isEmpty) {
      return {
        'error': 'No skills extracted from resume. Please upload a clear, text-based PDF.',
        'alumniMatches': [],
        'mentorshipRecommendations': [],
        'networkingSuggestions': [],
        'missingSkills': [],
        'suggestedLearningPath': [],
        'skillGapResult': null,
      };
    }

    final normalizedCandSkills = candidateSkills
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    // ── Step 1: Domain-Aware Python Skill Gap Analysis ────────────────────────
    Map<String, dynamic>? skillGapResult;
    List<String> missingSkills = [];

    // Map domain to the correct benchmark role ID
    final inferredRoleId = targetRole ??
        _domainToRoleId[candidateDomain] ??
        'data_scientist';

    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/alumni-skill/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'student_name': candidateName,
              'student_skills': candidateSkills,
              'target_role': inferredRoleId,
              'experience_level': candidateExperience >= 3
                  ? 'Mid Level'
                  : 'Entry Level',
            }),
          )
          .timeout(ApiConfig.analyzeTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          skillGapResult = data['skill_gap'] as Map<String, dynamic>?;

          final criticalMissing =
              skillGapResult?['missing_critical_skills'] as List? ?? [];
          final secondaryMissing =
              skillGapResult?['missing_secondary_skills'] as List? ?? [];
          missingSkills = [
            ...criticalMissing.map(
                (s) => (s as Map<String, dynamic>)['skill_name']?.toString() ?? ''),
            ...secondaryMissing.map(
                (s) => (s as Map<String, dynamic>)['skill_name']?.toString() ?? ''),
          ].where((s) => s.isNotEmpty).toList();
        }
      }
    } on TimeoutException {
      // Python server not running — continue with SBERT match only
    } on http.ClientException {
      // Server unreachable — continue with SBERT match only
    } catch (_) {
      // Any error — continue gracefully
    }

    // ── Step 2: SBERT Mentor Match (via MentorMatchService) ──────────────────
    final mentorMatchResult = await _mentorMatchService.findMentors(
      candidateProfile: candidateProfile,
      topK: 5,
    );

    final mentorMatches =
        List<Map<String, dynamic>>.from(mentorMatchResult['mentor_matches'] ?? []);
    final alumniPool =
        List<Map<String, dynamic>>.from(mentorMatchResult['alumni_pool'] ?? []);

    // ── Step 3: Build enriched alumni match cards ─────────────────────────────
    // Build ranked alumni cards from SBERT results
    final rankedAlumniMatches = mentorMatches.map((m) {
      return {
        'uid': m['uid'] ?? '',
        'name': m['name'] ?? 'Alumni',
        'company': m['company'] ?? '',
        'role': m['role'] ?? '',
        'department': m['department'] ?? '',
        'photoUrl': m['photoUrl'],
        'matchingSkills': m['matched_skills'] ?? [],
        'matchPercentage': m['match_percentage'] ?? 0.0,
        'matchReasons': m['match_reasons'] ?? [],
        'experienceYears': m['experience_years'] ?? 0.0,
        'graduationYear': m['graduationYear'] ?? '',
        'similarityScore': m['similarity_score'] ?? 0.0,
        'rank': m['rank'] ?? 0,
      };
    }).toList();

    // ── Step 4: Mentorship Recommendations (top 3 SBERT matches) ─────────────
    final top3 = rankedAlumniMatches.take(3).toList();
    final mentorshipRecommendations = top3.map((m) {
      final skills = List<String>.from(m['matchingSkills'] ?? []);
      final reasons = List<String>.from(m['matchReasons'] ?? []);
      final skillText = skills.isNotEmpty ? skills.take(3).join(', ') : 'shared domain';
      return {
        'mentorName': m['name'],
        'company': m['company'],
        'role': m['role'],
        'photoUrl': m['photoUrl'],
        'matchPercentage': m['matchPercentage'],
        'experienceYears': m['experienceYears'],
        'availability': 'Available for Mentorship',
        'reason': reasons.isNotEmpty
            ? reasons.first
            : 'Shared expertise in $skillText at ${m['company']}.',
        'sharedSkills': skills.take(4).toList(),
      };
    }).toList();

    // ── Step 5: Networking Suggestions (alumni 4–8 from SBERT rank) ───────────
    final networkingSuggestions = rankedAlumniMatches.skip(3).take(5).map((m) {
      final skills = List<String>.from(m['matchingSkills'] ?? []);
      final alumName = (m['name'] as String).split(' ').first;
      String reason;
      if (skills.isNotEmpty) {
        reason =
            'You and $alumName both have expertise in ${skills.take(2).join(' and ')}. '
            'Connect to explore opportunities at ${m['company']}.';
      } else {
        reason =
            '$alumName works at ${m['company']} in ${m['department']}. '
            'A valuable connection for your career in $candidateDomain.';
      }
      return {
        'name': m['name'],
        'company': m['company'],
        'role': m['role'],
        'photoUrl': m['photoUrl'],
        'department': m['department'],
        'reason': reason,
        'matchPercentage': m['matchPercentage'],
      };
    }).toList();

    // ── Step 6: Compute missing skills if Python server was unreachable ────────
    if (missingSkills.isEmpty && top3.isNotEmpty) {
      final allTopSkills = <String>{};
      for (final m in top3) {
        for (final s in List<String>.from(m['matchingSkills'] ?? [])) {
          allTopSkills.add(s);
        }
      }
      // Also look at alumni pool for their full skills
      for (final alum in alumniPool.take(3)) {
        final alumSkills = List<String>.from(alum['skills'] ?? []);
        for (final s in alumSkills) {
          if (!normalizedCandSkills.contains(s.toLowerCase())) {
            allTopSkills.add(s);
          }
        }
      }
      missingSkills = allTopSkills
          .where((s) => !normalizedCandSkills.contains(s.toLowerCase()))
          .take(8)
          .toList();
    }

    // ── Step 7: Build phased AI-generated learning roadmap ────────────────────
    final learningPath = _buildPhasedRoadmap(missingSkills, candidateDomain);

    return {
      'alumniMatches': rankedAlumniMatches,
      'mentorshipRecommendations': mentorshipRecommendations,
      'networkingSuggestions': networkingSuggestions,
      'missingSkills': missingSkills,
      'suggestedLearningPath': learningPath,
      'skillGapResult': skillGapResult,
      'inferredTargetRole': inferredRoleId,
    };
  }

  /// Builds a phased month-by-month learning roadmap based on missing skills.
  List<Map<String, dynamic>> _buildPhasedRoadmap(
    List<String> missingSkills,
    String domain,
  ) {
    if (missingSkills.isEmpty) {
      return [
        {
          'phase': 'Month 1–2',
          'skill': 'Portfolio Project',
          'action': 'Build a capstone project showcasing your existing skills on GitHub.',
          'difficulty': 'Intermediate',
          'duration': '2 Months',
          'reason': 'Strong portfolio projects increase interview callbacks by 3x.',
        },
        {
          'phase': 'Month 3',
          'skill': 'Interview Preparation',
          'action': 'Practice domain-specific interview questions and mock interviews with alumni mentors.',
          'difficulty': 'Intermediate',
          'duration': '1 Month',
          'reason': 'Alumni mock interviews simulate real hiring panel scenarios.',
        },
      ];
    }

    final roadmap = <Map<String, dynamic>>[];
    final phases = [
      'Month 1', 'Month 2', 'Month 3', 'Month 4', 'Month 5', 'Month 6',
    ];

    // Difficulty heuristics by skill type
    final hardSkills = {
      'machine learning', 'deep learning', 'azure data factory',
      'microsoft fabric', 'kubernetes', 'mlops', 'dax', 'etl',
    };
    final mediumSkills = {
      'power bi', 'tableau', 'sql', 'advanced sql', 'docker', 'fastapi',
      'scikit-learn', 'pandas', 'data visualization',
    };

    for (int i = 0; i < missingSkills.length && i < phases.length; i++) {
      final skill = missingSkills[i];
      final skillLower = skill.toLowerCase();
      String difficulty = 'Beginner';
      if (hardSkills.any((h) => skillLower.contains(h))) {
        difficulty = 'Advanced';
      } else if (mediumSkills.any((m) => skillLower.contains(m))) {
        difficulty = 'Intermediate';
      }

      final action = _getRoadmapAction(skill, domain);

      roadmap.add({
        'phase': phases[i],
        'skill': skill,
        'action': action,
        'difficulty': difficulty,
        'duration': '3–4 Weeks',
        'reason': _getRoadmapReason(skill, domain),
      });
    }

    // Always add a capstone project as the final step
    if (missingSkills.length < phases.length) {
      roadmap.add({
        'phase': phases[missingSkills.length],
        'skill': 'Capstone Project',
        'action':
            'Build a complete $domain project integrating ${missingSkills.take(3).join(', ')} '
            'and publish it on GitHub.',
        'difficulty': 'Intermediate',
        'duration': '4–6 Weeks',
        'reason': 'Hands-on projects demonstrate applied competency to recruiters.',
      });
    }

    return roadmap;
  }

  String _getRoadmapAction(String skill, String domain) {
    final actionMap = <String, String>{
      'advanced sql': 'Complete advanced SQL challenges on LeetCode + build a SQL analytics dashboard.',
      'power bi': 'Complete Microsoft PL-300 Power BI Analyst certification track.',
      'microsoft fabric': 'Learn Microsoft Fabric through the free Microsoft Learn path.',
      'azure data factory': 'Build an ETL pipeline project using Azure Data Factory.',
      'dax': 'Practice DAX formulas for Power BI calculated columns and measures.',
      'tableau': 'Complete the Tableau Desktop Specialist certification preparation.',
      'machine learning': 'Complete Andrew Ng Machine Learning Specialization on Coursera.',
      'deep learning': 'Build a neural network project using PyTorch or TensorFlow.',
      'data visualization': 'Create 5 portfolio-quality dashboards using Matplotlib, Seaborn, and Plotly.',
      'etl': 'Design and implement an ETL pipeline project using Python and a cloud tool.',
      'docker': 'Containerize a Python application and deploy it using Docker Compose.',
      'kubernetes': 'Complete the CKAD (Certified Kubernetes Application Developer) prep course.',
      'flutter': 'Build a full-featured Flutter app with Firebase backend and publish to Play Store.',
      'pandas': 'Complete 30 real-world data manipulation challenges using Pandas.',
      'scikit-learn': 'Train, evaluate, and deploy 3 different ML models using Scikit-Learn.',
    };
    final key = skill.toLowerCase();
    return actionMap[key] ??
        'Study $skill through official documentation, tutorials, and build a mini-project to apply it.';
  }

  String _getRoadmapReason(String skill, String domain) {
    final reasonMap = <String, String>{
      'advanced sql': 'SQL is the #1 required skill in 87% of Data Analyst job descriptions.',
      'power bi': 'Microsoft Power BI is the most demanded BI tool in Indian enterprise analytics.',
      'microsoft fabric': 'Microsoft Fabric is replacing traditional ETL pipelines in 2024–2025.',
      'azure data factory': 'ADF is critical for cloud-based data engineering pipelines.',
      'dax': 'DAX mastery separates junior analysts from senior Power BI developers.',
      'tableau': 'Tableau proficiency commands a 15–20% salary premium in analytics roles.',
      'machine learning': 'ML is a core differentiator for Data Analyst → Data Scientist career progression.',
      'data visualization': 'Storytelling with data is the primary skill tested in analytics interviews.',
      'docker': 'Docker skills are required for deploying production ML models and APIs.',
      'flutter': 'Flutter development is the fastest growing mobile framework in India.',
    };
    final key = skill.toLowerCase();
    return reasonMap[key] ??
        'AI recommends $skill as a high-impact skill for your $domain career path.';
  }
}
