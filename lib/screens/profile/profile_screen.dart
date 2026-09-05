import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import 'profile_edit_screen.dart';

import '../jobs/my_jobs_screen.dart';
import '../events/my_events_screen.dart';
import '../saved/saved_jobs_screen.dart';
import '../saved/saved_events_screen.dart';
import '../social/user_list_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // 🔗 OPEN LINK
  Future<void> _openLink(BuildContext context, String? url) async {
    final cleaned = url?.trim() ?? "";
    if (cleaned.isEmpty || !cleaned.startsWith("http")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid link")),
      );
      return;
    }
    await launchUrl(
      Uri.parse(cleaned),
      mode: LaunchMode.externalApplication,
    );
  }

  // 👥 FOLLOW COUNT
  Widget _followCount(
    BuildContext context, {
    required String title,
    required String uid,
    required String collection,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserListScreen(
              uid: uid,
              title: title,
              collection: collection,
            ),
          ),
        );
      },
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collection)
            .doc(uid)
            .collection('users')
            .snapshots(),
        builder: (_, snap) {
          final count = snap.data?.docs.length ?? 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNeon,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Edit profile",
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryNeon),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileEditScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: "Settings",
            icon: Icon(Icons.settings_outlined,
                color: theme.textTheme.bodyMedium?.color),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryNeon),
            );
          }

          final userData = snap.data!.data() as Map<String, dynamic>?;
          if (userData == null) {
            return const Center(child: Text("User not found"));
          }

          final name = userData['name'] ?? "";
          final photoUrl = userData['photoURL'] as String?;
          final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";
          final rawRole = (userData['role'] ?? "Student").toString();
          final isMentor = userData['isMentor'] == true;

          final isAlumni = rawRole.toLowerCase() == 'alumni';
          final isStaff = rawRole.toLowerCase() == 'staff';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= HEADER =================
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primaryNeon, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryNeon.withOpacity(0.25),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor:
                              AppColors.primaryNeon.withOpacity(0.15),
                          backgroundImage:
                              photoUrl != null && photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? Text(
                                  firstLetter,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    color: AppColors.primaryNeon,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // NAME WITH VERIFICATION MARK
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (isMentor && (isAlumni || isStaff)) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified,
                                color: AppColors.primaryNeon, size: 22),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      // CONDITIONAL ROLE/DESIGNATION DISPLAY
                      Text(
                        isAlumni
                            ? "${userData['designation'] ?? ""} @ ${userData['company'] ?? ""}"
                            : isStaff
                                ? "${userData['designation'] ?? ""} • ${userData['company'] ?? ""}"
                                : "Student",
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 3),
                      Text(
                        isStaff
                            ? (userData['department'] ?? "")
                            : "${userData['batch'] ?? ""} • ${userData['department'] ?? ""}",
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 12,
                        ),
                      ),

                      // MENTOR BADGE
                      if (isMentor && (isAlumni || isStaff)) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNeon.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.primaryNeon.withOpacity(0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user,
                                  size: 16, color: AppColors.primaryNeon),
                              SizedBox(width: 6),
                              Text(
                                "Mentor",
                                style: TextStyle(
                                  color: AppColors.primaryNeon,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ================= FOLLOW STATS =================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _followCount(
                            context,
                            title: "Followers",
                            uid: uid,
                            collection: "followers",
                          ),
                          const SizedBox(width: 16),
                          _followCount(
                            context,
                            title: "Following",
                            uid: uid,
                            collection: "following",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ================= ABOUT =================
                _sectionTitle("About"),
                _card(
                  context,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote,
                          color: AppColors.primaryNeon, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userData['bio'] ?? "No bio added",
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= CONTACT =================
                _infoCard(
                  context,
                  email: userData['email'],
                  location: !isStaff ? userData['location'] : null,
                  linkedin: !isStaff ? userData['linkedin'] : null,
                ),

                const SizedBox(height: 28),

                // ================= MY ACTIVITY =================
                _sectionTitle("My Activity"),
                _activityTile(
                  context,
                  title: "My Jobs",
                  icon: Icons.work_outline,
                  query: FirebaseFirestore.instance
                      .collection('jobs')
                      .where('ownerId', isEqualTo: uid),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyJobsScreen()),
                  ),
                ),
                _activityTile(
                  context,
                  title: "My Events",
                  icon: Icons.event_outlined,
                  query: FirebaseFirestore.instance
                      .collection('events')
                      .where('ownerId', isEqualTo: uid),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyEventsScreen()),
                  ),
                ),

                const SizedBox(height: 24),

                // ================= SAVED =================
                _sectionTitle("Saved"),
                _activityTile(
                  context,
                  title: "Saved Jobs",
                  icon: Icons.bookmark_outline,
                  query: FirebaseFirestore.instance
                      .collection('saved_jobs')
                      .where('userId', isEqualTo: uid),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SavedJobsScreen()),
                  ),
                ),
                _activityTile(
                  context,
                  title: "Saved Events",
                  icon: Icons.star_outline,
                  query: FirebaseFirestore.instance
                      .collection('saved_events')
                      .where('userId', isEqualTo: uid),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SavedEventsScreen()),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= REUSABLE UI =================

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoCard(
    BuildContext context, {
    String? email,
    String? location,
    String? linkedin,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.email_outlined,
                  size: 18, color: AppColors.primaryNeon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  email ?? "-",
                  style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color, fontSize: 13),
                ),
              ),
            ],
          ),
          if (location != null && location.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 18, color: AppColors.primaryNeon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          if (linkedin != null && linkedin.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text("View LinkedIn",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryNeon,
                  side: const BorderSide(color: AppColors.primaryNeon),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => _openLink(context, linkedin),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _activityTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Query query,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (_, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNeon.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.primaryNeon, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNeon,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
