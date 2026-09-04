import 'package:cloud_firestore/cloud_firestore.dart';

/// referrals/{referralId} — posted by alumni, surfaced in student Jobs tab
class ReferralModel {
  final String referralId;
  final String postedByUid;
  final String title;
  final String companyName;
  final String type; // "job" | "internship" | "referral"
  final String description;
  final Timestamp? postedAt;

  ReferralModel({
    required this.referralId,
    required this.postedByUid,
    required this.title,
    required this.companyName,
    required this.type,
    required this.description,
    this.postedAt,
  });

  factory ReferralModel.fromMap(Map<String, dynamic> map, String id) {
    return ReferralModel(
      referralId: id,
      postedByUid: map['postedByUid'] ?? '',
      title: map['title'] ?? '',
      companyName: map['companyName'] ?? '',
      type: map['type'] ?? 'referral',
      description: map['description'] ?? '',
      postedAt: map['postedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postedByUid': postedByUid,
      'title': title,
      'companyName': companyName,
      'type': type,
      'description': description,
      'postedAt': postedAt,
    };
  }
}
