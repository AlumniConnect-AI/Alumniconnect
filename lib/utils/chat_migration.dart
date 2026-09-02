import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> fixChatLastMessageTime() async {
  final chats = await FirebaseFirestore.instance.collection('chats').get();

  for (var d in chats.docs) {
    final data = d.data();
    if (!data.containsKey('lastMessageTime') || data['lastMessageTime'] == null) {
      await d.reference.update({
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
  }
}
