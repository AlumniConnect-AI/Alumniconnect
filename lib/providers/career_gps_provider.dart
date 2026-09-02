import 'package:flutter/material.dart';
import '../services/career_gps_service.dart';

class CareerGPSProvider extends ChangeNotifier {
  final CareerGPSService _gpsService = CareerGPSService();

  bool _isLoading = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _roadmap;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get roadmap => _roadmap;
  String? get error => _error;

  CareerGPSProvider() {
    initialize();
  }

  Future<void> initialize() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _gpsService.initializeModel();
      _isInitialized = _gpsService.isInitialized;
    } catch (e) {
      _error = 'Failed to initialize Career GPS Engine: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateRoadmap({
    required String targetRole,
    required String currentSkills,
    String education = 'Bachelors',
    double experienceYears = 1.0,
  }) async {
    if (targetRole.trim().isEmpty) {
      _error = 'Please select a target career role.';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final res = await _gpsService.generateRoadmap(
        targetRole: targetRole,
        currentSkillsText: currentSkills,
        education: education,
        experienceYears: experienceYears,
      );

      _roadmap = res;
    } catch (e) {
      _error = 'Roadmap generation failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _roadmap = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
