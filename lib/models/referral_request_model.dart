import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralRequestModel {
  final String id;
  final String studentUid;
  final String studentName;
  final String? studentProfileImage;
  final String alumniUid;
  final String alumniName;
  final String jobId;
  final String jobTitle;
  final String company;
  final String resumeUrl;
  final String message;
  final bool isInterested;
  final String status; // 'pending' | 'accepted' | 'declined' | 'referral_submitted' | 'completed' | 'cancelled'
  final String? referralNote;
  final Timestamp? requestedAt;
  final Timestamp? updatedAt;

  ReferralRequestModel({
    required this.id,
    required this.studentUid,
    required this.studentName,
    this.studentProfileImage,
    required this.alumniUid,
    required this.alumniName,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.resumeUrl,
    required this.message,
    required this.isInterested,
    required this.status,
    this.referralNote,
    this.requestedAt,
    this.updatedAt,
  });

  factory ReferralRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return ReferralRequestModel(
      id: id,
      studentUid: map['studentUid'] ?? map['studentId'] ?? '',
      studentName: map['studentName'] ?? 'Student',
      studentProfileImage: map['studentProfileImage'],
      alumniUid: map['alumniUid'] ?? map['alumniId'] ?? '',
      alumniName: map['alumniName'] ?? 'Alumni',
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? 'Role',
      company: map['company'] ?? map['companyName'] ?? '',
      resumeUrl: map['resumeUrl'] ?? '',
      message: map['message'] ?? map['note'] ?? '',
      isInterested: map['isInterested'] ?? map['interested'] ?? true,
      status: map['status'] ?? 'pending',
      referralNote: map['referralNote'],
      requestedAt: map['requestedAt'] ?? map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'studentProfileImage': studentProfileImage,
      'alumniUid': alumniUid,
      'alumniName': alumniName,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'company': company,
      'resumeUrl': resumeUrl,
      'message': message,
      'isInterested': isInterested,
      'status': status,
      'referralNote': referralNote,
      'requestedAt': requestedAt,
      'updatedAt': updatedAt,
    };
  }
}
