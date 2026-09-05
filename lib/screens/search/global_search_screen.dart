import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../alumni/alumni_profile_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../events/event_detail_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  String query = "";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: TextField(
          autofocus: true,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: "Search alumni, staff, jobs, events",
            hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => query = v.toLowerCase()),
        ),
      ),
      body: query.isEmpty
          ? Center(
        child: Text(
          "Start typing to search",
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, "Alumni & Staff"),
            _userResults(),

            const SizedBox(height: 24),

            _sectionTitle(context, "Jobs"),
            _jobResults(),

            const SizedBox(height: 24),

            _sectionTitle(context, "Events"),
            _eventResults(),
          ],
        ),
      ),
    );
  }

  // ================= USERS (ALUMNI & STAFF) =================
  Widget _userResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('profileCompleted', isEqualTo: true)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();

        final results = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final role = (data['role'] ?? '').toString().toLowerCase();
          final dept = (data['department'] ?? '').toString().toLowerCase();
          
          return name.contains(query) || role.contains(query) || dept.contains(query);
        }).toList();

        return results.isEmpty
            ? _empty(context, "No matches found")
            : Column(
          children: results.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final role = d['role'] ?? "Student";
            
            String subtitle = "Student";
            if (role == "Alumni") {
              subtitle = "Alumni • Batch ${d['batch'] ?? '-'}";
            } else if (role == "Staff") {
              subtitle = "Staff • ${d['designation'] ?? 'University Member'}";
            }

            return _tile(
              context,
              title: d['name'],
              subtitle: subtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AlumniProfileScreen(userId: doc.id),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ================= JOBS =================
  Widget _jobResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();

        final results = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return (data['designation'] ?? '')
              .toString()
              .toLowerCase()
              .contains(query) ||
              (data['company'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query);
        }).toList();

        return results.isEmpty
            ? _empty(context, "No jobs found")
            : Column(
          children: results.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _tile(
              context,
              title: d['designation'],
              subtitle: d['company'],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailScreen(jobId: doc.id),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ================= EVENTS =================
  Widget _eventResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();

        final results = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return (data['title'] ?? '')
              .toString()
              .toLowerCase()
              .contains(query) ||
              (data['location'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query);
        }).toList();

        return results.isEmpty
            ? _empty(context, "No events found")
            : Column(
          children: results.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _tile(
              context,
              title: d['title'],
              subtitle: d['location'],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EventDetailScreen(eventId: doc.id),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ================= UI HELPERS =================
  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _tile(BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
      ),
    );
  }

  Widget _empty(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
    );
  }
}
