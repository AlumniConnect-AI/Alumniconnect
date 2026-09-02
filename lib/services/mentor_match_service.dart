import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// MentorMatchService — Connects Flutter to the SBERT Mentor Match Engine.
///
/// Pipeline:
///   1. Fetch alumni from Firestore (with role filter)
///   2. If Firestore pool is empty, populate 5 Dummy Mentors (Demo Data)
///   3. POST candidate profile + alumni pool to /mentor-match/analyze
///   4. Receive SBERT-ranked results (cosine similarity + AI explanations)
///   5. Return enriched match list for the UI
class MentorMatchService {
  static final MentorMatchService _instance = MentorMatchService._internal();
  factory MentorMatchService() => _instance;
  MentorMatchService._internal();

  String get apiBaseUrl => ApiConfig.baseUrl;

  /// Returns 5 curated dummy mentor profiles clearly labeled for UI fallback.
  List<Map<String, dynamic>> getDummyMentors() {
    return [
      {
        'uid': 'dummy_1',
        'name': 'Priya S. (Demo Data)',
        'company': 'Zoho',
        'designation': 'Senior Data Analyst',
        'department': 'Data Analytics & BI',
        'skills': ['Python', 'SQL', 'Power BI', 'Microsoft Fabric'],
        'interests': ['Data Analytics', 'BI Dashboards', 'SQL Optimization'],
        'bio': 'Dummy Mentor (Demo Data) — Senior Data Analyst at Zoho with 3+ years experience.',
        'graduation_year': '2021 BCA Alumni',
        'experience_years': 3.5,
        'photo_url': null,
        'is_demo': true,
      },
      {
        'uid': 'dummy_2',
        'name': 'Arun K. (Demo Data)',
        'company': 'Freshworks',
        'designation': 'Flutter Developer',
        'department': 'Mobile App Development',
        'skills': ['Flutter', 'Firebase', 'Dart'],
        'interests': ['Mobile Apps', 'Cross-Platform', 'State Management'],
        'bio': 'Dummy Mentor (Demo Data) — Mobile App Architect at Freshworks specializing in Flutter & Firebase.',
        'graduation_year': '2022 MCA Alumni',
        'experience_years': 2.5,
        'photo_url': null,
        'is_demo': true,
      },
      {
        'uid': 'dummy_3',
        'name': 'Kavya M. (Demo Data)',
        'company': 'TCS',
        'designation': 'AI Engineer',
        'department': 'AI / Machine Learning',
        'skills': ['Python', 'TensorFlow', 'NLP'],
        'interests': ['Machine Learning', 'Natural Language Processing', 'Deep Learning'],
        'bio': 'Dummy Mentor (Demo Data) — AI Specialist at TCS building NLP and Deep Learning models.',
        'graduation_year': '2020 B.Tech',
        'experience_years': 4.0,
        'photo_url': null,
        'is_demo': true,
      },
      {
        'uid': 'dummy_4',
        'name': 'Sanjay R. (Demo Data)',
        'company': 'Infosys',
        'designation': 'Cloud Engineer',
        'department': 'Cloud Engineering',
        'skills': ['Azure', 'Docker', 'Kubernetes'],
        'interests': ['Cloud Architecture', 'DevOps', 'Microservices'],
        'bio': 'Dummy Mentor (Demo Data) — Cloud Infrastructure Architect at Infosys.',
        'graduation_year': '2019 B.Tech',
        'experience_years': 5.0,
        'photo_url': null,
        'is_demo': true,
      },
      {
        'uid': 'dummy_5',
        'name': 'Divya P. (Demo Data)',
        'company': 'Cognizant',
        'designation': 'BI Developer',
        'department': 'Data Analytics & BI',
        'skills': ['SQL', 'Tableau', 'Power BI'],
        'interests': ['Business Intelligence', 'Data Visualization', 'Data Warehousing'],
        'bio': 'Dummy Mentor (Demo Data) — BI Developer at Cognizant building enterprise reporting solutions.',
        'graduation_year': '2021 BCA Alumni',
        'experience_years': 3.0,
        'photo_url': null,
        'is_demo': true,
      },
    ];
  }

