import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/theme.dart';
import 'event_detail_screen.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // ================= STATUS =================
  String _status(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return "OPEN";
    return d.isBefore(DateTime.now()) ? "CLOSED" : "OPEN";
  }

  Color _statusBg(String s) =>
      s == "OPEN" ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15);

  Color _statusText(String s) => s == "OPEN" ? Colors.green : Colors.red;

  // ================= DELETE =================
  Future<bool> _confirmDelete(String id) async {
    final theme = Theme.of(context);
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text("Delete Event"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
              const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (res == true) {
      await FirebaseFirestore.instance.collection('events').doc(id).delete();
      return true;
    }
    return false;
  }

  // ================= ADD / EDIT =================
  void _openDialog({DocumentSnapshot? event}) async {
    final theme = Theme.of(context);
    final d = event?.data() as Map<String, dynamic>?;

    final title = TextEditingController(text: d?['title'] ?? "");
    final date = TextEditingController(text: d?['date'] ?? "");
    final time = TextEditingController(text: d?['time'] ?? "");
    final location = TextEditingController(text: d?['location'] ?? "");
    final type = TextEditingController(text: d?['type'] ?? "");
    final desc = TextEditingController(text: d?['description'] ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(event == null ? "Add Event" : "Edit Event"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _input("Title", title, context),
              _input("Date (YYYY-MM-DD)", date, context),
              _input("Time", time, context),
              _input("Location", location, context),
              _input("Type", type, context),
              _input("Description", desc, context, max: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () async {
              final userSnap = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get();

              final data = {
                'title': title.text.trim(),
                'date': date.text.trim(),
                'time': time.text.trim(),
                'location': location.text.trim(),
                'type': type.text.trim(),
                'description': desc.text.trim(),
                'ownerId': uid,
                'ownerName': userSnap.data()?['name'] ?? "Alumni",
                'createdAt': FieldValue.serverTimestamp(),
              };

              if (event == null) {
                await FirebaseFirestore.instance.collection('events').add(data);
              } else {
                await FirebaseFirestore.instance
                    .collection('events')
                    .doc(event.id)
                    .update(data);
              }

              Navigator.pop(context);
            },
            child: Text(event == null ? "Post Event" : "Update Event",
                style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("My Events"), centerTitle: true),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('ownerId', isEqualTo: uid)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(
                child:
                CircularProgressIndicator(color: AppColors.primary));
          }

          if (snap.data!.docs.isEmpty) {
            return Center(
              child: Text("No events posted",
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: snap.data!.docs.map((e) {
              final d = e.data() as Map<String, dynamic>;
              final status = _status(d['date'] ?? "");

              return Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.horizontal,
                confirmDismiss: (dir) async {
                  if (dir == DismissDirection.startToEnd) {
                    return await _confirmDelete(e.id);
                  } else {
                    _openDialog(event: e);
                    return false;
                  }
                },
                background:
                _bg(Icons.delete, Colors.red, Alignment.centerLeft),
                secondaryBackground:
                _bg(Icons.edit, AppColors.primary, Alignment.centerRight),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EventDetailScreen(eventId: e.id),
                    ),
                  ),
                  child: _card(
                    d['title'],
                    "${d['date']} • ${d['time']} • ${d['location']}",
                    status,
                    context,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ================= HELPERS =================
  static Widget _input(String h, TextEditingController c, BuildContext context, {int max = 1}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: max,
        decoration: InputDecoration(
          hintText: h,
          filled: true,
          fillColor: theme.scaffoldBackgroundColor,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _card(String t, String s, String status, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(s,
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
                ]),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusBg(status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: TextStyle(
                    color: _statusText(status),
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Widget _bg(IconData i, Color c, Alignment a) => Container(
    alignment: a,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    color: c.withOpacity(0.9),
    child: Icon(i, color: Colors.white),
  );
}
