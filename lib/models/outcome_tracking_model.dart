import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents one placement check-in entry inside outcome_tracking/{uid}.checkIns
class CheckInEntry {
  final Timestamp date;
  final String status;
  final String? employmentType;
  final String? employerName;
  final String? note;
  final bool verified;

  CheckInEntry({
    required this.date,
    required this.status,
    this.employmentType,
    this.employerName,
    this.note,
    this.verified = false,
  });

  factory CheckInEntry.fromMap(Map<String, dynamic> map) {
    return CheckInEntry(
      date: map['date'] as Timestamp? ?? Timestamp.now(),
      status: map['status'] ?? '',
      employmentType: map['employmentType'] as String?,
      employerName: map['employerName'] as String?,
      note: map['note'] as String?,
      verified: map['verified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'status': status,
      'employmentType': employmentType,
      'employerName': employerName,
      'note': note,
      'verified': verified,
    };
  }
}

/// outcome_tracking/{uid} — one document per user for their entire lifetime
///
/// status values: "trained" | "placed" | "retained_3mo" | "retained_6mo"
///               | "retained_12mo" | "dropped_off"
class OutcomeTrackingModel {
  final String uid;
  final String status;
  final Timestamp? placementDate;
  final String? employmentType; // "formal" | "self_employed" | "apprenticeship" | "unemployed"
  final String? employerName;
  final String? nonPlacementReason;
  final List<CheckInEntry> checkIns;

  OutcomeTrackingModel({
    required this.uid,
    required this.status,
    this.placementDate,
    this.employmentType,
    this.employerName,
    this.nonPlacementReason,
    this.checkIns = const [],
  });

  factory OutcomeTrackingModel.fromMap(Map<String, dynamic> map, String uid) {
    final rawCheckIns = map['checkIns'] as List<dynamic>? ?? [];
    return OutcomeTrackingModel(
      uid: uid,
      status: map['status'] ?? 'trained',
      placementDate: map['placementDate'] as Timestamp?,
      employmentType: map['employmentType'] as String?,
      employerName: map['employerName'] as String?,
      nonPlacementReason: map['nonPlacementReason'] as String?,
      checkIns: rawCheckIns
          .map((e) => CheckInEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'placementDate': placementDate,
      'employmentType': employmentType,
      'employerName': employerName,
      'nonPlacementReason': nonPlacementReason,
      'checkIns': checkIns.map((e) => e.toMap()).toList(),
    };
  }

  /// The ordered stages for the Retention Timeline widget
  static const List<String> stages = [
    'trained',
    'placed',
    'retained_3mo',
    'retained_6mo',
    'retained_12mo',
  ];

  /// Returns the 0-based index of current status in [stages].
  /// Returns -1 if status is 'dropped_off' or unknown.
  int get stageIndex {
    return stages.indexOf(status);
  }

  bool get isDroppedOff => status == 'dropped_off';
}