  /// Fetches alumni from Firestore and runs SBERT mentor matching.
  ///
  /// [candidateProfile]  — Full CandidateProfile JSON from /resume/upload
  /// [topK]              — Number of top mentors to return
  ///
  /// Returns: List of ranked mentor match maps with AI explanations.
  Future<Map<String, dynamic>> findMentors({
    required Map<String, dynamic> candidateProfile,
    int topK = 5,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // ── Step 1: Fetch alumni from Firestore (5-second timeout to avoid hangs) ──
    List<Map<String, dynamic>> alumniPool = [];
    try {
      // Try with 'role' field first (5s timeout), then fallback to 'userType'
      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'alumni')
            .get()
            .timeout(const Duration(seconds: 5));
        if (snapshot.docs.isEmpty) {
          snapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('userType', isEqualTo: 'alumni')
              .get()
              .timeout(const Duration(seconds: 5));
        }
      } catch (_) {
        snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: 'alumni')
            .get()
            .timeout(const Duration(seconds: 5));
      }

      for (final doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;
        final data = doc.data() as Map<String, dynamic>;

        // Parse skills from various Firestore formats
        List<String> skills = [];
        final rawSkills = data['skills'];
        if (rawSkills is List) {
          skills = List<String>.from(rawSkills.map((s) => s.toString()));
        } else if (rawSkills is String && rawSkills.isNotEmpty) {
          skills = rawSkills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        }

        // Fallback: infer skills from text if alumni profile has no skills field
        if (skills.isEmpty) {
          final designation = data['designation']?.toString() ?? '';
          final department = data['department']?.toString() ?? '';
          final company = data['company']?.toString() ?? '';
          final inferText = '$designation $department $company'.toLowerCase();
          const knownSkills = [
            'flutter', 'dart', 'python', 'java', 'sql', 'react', 'aws', 'docker',
            'machine learning', 'power bi', 'data analytics', 'tableau', 'azure',
            'nodejs', 'mongodb', 'postgresql', 'tensorflow', 'pytorch', 'devops', 'gcp',
          ];
          for (final s in knownSkills) {
            if (inferText.contains(s)) skills.add(s);
          }
        }

        List<String> interests = [];
        final rawInterests = data['interests'];
        if (rawInterests is List) {
          interests = List<String>.from(rawInterests.map((i) => i.toString()));
        }

        // Parse graduation year
        String gradYear = '';
        final rawGrad = data['graduationYear'] ?? data['graduation_year'] ?? data['batch'];
        if (rawGrad != null) gradYear = rawGrad.toString();

        double expYears = 0.0;
        final rawExp = data['experience'] ?? data['experienceYears'] ?? data['experience_years'];
        if (rawExp != null) expYears = double.tryParse(rawExp.toString()) ?? 0.0;

        alumniPool.add({
          'uid': doc.id,
          'name': data['name']?.toString() ?? 'Alumni',
          'company': data['company']?.toString() ?? '',
          'designation': data['designation']?.toString() ?? data['role']?.toString() ?? '',
          'department': data['department']?.toString() ?? '',
          'skills': skills,
          'interests': interests,
          'bio': data['bio']?.toString() ?? data['about']?.toString() ?? '',
          'graduation_year': gradYear,
          'experience_years': expYears,
          'photo_url': data['photoURL']?.toString() ?? data['profileImage']?.toString(),
          'is_demo': false,
        });
      }
    } catch (_) {
      // Ignore Firestore query errors and use dummy mentor fallback below
    }

    // Populate dummy mentors if Firestore returned no alumni
    if (alumniPool.isEmpty) {
      alumniPool = getDummyMentors();
    }

    // ── Step 2: POST to SBERT Mentor Match Engine ────────────────────────────
    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/mentor-match/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'candidate_profile': candidateProfile,
              'alumni_pool': alumniPool
                  .map((a) => {
                        'uid': a['uid'],
                        'name': a['name'],
                        'company': a['company'],
                        'designation': a['designation'],
                        'department': a['department'],
                        'skills': a['skills'],
                        'interests': a['interests'],
                        'bio': a['bio'],
                        'graduation_year': a['graduation_year'],
                        'experience_years': a['experience_years'],
                      })
                  .toList(),
              'top_k': topK,
            }),
          )
          .timeout(ApiConfig.analyzeTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final matches = data['mentor_matches'] as List? ?? [];

          // Enrich results with Firestore photo URLs (not sent to Python)
          final enriched = matches.map((m) {
            final uid = m['uid']?.toString() ?? '';
            final alumniData = alumniPool.firstWhere(
              (a) => a['uid'] == uid,
              orElse: () => <String, dynamic>{},
            );
            return {
              ...m as Map<String, dynamic>,
              'photoUrl': alumniData['photo_url'],
              'graduationYear': alumniData['graduation_year'] ?? '',
            };
          }).toList();

          return {
            'mentor_matches': enriched,
            'total_evaluated': data['total_evaluated'] ?? alumniPool.length,
            'alumni_pool': alumniPool,
          };
        }
      }

      // If SBERT endpoint unavailable, fall back to Jaccard overlap ranking
      return _fallbackJaccardRanking(candidateProfile, alumniPool, topK);
    } on TimeoutException {
      return _fallbackJaccardRanking(candidateProfile, alumniPool, topK);
    } on http.ClientException {
      return _fallbackJaccardRanking(candidateProfile, alumniPool, topK);
    } catch (_) {
      return _fallbackJaccardRanking(candidateProfile, alumniPool, topK);
    }
  }

  /// Fallback: rank alumni by simple Jaccard skill overlap when SBERT is unavailable.
  Map<String, dynamic> _fallbackJaccardRanking(
    Map<String, dynamic> candidateProfile,
    List<Map<String, dynamic>> alumniPool,
    int topK,
  ) {
    final candidateSkills = (candidateProfile['allSkills'] as List? ?? [])
        .map((s) => s.toString().toLowerCase().trim())
        .toSet();

    final ranked = alumniPool.map((alum) {
      final alumSkills = (alum['skills'] as List? ?? [])
          .map((s) => s.toString().toLowerCase().trim())
          .toSet();

      final matched = candidateSkills.intersection(alumSkills).toList();
      final matchPct = candidateSkills.isEmpty
          ? 0.0
          : (matched.length / candidateSkills.length * 100.0).clamp(0.0, 100.0);

      return {
        'uid': alum['uid'],
        'name': alum['name'],
        'company': alum['company'],
        'role': alum['designation'],
        'department': alum['department'],
        'career_domain': alum['department'],
        'experience_years': alum['experience_years'],
        'similarity_score': matchPct / 100.0,
        'match_percentage': double.parse(matchPct.toStringAsFixed(1)),
        'matched_skills': matched,
        'match_reasons': matched.isNotEmpty
            ? ['Shared expertise in ${matched.take(3).join(', ')}']
            : ['Alumni from ${alum['department']} department'],
        'photoUrl': alum['photo_url'],
        'graduationYear': alum['graduation_year'] ?? '',
        'rank': 0,
      };
    }).toList();

    ranked.sort((a, b) =>
        (b['match_percentage'] as num).compareTo(a['match_percentage'] as num));

    for (int i = 0; i < ranked.length; i++) {
      ranked[i]['rank'] = i + 1;
    }

    return {
      'mentor_matches': ranked.take(topK).toList(),
      'total_evaluated': alumniPool.length,
      'alumni_pool': alumniPool,
      'fallback_mode': true,
    };
  }
}
