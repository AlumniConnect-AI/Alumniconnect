/// AISessionCache — Singleton cache for the parsed resume profile.
///
/// Ensures resume is uploaded and parsed ONCE per session.
/// All AI screens (Career Twin, Career GPS, Alumni Skill) consume this cache
/// instead of uploading the resume again.
class AISessionCache {
  static final AISessionCache _instance = AISessionCache._internal();
  factory AISessionCache() => _instance;
  AISessionCache._internal();

  /// The parsed CandidateProfile JSON from /resume/upload
  Map<String, dynamic>? parsedProfile;

  /// Raw PDF bytes of the last uploaded resume
  List<int>? pdfBytes;

  /// Original filename of the uploaded resume
  String? filename;

  /// Timestamp of when the profile was parsed
  DateTime? parsedAt;

  /// Whether a valid parsed profile is cached
  bool get hasProfile => parsedProfile != null && parsedAt != null;

  /// Whether the cache is still fresh (< 30 minutes old)
  bool get isFresh {
    if (parsedAt == null) return false;
    return DateTime.now().difference(parsedAt!).inMinutes < 30;
  }

  /// Store a freshly parsed profile
  void storeProfile({
    required Map<String, dynamic> profile,
    required String uploadedFilename,
    List<int>? bytes,
  }) {
    parsedProfile = profile;
    filename = uploadedFilename;
    pdfBytes = bytes;
    parsedAt = DateTime.now();
  }

  /// Clear all cached data (e.g., when user resets or logs out)
  void clear() {
    parsedProfile = null;
    pdfBytes = null;
    filename = null;
    parsedAt = null;
  }

  // ── Convenience getters pulled from the cached profile ──────────────────────

  String get candidateName {
    final info = parsedProfile?['personalInfo'] as Map<String, dynamic>?;
    return info?['name']?.toString() ?? 'Candidate';
  }

  String get candidateDomain {
    return parsedProfile?['primaryDomain']?.toString() ?? 'Software Development';
  }

  double get candidateExperienceYears {
    return (parsedProfile?['totalExperienceYears'] as num?)?.toDouble() ?? 0.0;
  }

  int get candidateExperienceMonths {
    return (parsedProfile?['totalExperienceMonths'] as num?)?.toInt() ?? 0;
  }

  String get candidateExperienceDisplay {
    return parsedProfile?['experienceDisplay']?.toString() ??
        (candidateExperienceYears == 0.0
            ? 'Fresher (0 Years)'
            : '${candidateExperienceYears.toStringAsFixed(1)} Years');
  }

  List<String> get allSkills {
    final allSkills = parsedProfile?['allSkills'];
    if (allSkills is List) return List<String>.from(allSkills);
    // Flatten categorized skills dict
    final skills = parsedProfile?['skills'] as Map<String, dynamic>?;
    if (skills != null) {
      final flat = <String>[];
      for (final v in skills.values) {
        if (v is List) flat.addAll(v.map((s) => s.toString()));
      }
      return flat;
    }
    return [];
  }

  String get highestDegree {
    final edu = parsedProfile?['education'];
    if (edu is List && edu.isNotEmpty) {
      final first = edu.first as Map<String, dynamic>?;
      return first?['degree']?.toString() ?? 'Degree';
    }
    return 'Degree';
  }

  String get college {
    final edu = parsedProfile?['education'];
    if (edu is List && edu.isNotEmpty) {
      final first = edu.first as Map<String, dynamic>?;
      return first?['institution']?.toString() ?? '';
    }
    return '';
  }

  String get graduationYear {
    final edu = parsedProfile?['education'];
    if (edu is List && edu.isNotEmpty) {
      final first = edu.first as Map<String, dynamic>?;
      return first?['year']?.toString() ?? '';
    }
    return '';
  }

  String get currentRole {
    // Try to get from experience entries
    final exp = parsedProfile?['experience'];
    if (exp is List && exp.isNotEmpty) {
      final first = exp.first as Map<String, dynamic>?;
      return first?['role']?.toString() ?? 'Student';
    }
    return 'Student';
  }
}
