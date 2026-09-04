import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/alumni_skill_service.dart';
import 'ai_session_cache.dart';

class AlumniSkillProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  final AlumniSkillService _alumniSkillService = AlumniSkillService();
  final AISessionCache _cache = AISessionCache();

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  String? _uploadedPdfName;

  // ── Cold-start UX: phased loading messages ───────────────────────────────
  String _loadingMessage = 'Starting AI engine…';
  int _elapsedSeconds = 0;
  Timer? _loadingTimer;

  /// The full CandidateProfile JSON from /resume/upload
  Map<String, dynamic>? _parsedProfile;

  /// The unified analysis result: alumniMatches, mentorshipRecommendations, etc.
  Map<String, dynamic>? _result;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get uploadedPdfName => _uploadedPdfName;
  Map<String, dynamic>? get parsedProfile => _parsedProfile;
  Map<String, dynamic>? get result => _result;
  String get loadingMessage => _loadingMessage;
  int get elapsedSeconds => _elapsedSeconds;

  // ── Candidate Profile Getters ─────────────────────────────────────────────

  String get candidateName {
    final info = _parsedProfile?['personalInfo'] as Map<String, dynamic>?;
    return info?['name']?.toString() ?? 'Candidate';
  }

  String get candidateDegree {
    final edu = _parsedProfile?['education'];
    if (edu is List && edu.isNotEmpty) {
      final first = edu.first as Map<String, dynamic>?;
      return first?['degree']?.toString() ?? 'Degree';
    }
    return 'Degree';
  }

  String get candidateDomain {
    return _parsedProfile?['primaryDomain']?.toString() ?? 'Computer Science';
  }

  /// Returns experience as decimal years (e.g. 0.8 for 8 months)
  double get candidateExperience {
    return (_parsedProfile?['totalExperienceYears'] as num?)?.toDouble() ?? 0.0;
  }

  /// Returns experience in months
  int get candidateExperienceMonths {
    return (_parsedProfile?['totalExperienceMonths'] as num?)?.toInt() ?? 0;
  }

  /// Returns human-readable experience string (never shows 17 years for internships)
  String get candidateExperienceDisplay {
    // Prefer the display string computed by the Python backend
    final backendDisplay = _parsedProfile?['experienceDisplay']?.toString();
    if (backendDisplay != null && backendDisplay.isNotEmpty) {
      return backendDisplay;
    }
    // Local fallback calculation
    final years = candidateExperience;
    final months = candidateExperienceMonths;
    if (years == 0.0 && months == 0) return 'Fresher (0 Years)';
    if (months > 0 && months < 12) return '$months Months';
    if (years > 0 && years < 1.0) return '${(years * 12).round()} Months';
    return '${years.toStringAsFixed(1)} Years';
  }

  String get candidateCollege {
    final edu = _parsedProfile?['education'];
    if (edu is List && edu.isNotEmpty) {
      final first = edu.first as Map<String, dynamic>?;
      return first?['institution']?.toString() ?? '';
    }
    return '';
  }

  String get candidateGraduationYear {
    final edu = _parsedProfile?['education'];
    if (edu is List && edu.isNotEmpty) {
      final first = edu.first as Map<String, dynamic>?;
      return first?['year']?.toString() ?? '';
    }
    return '';
  }

  String get candidateCurrentRole {
    final exp = _parsedProfile?['experience'];
    if (exp is List && exp.isNotEmpty) {
      final first = exp.first as Map<String, dynamic>?;
      final role = first?['role']?.toString() ?? '';
      if (role.isNotEmpty) return role;
    }
    return 'Student';
  }

  double get resumeScore {
    if (_cache.atsScore != null) {
      return _cache.atsScore!;
    }
    final sgr = _result?['skillGapResult'] as Map<String, dynamic>?;
    return (sgr?['placement_readiness_score'] as num?)?.toDouble() ?? 0.0;
  }

  String get readinessLevel {
    if (_cache.atsReadinessLevel != null) {
      return _cache.atsReadinessLevel!;
    }
    final sgr = _result?['skillGapResult'] as Map<String, dynamic>?;
    return sgr?['readiness_level']?.toString() ?? '';
  }

  List<String> get extractedSkills {
    final allSkills = _parsedProfile?['allSkills'];
    if (allSkills is List) {
      return List<String>.from(allSkills);
    }
    // Flatten categorized skills
    final skills = _parsedProfile?['skills'] as Map<String, dynamic>?;
    if (skills != null) {
      final flat = <String>[];
      for (final v in skills.values) {
        if (v is List) flat.addAll(v.map((s) => s.toString()));
      }
      return flat;
    }
    return [];
  }

  /// Returns skills organized by category for neon chip display
  Map<String, List<String>> get skillsByCategory {
    final skills = _parsedProfile?['skills'];
    if (skills is Map) {
      return Map<String, List<String>>.fromEntries(
        (skills as Map<String, dynamic>).entries.map(
          (e) => MapEntry(
            e.key,
            e.value is List ? List<String>.from(e.value as List) : <String>[],
          ),
        ),
      );
    }
    return {};
  }

  AlumniSkillProvider() {
    initialize();
  }

  void _startLoadingTimer() {
    _elapsedSeconds = 0;
    _loadingMessage = 'Starting AI engine…';
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      if (_elapsedSeconds == 2) {
        _loadingMessage = 'Parsing PDF resume...';
      } else if (_elapsedSeconds == 6) {
        _loadingMessage = 'Fetching alumni network...';
      } else if (_elapsedSeconds == 10) {
        _loadingMessage = 'Running SBERT mentor match...';
      }
      notifyListeners();
    });
  }

  void _stopLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  Future<void> initialize() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _aiService.initializeModel();
      await _alumniSkillService.initializeModel();
      _isInitialized = _aiService.isInitialized && _alumniSkillService.isInitialized;
    } catch (e) {
      _error = 'Failed to initialize Alumni Skill AI: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// PRIMARY METHOD: Accepts raw PDF bytes from the file picker.
  ///
  /// Pipeline:
  ///   1. Check AISessionCache — if fresh profile already parsed, reuse it
  ///   2. Otherwise POST PDF to Python /resume/upload → CandidateProfile JSON
  ///   3. Cache the profile in AISessionCache for other screens
  ///   4. Run domain-aware skill gap analysis + SBERT mentor match
  Future<void> analyzeResumeBytes({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    if (pdfBytes.isEmpty) {
      _error = 'Selected file is empty.';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      _parsedProfile = null;
      _result = null;
      _uploadedPdfName = filename;
      _startLoadingTimer();
      notifyListeners();

      // ── Step 1: Get parsed profile (from cache or fresh upload) ──────────
      Map<String, dynamic>? profile;

      if (_cache.hasProfile &&
          _cache.isFresh &&
          !_cache.isOfflineFallback &&
          _cache.filename == filename) {
        // Reuse cached profile if same file and from live server
        profile = _cache.parsedProfile;
      } else {
        // Upload to Python server
        final uploadResult =
            await _aiService.uploadResumeBytes(pdfBytes, filename);
        profile = uploadResult['profile'] as Map<String, dynamic>?;

        if (profile == null) {
          _error = 'Resume parsing failed. Ensure the PDF has selectable text.';
          return;
        }

        // Cache for other screens
        _cache.storeProfile(
          profile: profile,
          uploadedFilename: filename,
          bytes: pdfBytes,
        );
      }

      _parsedProfile = profile;

      // ── Step 2: Validate skills extracted ──────────────────────────────
      final List<String> candidateSkills = extractedSkills;
      if (candidateSkills.isEmpty) {
        _error = 'No skills detected in your resume. Check that skills are listed clearly.';
        return;
      }

      // ── Step 3: Domain-aware skill gap + SBERT mentor match ────────────
      final matchResults = await _alumniSkillService.analyzeAndMatchAlumni(
        candidateSkills: candidateSkills,
        candidateDomain: candidateDomain,
        candidateExperience: candidateExperience,
        candidateProfile: profile!,  // non-null: guarded by early return above
        candidateName: candidateName,
      );

      if (matchResults.containsKey('error')) {
        _error = matchResults['error']?.toString();
        return;
      }

      _result = matchResults;
    } catch (e) {
      _error = e.toString();
    } finally {
      _stopLoadingTimer();
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _result = null;
    _parsedProfile = null;
    _uploadedPdfName = null;
    _error = null;
    _isLoading = false;
    _loadingMessage = 'Starting AI engine…';
    _stopLoadingTimer();
    notifyListeners();
  }
}
