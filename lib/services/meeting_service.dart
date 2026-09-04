import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles mentor connection requests and meeting scheduling.
///
/// Collections used:
///   mentor_requests/{reqId}  — connection/mentorship requests
///   meetings/{meetingId}     — scheduled meetings
///   chats/{chatId}/messages  — system messages for meeting confirmations
class MeetingService {
  static final _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── 1. SEND CONNECTION REQUEST ──────────────────────────────────────────────

  /// Sends a mentorship connection request from the current user to [mentorUid].
  /// Returns false if a pending/accepted request already exists.
  static Future<bool> sendConnectionRequest({
    required String mentorUid,
    required String mentorName,
  }) async {
    try {
      // Check for existing request to prevent duplicates
      final existing = await _db
          .collection('mentor_requests')
          .where('studentUid', isEqualTo: _uid)
          .where('mentorUid', isEqualTo: mentorUid)
          .where('status', whereIn: ['pending', 'accepted'])
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) return false; // already exists

      await _db.collection('mentor_requests').add({
        'studentUid': _uid,
        'mentorUid': mentorUid,
        'mentorName': mentorName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      dev.log('[MeetingService] Connection request sent → mentorUid=$mentorUid');
      return true;
    } catch (e) {
      dev.log('[MeetingService] sendConnectionRequest error: $e');
      rethrow;
    }
  }

  /// Returns true if there is already a pending or accepted request from
  /// the current user to [mentorUid].
  static Future<bool> hasExistingRequest(String mentorUid) async {
    try {
      final snap = await _db
          .collection('mentor_requests')
          .where('studentUid', isEqualTo: _uid)
          .where('mentorUid', isEqualTo: mentorUid)
          .where('status', whereIn: ['pending', 'accepted'])
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── 2. GET OR CREATE CHAT ───────────────────────────────────────────────────

  /// Returns the chatId for a 1:1 conversation between current user and [peerId].
  /// Creates the chat document if it doesn't exist yet.
  /// Chat IDs are deterministic: smaller UID first, joined with underscore.
  static Future<String> getOrCreateChat(String peerId) async {
    final uid = _uid;
    // Deterministic chatId: always smaller UID first
    final chatId = uid.compareTo(peerId) < 0
        ? '${uid}_$peerId'
        : '${peerId}_$uid';

    final chatRef = _db.collection('chats').doc(chatId);
    final snap = await chatRef.get();

    if (!snap.exists) {
      await chatRef.set({
        'participants': [uid, peerId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      dev.log('[MeetingService] Created chat chatId=$chatId');
    }

    return chatId;
  }

  // ── 3. SCHEDULE MEETING ─────────────────────────────────────────────────────

  /// Schedules a meeting between the current user and [peerId].
  /// Writes to meetings/ collection and posts a system message in the chat.
  static Future<void> scheduleMeeting({
    required String peerId,
    required String chatId,
    required DateTime scheduledDateTime,
    required String title,
    String? agenda,
  }) async {
    final uid = _uid;

    // Write to meetings collection
    final meetingRef = await _db.collection('meetings').add({
      'participants': [uid, peerId],
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'title': title.trim().isEmpty ? 'Mentorship Meeting' : title.trim(),
      'agenda': agenda?.trim(),
      'createdBy': uid,
      'status': 'scheduled',
      'createdAt': FieldValue.serverTimestamp(),
    });

    dev.log('[MeetingService] Meeting scheduled: ${meetingRef.id}');

    // Post a system message in the chat thread
    final dateStr = _formatDateTime(scheduledDateTime);
    final systemMsg =
        '📅 Meeting scheduled: "${title.trim().isEmpty ? 'Mentorship Meeting' : title.trim()}" on $dateStr';

    final chatRef = _db.collection('chats').doc(chatId);
    await chatRef.set({
      'participants': FieldValue.arrayUnion([uid, peerId]),
      'lastMessage': systemMsg,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'senderId': 'system',
      'receiverId': null,
      'type': 'system',
      'text': systemMsg,
      'meetingId': meetingRef.id,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns a stream of upcoming meetings for the current user.
  static Stream<QuerySnapshot> upcomingMeetingsStream() {
    return _db
        .collection('meetings')
        .where('participants', arrayContains: _uid)
        .where('status', isEqualTo: 'scheduled')
        .orderBy('scheduledDateTime')
        .snapshots();
  }

  /// Returns meetings for any specific chat participant pair.
  static Future<List<Map<String, dynamic>>> getMeetingsForPair(
      String peerId) async {
    final uid = _uid;
    final snap = await _db
        .collection('meetings')
        .where('participants', arrayContains: uid)
        .where('status', whereIn: ['scheduled', 'completed'])
        .orderBy('scheduledDateTime', descending: true)
        .limit(5)
        .get();
    return snap.docs
        .where((d) {
          final p = List<String>.from(d['participants'] ?? []);
          return p.contains(peerId);
        })
        .map((d) => {...d.data(), 'id': d.id})
        .toList();
  }

  static String _formatDateTime(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.day} ${months[dt.month]} ${dt.year} at $hour:$minute $ampm';
  }
}
