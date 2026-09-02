import 'package:firebase_auth/firebase_auth.dart';

class ChatUtils {
  static String getChatId(String otherUserId) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return uid.compareTo(otherUserId) < 0
        ? "${uid}_$otherUserId"
        : "${otherUserId}_$uid";
  }
}
