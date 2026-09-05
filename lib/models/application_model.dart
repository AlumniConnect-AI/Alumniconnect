import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String id;
  final String studentUid;
  final String jobId;
  final String jobTitle;
  final String company;
  final String resumeUrl;
  final String resumeName;
  final bool isInterested;
  final String status; // 'submitted' | 'under_review' | 'shortlisted' | 'rejected' | 'hired'
  final Timestamp? appliedAt;

  ApplicationModel({
    required this.id,
    required this.studentUid,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.resumeUrl,
    required this.resumeName,
    required this.isInterested,
    required this.status,
    this.appliedAt,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    return ApplicationModel(
      id: id,
      studentUid: map['studentUid'] ?? map['userId'] ?? '',
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? map['designation'] ?? 'Job',
      company: map['company'] ?? '',
      resumeUrl: map['resumeUrl'] ?? '',
      resumeName: map['resumeName'] ?? 'Resume.pdf',
      isInterested: map['isInterested'] ?? map['interested'] ?? true,
      status: map['status'] ?? 'submitted',
      appliedAt: map['appliedAt'] ?? map['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'company': company,
      'resumeUrl': resumeUrl,
      'resumeName': resumeName,
      'isInterested': isInterested,
      'status': status,
      'appliedAt': appliedAt,
    };
  }
}
