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

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get result => _result;
  Map<String, dynamic>? get cachedProfile => _cachedProfile;
  String? get error => _error;

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

  /// Upload PDF bytes and analyze against a job description.
  /// Uses Python backend: /resume/upload → /career-twin/analyze.
  /// Never uses hardcoded sample profiles.
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
      notifyListeners();

      // Step 1: Upload PDF → get CandidateProfile from Python
      final uploadResult = await _aiService.uploadResumeBytes(pdfBytes, filename);
      final profile = uploadResult['profile'] as Map<String, dynamic>?;

      if (profile == null || profile.isEmpty) {
        _error = 'Resume parsing failed. Ensure the PDF has selectable text.';
        return;
      }
      _cachedProfile = profile;

      // Cache profile for other AI screens (Career GPS, Alumni Skill Matcher)
      _sessionCache.storeProfile(
        profile: profile,
        uploadedFilename: filename,
        bytes: pdfBytes,
      );


      // Step 2: Career Twin analysis using the parsed profile
      final analysisResult = await _aiService.analyzeCareerTwin(
        profile: profile,
        jdText: jdText,
        requiredExpYears: requiredExpYears,
      );

      _result = analysisResult;
    } catch (e) {
      _error = e.toString();
    } finally {
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
      notifyListeners();

      _cachedProfile = profile;
      final analysisResult = await _aiService.analyzeCareerTwin(
        profile: profile,
        jdText: jdText,
        requiredExpYears: requiredExpYears,
      );
      _result = analysisResult;
    } catch (e) {
      _error = e.toString();
    } finally {
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
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _result = null;
    _cachedProfile = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
