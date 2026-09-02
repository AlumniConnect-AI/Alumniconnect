import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/theme.dart';
import '../alumni/alumni_profile_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;
  String search = "";
  
  // 🔹 Filter states
  String departmentFilter = "All";
  String positionFilter = "All";
  String officeFilter = "All";
  bool isMentorFilter = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Staff Directory",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Staff')
            .where('profileCompleted', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final docs = snapshot.data!.docs;

          // 🔹 Dynamic filter values
          final departments = _unique(docs, 'department');
          final positions = _unique(docs, 'designation');
          final offices = _unique(docs, 'company');

          final staff = docs.where((doc) {
            // 🔥 HIDE OWN PROFILE
            if (doc.id == currentUid) return false;

            final d = doc.data() as Map<String, dynamic>;
            final q = search.toLowerCase();

            final matchesSearch =
                (d['name'] ?? '').toString().toLowerCase().contains(q) ||
                    (d['designation'] ?? '').toString().toLowerCase().contains(q) ||
                    (d['department'] ?? '').toString().toLowerCase().contains(q) ||
                    (d['company'] ?? '').toString().toLowerCase().contains(q);

            final matchesDept = departmentFilter == "All" || d['department'] == departmentFilter;
            final matchesPos = positionFilter == "All" || d['designation'] == positionFilter;
            final matchesOffice = officeFilter == "All" || d['company'] == officeFilter;
            final matchesMentor = !isMentorFilter || d['isMentor'] == true;

            return matchesSearch && matchesDept && matchesPos && matchesOffice && matchesMentor;
          }).toList();

          return Column(
            children: [
              // 🔍 SEARCH
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search staff, position, or lab",
                    filled: true,
                    fillColor: theme.cardColor,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => search = v),
                ),
              ),

              // 🎛 FILTERS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // ✅ Mentorship Filter Chip
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text("Mentors"),
                        selected: isMentorFilter,
                        selectedColor: AppColors.primary.withOpacity(0.25),
                        checkmarkColor: AppColors.primary,
                        onSelected: (val) => setState(() => isMentorFilter = val),
                      ),
                    ),
                    _filter("Dept", departmentFilter, departments,
                            (v) => setState(() => departmentFilter = v)),
                    _filter("Position", positionFilter, positions,
                            (v) => setState(() => positionFilter = v)),
                    _filter("Office/Lab", officeFilter, offices,
                            (v) => setState(() => officeFilter = v)),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: staff.isEmpty
                    ? const Center(child: Text("No staff found"))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: staff.length,
                  itemBuilder: (_, i) {
                    final doc = staff[i];
                    final d = doc.data() as Map<String, dynamic>;

                    final name = d['name'] ?? "";
                    final photoUrl = d['photoURL'] as String?;
                    final designation = d['designation'] ?? "";
                    final dept = d['department'] ?? "";
                    final office = d['company'] ?? "";
                    final isMentor = d['isMentor'] == true;

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + (i * 40)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 12),
                            child: child,
                          ),
                        );
                      },
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlumniProfileScreen(userId: doc.id),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: (photoUrl == null || photoUrl.isEmpty)
                                    ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (isMentor) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.verified, size: 14, color: AppColors.primary),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "$designation • $office",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    Text(
                                      dept,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<String> _unique(List<QueryDocumentSnapshot> docs, String key) {
    final values = docs
        .map((d) => (d.data() as Map<String, dynamic>)[key])
        .where((v) => v != null && v.toString().isNotEmpty)
        .map((v) => v.toString())
        .toSet()
        .toList();
    values.sort();
    return ["All", ...values];
  }

  Widget _filter(String label, String value, List<String> items, Function(String) onChanged) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: DropdownButton<String>(
        value: value,
        dropdownColor: theme.cardColor,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
            .toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}
