import 'dart:async';
import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'ai_session_cache.dart';

class AIProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  final AISessionCache _sessionCache = AISessionCache();

  bool _isLoading = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _result;

  /// The full CandidateProfile from Python /resume/upload (shared cache).
  Map<String, dynamic>? _cachedProfile;
  String? _error;

  // ── Cold-start UX: phased loading messages ───────────────────────────────
  String _loadingMessage = 'Starting AI engine…';
  int _elapsedSeconds = 0;
  Timer? _loadingTimer;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get result => _result;
  Map<String, dynamic>? get cachedProfile => _cachedProfile;
  String? get error => _error;
  String get loadingMessage => _loadingMessage;
  int get elapsedSeconds => _elapsedSeconds;

  AIProvider() {
    initialize();
  }

  Future<void> initialize() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await _aiService.initializeModel();
      _isInitialized = _aiService.isInitialized;
    } catch (e) {
      _error = 'Failed to initialize AI Engine: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Phased loading message ticker ─────────────────────────────────────────
  void _startLoadingTimer() {
    _elapsedSeconds = 0;
    _loadingMessage = 'Waking up AI engine… this may take up to 60 s on first launch';
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _elapsedSeconds++;
      if (_elapsedSeconds < 8) {
        _loadingMessage = 'Uploading resume to AI engine…';
      } else if (_elapsedSeconds < 20) {
        _loadingMessage = 'Parsing resume — extracting skills & experience…';
      } else if (_elapsedSeconds < 40) {
        _loadingMessage =
            'Still warming up (Render free tier cold start)… hang tight!';
      } else if (_elapsedSeconds < 60) {
        _loadingMessage =
            'Almost there — computing career match score…';
      } else {
        _loadingMessage =
            'Taking longer than usual. Falling back to offline engine if needed…';
      }
      notifyListeners();
    });
  }

  void _stopLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
    _elapsedSeconds = 0;
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  /// Upload PDF bytes and analyze against a job description.
  /// Uses Python backend: /resume/upload → /career-twin/analyze.
  /// Falls back to native Dart engine if Render is slow/offline.
  Future<void> analyzeFromPdf({
    required Uint8List pdfBytes,
    required String filename,
    required String jdText,
    double requiredExpYears = 0.0,
  }) async {
    if (pdfBytes.isEmpty) {
      _error = 'No file selected.';
      notifyListeners();
      return;
    }
    if (jdText.trim().isEmpty) {
      _error = 'Please enter a job description.';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      _startLoadingTimer();
      notifyListeners();

      dev.log('[AIProvider] Step 1: Uploading PDF to AI engine…');

      // Step 1: Upload PDF → get CandidateProfile from Python (or local fallback)
      final uploadResult =
          await _aiService.uploadResumeBytes(pdfBytes, filename);
      final profile = uploadResult['profile'] as Map<String, dynamic>?;

      if (profile == null || profile.isEmpty) {
        _error = 'Resume parsing failed. Ensure the PDF has selectable text.';
        return;
      }

      // ── BUG 3 FIX: Normalize allSkills to lowercase before caching ──────
      // This ensures the downstream _getSkillOverlap set intersection works
      // correctly regardless of whether the Python server returns "Power BI"
      // or "power bi" — both map to the same canonical lowercase key.
      final rawSkills = profile['allSkills'] as List? ?? [];
      profile['allSkills'] = rawSkills
          .map((s) => s.toString().toLowerCase().trim())
          .toList();

      dev.log('[AIProvider] Skills after normalisation: ${profile['allSkills']}');

      _cachedProfile = profile;

      // Cache profile for other AI screens
      _sessionCache.storeProfile(
        profile: profile,
        uploadedFilename: filename,
        bytes: pdfBytes,
      );

      dev.log('[AIProvider] Step 2: Running Career Twin analysis…');

      // Step 2: Career Twin analysis using the parsed profile
      final analysisResult = await _aiService.analyzeCareerTwin(
        profile: profile,
        jdText: jdText,
        requiredExpYears: requiredExpYears,
      );

      _result = analysisResult;
      
      // Save atsScore to shared session cache for Alumni Skill screen
      final atsScore = (analysisResult['career_score']?['ats_score'] as num?)?.toDouble();
      final tier = analysisResult['career_score']?['tier']?.toString();
      if (atsScore != null) {
        _sessionCache.atsScore = atsScore;
        _sessionCache.atsReadinessLevel = tier;
      }

      dev.log('[AIProvider] Analysis complete in ${_elapsedSeconds}s');
    } catch (e, st) {
      dev.log('[AIProvider] analyzeFromPdf error: $e', stackTrace: st);
      _error = e.toString();
    } finally {
      _stopLoadingTimer();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Analyzes a pre-parsed profile (cached from a previous upload) against a JD.
  Future<void> analyzeFromProfile({
    required Map<String, dynamic> profile,
    required String jdText,
    double requiredExpYears = 0.0,
  }) async {
    if (jdText.trim().isEmpty) {
      _error = 'Please enter a job description.';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      _startLoadingTimer();
      notifyListeners();

      // Normalize cached profile skills too
      final rawSkills = profile['allSkills'] as List? ?? [];
      profile['allSkills'] = rawSkills
          .map((s) => s.toString().toLowerCase().trim())
          .toList();

      _cachedProfile = profile;

      final analysisResult = await _aiService.analyzeCareerTwin(
        profile: profile,
        jdText: jdText,
        requiredExpYears: requiredExpYears,
      );
      
      _result = analysisResult;

      // Save atsScore to shared session cache
      final atsScore = (analysisResult['career_score']?['ats_score'] as num?)?.toDouble();
      final tier = analysisResult['career_score']?['tier']?.toString();
      if (atsScore != null) {
        _sessionCache.atsScore = atsScore;
        _sessionCache.atsReadinessLevel = tier;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _stopLoadingTimer();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Analyzes raw profile text against a JD (text-based Career Twin flow).
  Future<void> analyze({
    required String profileText,
    required String jdText,
    double requiredExpYears = 0.0,
  }) async {
    if (profileText.trim().isEmpty) {
      _error = 'Please enter your profile or resume text.';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      _startLoadingTimer();
      notifyListeners();

      final res = await _aiService.analyzeInput(
        profileText: profileText,
        jdText: jdText,
        requiredExpYears: requiredExpYears,
      );
      _result = res;
    } catch (e) {
      _error = 'Analysis failed: ${e.toString()}';
    } finally {
      _stopLoadingTimer();
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _result = null;
    _cachedProfile = null;
    _error = null;
    _isLoading = false;
    _loadingMessage = 'Starting AI engine…';
    _stopLoadingTimer();
    notifyListeners();
  }
}
