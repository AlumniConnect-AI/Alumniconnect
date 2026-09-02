import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ➕ Add event
  Future<void> addEvent(EventModel event) async {
    await _db.collection("events").add(event.toMap());
  }

  // 📥 Get all events
  Future<List<EventModel>> getEvents() async {
    final snap = await _db
        .collection("events")
        .orderBy("createdAt", descending: true)
        .get();

    return snap.docs
        .map((d) => EventModel.fromMap(d.data(), d.id))
        .toList();
  }

  // ✏️ Update event
  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _db.collection("events").doc(id).update(data);
  }

  // 🗑️ Delete event
  Future<void> deleteEvent(String id) async {
    await _db.collection("events").doc(id).delete();
  }
}
