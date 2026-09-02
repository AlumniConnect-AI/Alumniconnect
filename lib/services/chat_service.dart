import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ================= SEND TEXT =================
  static Future<void> sendText({
    required String chatId,
    required String receiverId,
    required String text,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);

    // 1. Update/Create the chat document metadata
    await chatRef.set({
      'participants': FieldValue.arrayUnion([_uid, receiverId]),
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Increment unread count for the receiver using dot notation
    await chatRef.update({
      'unreadCount.$receiverId': FieldValue.increment(1),
    }).catchError((_) {
      // If unreadCount field doesn't exist yet, initialize it
      return chatRef.set({
        'unreadCount': {receiverId: 1}
      }, SetOptions(merge: true));
    });

    // 3. Add the actual message to the sub-collection
    await chatRef.collection('messages').add({
      'senderId': _uid,
      'receiverId': receiverId,
      'type': 'text',
      'text': text,
      'fileUrl': null,
      'fileName': null,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= SEND FILE/IMAGE =================
  static Future<void> sendFile({
    required String chatId,
    required String receiverId,
    required String fileUrl,
    required String fileName,
    required String type, // image | file
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);

    final String displayMsg = type == 'image' ? '📷 Image' : '📄 Document';

    await chatRef.set({
      'participants': FieldValue.arrayUnion([_uid, receiverId]),
      'lastMessage': displayMsg,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.update({
      'unreadCount.$receiverId': FieldValue.increment(1),
    }).catchError((_) {
      return chatRef.set({
        'unreadCount': {receiverId: 1}
      }, SetOptions(merge: true));
    });

    await chatRef.collection('messages').add({
      'senderId': _uid,
      'receiverId': receiverId,
      'type': type,
      'text': null,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= DELETE MESSAGE =================
  static Future<void> deleteMessage(String chatId, String messageId) async {
    final chatRef = _db.collection('chats').doc(chatId);
    await chatRef.collection('messages').doc(messageId).delete();

    // Update last message summary
    final lastMessages = await chatRef
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (lastMessages.docs.isNotEmpty) {
      final lastData = lastMessages.docs.first.data();
      String lastMsg = "";
      if (lastData['type'] == 'text') {
        lastMsg = lastData['text'] ?? "";
      } else if (lastData['type'] == 'image') {
        lastMsg = "📷 Image";
      } else {
        lastMsg = "📄 Document";
      }

      await chatRef.update({
        'lastMessage': lastMsg,
        'lastMessageTime': lastData['createdAt'],
      });
    } else {
      await chatRef.update({
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
  }

  // ================= DELETE CHAT =================
  static Future<void> deleteChat(String chatId) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final messages = await chatRef.collection('messages').get();
    
    final batch = _db.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(chatRef);
    await batch.commit();
  }

  // ================= MESSAGE STREAM =================
  static Stream<QuerySnapshot> messages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ================= MARK AS READ =================
  static Future<void> markRead(String chatId) async {
    final chatRef = _db.collection('chats').doc(chatId);

    // Reset unread count for current user
    await chatRef.update({
      'unreadCount.$_uid': 0,
    }).catchError((_) => Future.value());

    // Mark messages as read
    final snap = await chatRef
        .collection('messages')
        .where('receiverId', isEqualTo: _uid)
        .where('isRead', isEqualTo: false)
        .get();

    if (snap.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.update(d.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }
}
