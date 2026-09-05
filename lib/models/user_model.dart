import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String batch;
  final String department;
  final String company;
  final String designation;
  final bool profileCompleted;
  final String? photoUrl;
  final String? linkedin;

  // EduBridge add-on fields
  final int? graduationYear;
  final bool consentGiven;
  final Timestamp? consentTimestamp;
  final String verificationStatus; // "verified" | "pending" | ""
  final Map<String, dynamic> engagementStats;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.batch,
    required this.department,
    required this.company,
    required this.designation,
    required this.profileCompleted,
    this.photoUrl,
    this.linkedin,
    this.graduationYear,
    this.consentGiven = false,
    this.consentTimestamp,
    this.verificationStatus = '',
    this.engagementStats = const {},
  });

  // Firestore → Model
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      batch: map['batch'] ?? '',
      department: map['department'] ?? '',
      company: map['company'] ?? '',
      designation: map['designation'] ?? '',
      profileCompleted: map['profileCompleted'] ?? false,
      photoUrl: map['photoURL'],
      linkedin: map['linkedin'],
      graduationYear: map['graduationYear'] as int?,
      consentGiven: map['consentGiven'] ?? false,
      consentTimestamp: map['consentTimestamp'] as Timestamp?,
      verificationStatus: map['verificationStatus'] ?? '',
      engagementStats:
          (map['engagementStats'] as Map<String, dynamic>?) ?? {},
    );
  }

  // Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'batch': batch,
      'department': department,
      'company': company,
      'designation': designation,
      'profileCompleted': profileCompleted,
      'photoURL': photoUrl,
      'linkedin': linkedin,
      'graduationYear': graduationYear,
      'consentGiven': consentGiven,
      'consentTimestamp': consentTimestamp,
      'verificationStatus': verificationStatus,
      'engagementStats': engagementStats,
    };
  }
}
