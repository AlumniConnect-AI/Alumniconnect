import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/theme.dart';
import 'alumni_profile_screen.dart';

class AlumniListScreen extends StatefulWidget {
  const AlumniListScreen({super.key});

  @override
  State<AlumniListScreen> createState() => _AlumniListScreenState();
}

class _AlumniListScreenState extends State<AlumniListScreen> {
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  String search = "";

  String roleFilter = "All"; // Added role filter
  String batchFilter = "All";
  String departmentFilter = "All";
  String companyFilter = "All";
  String locationFilter = "All";
  bool isMentorFilter = false; 

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Community Directory",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('profileCompleted', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final docs = snapshot.data!.docs;

          // Dynamic filter values (only for non-staff)
          final filteredDocsForFilters = docs.where((doc) {
             final d = doc.data() as Map<String, dynamic>;
             final role = (d['role'] ?? "Student").toString().toLowerCase();
             return role != 'staff';
          }).toList();

          final batches = _unique(filteredDocsForFilters, 'batch');
          final departments = _unique(filteredDocsForFilters, 'department');
          final companies = _unique(filteredDocsForFilters, 'company');
          final locations = _unique(filteredDocsForFilters, 'location');

          // Apply filters + Hide self + Hide Staff
          final alumni = docs.where((doc) {
            if (doc.id == currentUid) return false;

            final d = doc.data() as Map<String, dynamic>;
            
            // EXCLUDE STAFF
            final role = (d['role'] ?? "Student").toString();
            if (role.toLowerCase() == 'staff') return false;

            final q = search.toLowerCase();

            final matchesSearch =
                (d['name'] ?? '').toString().toLowerCase().contains(q) ||
                    (d['company'] ?? '').toString().toLowerCase().contains(q) ||
                    (d['designation'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(q) ||
                    (d['department'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(q);

            final matchesRole = roleFilter == "All"|| role == roleFilter; // Role check
            final matchesBatch =
                batchFilter == "All" || d['batch'] == batchFilter;
            final matchesDept =
                departmentFilter == "All" ||
                    d['department'] == departmentFilter;
            final matchesCompany =
                companyFilter == "All" || d['company'] == companyFilter;
            final matchesLocation =
                locationFilter == "All" || d['location'] == locationFilter;
            
            final matchesMentor = !isMentorFilter || d['isMentor'] == true;

            return matchesSearch &&
                matchesRole &&
                matchesBatch &&
                matchesDept &&
                matchesCompany &&
                matchesLocation &&
                matchesMentor;
          }).toList();

          return Column(
            children: [
              // SEARCH
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search members",
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

              // FILTERS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _filter("Role", roleFilter, ["All", "Student", "Alumni"],
                            (v) => setState(() => roleFilter = v)), // Role dropdown
                    _filter("Batch", batchFilter, batches,
                            (v) => setState(() => batchFilter = v)),
                    _filter("Dept", departmentFilter, departments,
                            (v) => setState(() => departmentFilter = v)),
                    _filter("Company", companyFilter, companies,
                            (v) => setState(() => companyFilter = v)),
                    _filter("Location", locationFilter, locations,
                            (v) => setState(() => locationFilter = v)),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // LIST WITH ANIMATION
              Expanded(
                child: alumni.isEmpty
                    ? const Center(
                  child: Text(
                    "No matches found",
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alumni.length,
                  itemBuilder: (_, i) {
                    final doc = alumni[i];
                    final d =
                    doc.data() as Map<String, dynamic>;

                    final name = d['name'] ?? "";
                    final photoUrl = d['photoURL'] as String?;
                    final rawRole = (d['role'] ?? "Student").toString();
                    final designation = d['designation'] ?? "";
                    final company = d['company'] ?? "";
                    final dept = d['department'] ?? "";

                    final isAlumni = rawRole.toLowerCase() == 'alumni';

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration:
                      Duration(milliseconds: 300 + (i * 40)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset:
                            Offset(0, (1 - value) * 12),
                            child: child,
                          ),
                        );
                      },
                      child: InkWell(
                        borderRadius:
                        BorderRadius.circular(18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AlumniProfileScreen(
                                      userId: doc.id),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                              bottom: 14),
                          padding:
                          const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius:
                            BorderRadius.circular(18),
                            border: Border.all(
                                color: theme.dividerColor.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor:
                                AppColors.primary.withOpacity(0.1),
                                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: (photoUrl == null || photoUrl.isEmpty)
                                    ? Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : "?",
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
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isAlumni 
                                        ? "$designation @ $company"
                                        : "Student",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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

                              if (!isAlumni && d['batch'] != null)
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    d['batch'] ?? "-",
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
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

  List<String> _unique(
      List<QueryDocumentSnapshot> docs, String key) {
    final values = docs
        .map((d) => (d.data() as Map<String, dynamic>)[key])
        .where((v) => v != null && v.toString().isNotEmpty)
        .map((v) => v.toString())
        .toSet()
        .toList();

    values.sort();
    return ["All", ...values];
  }

  Widget _filter(
      String label,
      String value,
      List<String> items,
      Function(String) onChanged,
      ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: DropdownButton<String>(
        value: value,
        dropdownColor: theme.cardColor,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        items: items
            .map(
              (e) =>
              DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))),
        )
            .toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}
