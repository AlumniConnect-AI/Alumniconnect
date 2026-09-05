import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'meeting_service.dart';

class ReferralService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // 1. FIND SUITABLE ALUMNI FOR A JOB
  // Priorities:
  // 1. Job poster / Alumni working at the target company
  // 2. Alumni with relevant roles/skills
  // 3. Other verified alumni
  static Future<List<Map<String, dynamic>>> findSuitableAlumni({
    required String company,
    required String jobTitle,
    String? ownerId,
  }) async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'alumni')
          .get();

      final currentUid = _uid;
      final targetCompany = company.trim().toLowerCase();

      final List<Map<String, dynamic>> companyMatches = [];
      final List<Map<String, dynamic>> roleMatches = [];
      final List<Map<String, dynamic>> otherAlumni = [];

      for (var doc in snap.docs) {
        if (doc.id == currentUid) continue; // skip self
        final d = doc.data();
        d['id'] = doc.id;

        final userCompany = (d['company'] ?? d['organization'] ?? d['companyName'] ?? '')
            .toString()
            .toLowerCase();
        final userRole = (d['designation'] ?? d['jobTitle'] ?? d['roleTitle'] ?? '')
            .toString()
            .toLowerCase();

        final isPoster = ownerId != null && doc.id == ownerId;

        if (isPoster || (targetCompany.isNotEmpty && userCompany.contains(targetCompany))) {
          d['matchReason'] = isPoster ? 'Job Poster' : 'Works at $company';
          d['priority'] = 1;
          companyMatches.add(d);
        } else if (jobTitle.isNotEmpty &&
            userRole.contains(jobTitle.toLowerCase().split(' ').first)) {
          d['matchReason'] = 'Relevant Role: ${d['designation'] ?? userRole}';
          d['priority'] = 2;
          roleMatches.add(d);
        } else {
          d['matchReason'] = 'Verified Alumnus';
          d['priority'] = 3;
          otherAlumni.add(d);
        }
      }

      return [...companyMatches, ...roleMatches, ...otherAlumni];
    } catch (e) {
      dev.log('[ReferralService] findSuitableAlumni error: $e');
      return [];
    }
  }

  // 2. CHECK EXISTING ACTIVE REFERRAL REQUEST
  static Future<bool> hasActiveReferralRequest({
    required String jobId,
    required String alumniUid,
  }) async {
    try {
      final snap = await _db
          .collection('referral_requests')
          .where('studentUid', isEqualTo: _uid)
          .where('jobId', isEqualTo: jobId)
          .get();

      return snap.docs.any((d) {
        final data = d.data();
        final status = data['status']?.toString() ?? 'pending';
        return data['alumniUid'] == alumniUid &&
            (status == 'pending' || status == 'accepted' || status == 'referral_submitted');
      });
    } catch (_) {
      return false;
    }
  }

  // 3. SEND REFERRAL REQUEST
  static Future<void> sendReferralRequest({
    required String jobId,
    required String jobTitle,
    required String company,
    required String alumniUid,
    required String alumniName,
    required String resumeUrl,
    required String message,
    required bool isInterested,
  }) async {
    final uid = _uid;
    if (uid.isEmpty) throw Exception('User not authenticated');

    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};
    final studentName = userData['name']?.toString() ?? 'Student';
    final photoUrl = userData['photoURL']?.toString() ?? userData['profileImage']?.toString() ?? '';

    // Save referral request
    await _db.collection('referral_requests').add({
      'studentUid': uid,
      'studentName': studentName,
      'studentProfileImage': photoUrl,
      'alumniUid': alumniUid,
      'alumniName': alumniName,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'company': company,
      'resumeUrl': resumeUrl,
      'message': message.trim(),
      'isInterested': isInterested,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // In-app notification for alumni
    await NotificationService.sendNotification(
      toUserId: alumniUid,
      title: 'New Referral Request',
      body: '$studentName requested a referral for $jobTitle at $company.',
      data: {'type': 'referral_request', 'jobId': jobId},
    );

    // Post system message in 1-on-1 chat
    try {
      final chatId = await MeetingService.getOrCreateChat(alumniUid);
      final chatMsg = 'Referral Request for "$jobTitle" at $company: ${message.trim().isNotEmpty ? message.trim() : 'Requested a referral for this role.'}';
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': uid,
        'receiverId': alumniUid,
        'type': 'text',
        'text': chatMsg,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      dev.log('[ReferralService] Chat message log error: $e');
    }
  }

  // 4. UPDATE REFERRAL STATUS
  static Future<void> updateReferralStatus({
    required String requestId,
    required String newStatus, // 'accepted' | 'declined' | 'referral_submitted' | 'cancelled'
    String? referralNote,
  }) async {
    final docRef = _db.collection('referral_requests').doc(requestId);
    final snap = await docRef.get();
    if (!snap.exists) return;

    final data = snap.data() ?? {};
    final studentUid = data['studentUid']?.toString() ?? '';
    final alumniName = data['alumniName']?.toString() ?? 'Alumnus';
    final jobTitle = data['jobTitle']?.toString() ?? 'Role';
    final company = data['company']?.toString() ?? 'Company';

    await docRef.update({
      'status': newStatus,
      if (referralNote != null) 'referralNote': referralNote,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Notify student
    String notifTitle = 'Referral Request Updated';
    String notifBody = 'Your referral status for $jobTitle at $company has been updated to $newStatus.';

    if (newStatus == 'accepted') {
      notifTitle = 'Referral Accepted!';
      notifBody = '$alumniName accepted your referral request for $jobTitle at $company.';
    } else if (newStatus == 'declined') {
      notifTitle = 'Referral Request Declined';
      notifBody = '$alumniName declined your referral request for $jobTitle at $company.';
    } else if (newStatus == 'referral_submitted') {
      notifTitle = 'Referral Submitted!';
      notifBody = 'Your referral for $jobTitle at $company has been submitted by $alumniName.';
    }

    if (studentUid.isNotEmpty) {
      await NotificationService.sendNotification(
        toUserId: studentUid,
        title: notifTitle,
        body: notifBody,
        data: {'type': 'referral_update', 'requestId': requestId},
      );
    }
  }
}
