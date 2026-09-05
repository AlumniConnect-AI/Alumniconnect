import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/theme.dart';
import '../../widgets/theme/glass_card.dart';
import '../../widgets/theme/neon_button.dart';
import '../../widgets/retention_timeline_widget.dart';
import '../../services/role_flip_service.dart';
import '../alumni/alumni_profile_screen.dart';
import '../profile/profile_screen.dart';
import '../search/global_search_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../events/event_detail_screen.dart';
import '../ai/ai_hub_screen.dart';
import '../ai/career_twin_screen.dart';
import '../ai/career_gps_screen.dart';
import '../alumni/post_referral_screen.dart';
import '../alumni/employment_verification_screen.dart';
import '../alumni/alumni_mentees_screen.dart';
import 'placement_report_screen.dart';
import 'home_skeleton.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String? _nudgeBanner;

  final List<String> _quotes = [
    "Your network is your net worth.",
    "Education is the most powerful weapon which you can use to change the world.",
    "Opportunities don't happen. You create them.",
    "The only way to do great work is to love what you do.",
    "The future belongs to those who believe in the beauty of their dreams.",
    "Success is not final, failure is not fatal: it is the courage to continue that counts.",
    "Hard work beats talent when talent doesn't work hard.",
    "Believe you can and you're halfway there.",
    "Your education is a dress rehearsal for a life that is yours to lead.",
    "Don't wait for opportunity. Create it."
  ];

  @override
  void initState() {
    super.initState();
    _checkNudge();
  }

  Future<void> _checkNudge() async {
    final msg = await RoleFlipService.getNudgeBanner(uid);
    if (mounted) setState(() => _nudgeBanner = msg);
  }

  String _getQuoteOfTheDay() {
    final dayIndex = DateTime.now().day % _quotes.length;
    return _quotes[dayIndex];
  }

  String _greeting(String name, String role) {
    final hour = DateTime.now().hour;
    String timePrefix;
    if (hour < 12) {
      timePrefix = "Good Morning";
    } else if (hour < 17) {
      timePrefix = "Good Afternoon";
    } else {
      timePrefix = "Good Evening";
    }

    if (role.toLowerCase() == 'staff') {
      return "$timePrefix, Professor $name";
    } else if (role.toLowerCase() == 'alumni') {
      return "$timePrefix, Alumnus $name";
    } else {
      return "$timePrefix, $name";
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return "Recently";
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    return "Just now";
  }

  Future<List<QueryDocumentSnapshot>> _getRecommendedAlumni() async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('profileCompleted', isEqualTo: true)
        .get();

    final docs = query.docs.where((doc) => doc.id != uid).toList();
    docs.shuffle();
    return docs.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await _checkNudge();
          },
          color: AppColors.primaryNeon,
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(children: const [HomeSkeleton()]);
              }

              if (!snapshot.hasData || snapshot.data?.data() == null) {
                return ListView(children: const [HomeSkeleton()]);
              }

              final user = snapshot.data!.data() as Map<String, dynamic>;
              final name = user['name'] ?? "User";
              final role = (user['role'] ?? "student").toString().toLowerCase();
              final photoUrl = user['photoURL'] as String?;
              final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "U";
              final verificationStatus = user['verificationStatus'] ?? '';

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Card ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: theme.dividerColor.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ProfileScreen()),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.primaryNeon, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      AppColors.primaryNeon.withOpacity(0.15),
                                  backgroundImage: photoUrl != null &&
                                          photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: (photoUrl == null || photoUrl.isEmpty)
                                      ? Text(
                                          firstLetter,
                                          style: const TextStyle(
                                            color: AppColors.primaryNeon,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _greeting(name, role),
                                    style: TextStyle(
                                      color: theme.textTheme.bodyLarge?.color,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "Stay Connected. Stay Engaged.",
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (role != 'alumni') _chatBadge(context),
                          ],
                        ),
                      ),
                    ),

                    // ── Banners ──────────────────────────────────────────
                    if (role == 'alumni' && verificationStatus == 'pending')
                      _verificationBanner(context),

                    if (_nudgeBanner != null) _nudgeBannerWidget(context),

                    if (role == 'pending_alumni_verification')
                      _pendingAlumniPrompt(context),

                    const SizedBox(height: 20),

                    // ── Quote of the Day ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: AppGradients.blueViolet,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentBlue.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.format_quote_rounded,
                                    color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  "Quote of the Day",
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _getQuoteOfTheDay(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── AI Hub Card ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        borderColor: theme.dividerColor,
                        backgroundColor: theme.cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.neonCyanPurple,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryNeon
                                            .withOpacity(0.3),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.psychology,
                                      color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "AI Hub",
                                            style: TextStyle(
                                              color: theme
                                                  .textTheme.bodyLarge?.color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              gradient: AppGradients.purplePink,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              "DUAL ENGINE",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Career Intelligence Powered by AI",
                                        style: TextStyle(
                                          color: theme
                                              .textTheme.bodyMedium?.color,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios,
                                      size: 16, color: AppColors.primaryNeon),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const AiHubScreen()),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: NeonButton(
                                    text: "Career Twin AI",
                                    icon: Icons.smart_toy,
                                    height: 44,
                                    gradient: AppGradients.neonCyanPurple,
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const CareerTwinScreen()),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: NeonButton(
                                    text: "Career GPS AI",
                                    icon: Icons.explore,
                                    height: 44,
                                    gradient: AppGradients.purplePink,
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const CareerGpsScreen()),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── ROLE-BASED CONTENT FORK ──────────────────────────
                    if (role == 'alumni')
                      _alumniContent(context, user)
                    else
                      _studentContent(context, user),

                    const SizedBox(height: 28),

                    // ── Latest Updates ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _sectionHeader(context, "Latest Updates"),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _latestCombinedUpdates(context),
                    ),

                    const SizedBox(height: 28),

                    // ── Recommendations (Students/Staff only) ───────────────
                    if (role != 'alumni') ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _sectionHeader(context, "People You May Know"),
                      ),
                      const SizedBox(height: 12),
                      _recommendationList(context),
                      const SizedBox(height: 28),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STUDENT-SPECIFIC HOME CONTENT
  // ══════════════════════════════════════════════════════════════════════════

  Widget _studentContent(BuildContext context, Map<String, dynamic> user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Career Journey (Retention Timeline)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RetentionTimelineWidget(uid: uid),
        ),

        const SizedBox(height: 16),

        // Placement status CTA
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _placementCtaCard(context),
        ),

        const SizedBox(height: 24),

        // Quick actions grid — Student tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _sectionHeader(context, "Quick Actions"),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _quickCardWidget(context, "AI Hub", Icons.psychology,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AiHubScreen()))),
              _quickCardWidget(context, "Community", Icons.school,
                  () => widget.onTabChange(1)),
              _quickCardWidget(context, "Staff", Icons.badge,
                  () => widget.onTabChange(2)),
              _quickCardWidget(context, "Jobs", Icons.work,
                  () => widget.onTabChange(3)),
              _quickCardWidget(context, "Events", Icons.event,
                  () => widget.onTabChange(4)),
              _quickCardWidget(
                  context,
                  "Search",
                  Icons.search,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GlobalSearchScreen()))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placementCtaCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlacementReportScreen(uid: uid)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppGradients.emeraldCyan,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentEmerald.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_note, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Update Your Placement Status",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Help us track your career journey",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ALUMNI-SPECIFIC HOME CONTENT
  // ══════════════════════════════════════════════════════════════════════════

  Widget _alumniContent(BuildContext context, Map<String, dynamic> user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mentorship Requests Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _mentorshipRequestsCard(context),
        ),

        const SizedBox(height: 14),

        // My Mentees Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _myMenteesCard(context),
        ),

        const SizedBox(height: 14),

        // Retention Timeline
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RetentionTimelineWidget(uid: uid),
        ),

        const SizedBox(height: 14),

        // Post Job CTA
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _postReferralCtaCard(context),
        ),

        const SizedBox(height: 14),

        // Employment Verification CTA
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _employmentVerificationCtaCard(context),
        ),

        const SizedBox(height: 24),

        // Alumni Quick Actions grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _sectionHeader(context, "Quick Actions"),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _quickCardWidget(
                  context,
                  "My Profile",
                  Icons.person,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()))),
              _quickCardWidget(
                  context,
                  "Post Job",
                  Icons.work_outline,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PostReferralScreen()))),
              _quickCardWidget(
                  context,
                  "Mentees",
                  Icons.people,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AlumniMenteesScreen()))),
              _quickCardWidget(
                  context,
                  "Jobs Posted",
                  Icons.work,
                  () => widget.onTabChange(2)),
              _quickCardWidget(
                  context,
                  "Verify",
                  Icons.verified_user,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const EmploymentVerificationScreen()))),
              _quickCardWidget(
                  context,
                  "Search",
                  Icons.search,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GlobalSearchScreen()))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mentorshipRequestsCard(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AlumniMenteesScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppGradients.purplePink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.handshake, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mentorship Requests",
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('mentorship')
                        .where('mentorUid', isEqualTo: uid)
                        .where('requestStatus', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (_, snap) {
                      final count = snap.data?.docs.length ?? 0;
                      return Text(
                        count == 0
                            ? "No pending requests"
                            : "$count pending request${count > 1 ? 's' : ''}",
                        style: TextStyle(
                          color: count > 0
                              ? AppColors.accentPurple
                              : theme.textTheme.bodyMedium?.color,
                          fontSize: 12,
                          fontWeight: count > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.accentPurple, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _myMenteesCard(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AlumniMenteesScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primaryNeon.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppGradients.neonCyanPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Mentees",
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('mentorship')
                        .where('mentorUid', isEqualTo: uid)
                        .where('requestStatus', isEqualTo: 'accepted')
                        .snapshots(),
                    builder: (_, snap) {
                      final count = snap.data?.docs.length ?? 0;
                      return Text(
                        count == 0 ? "No active mentees" : "$count active mentee${count > 1 ? 's' : ''}",
                        style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 12),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.primaryNeon, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _postReferralCtaCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostReferralScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppGradients.blueViolet,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentBlue.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.work_outline, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Post a Job",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Share job opportunities with students at your alma mater",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _employmentVerificationCtaCard(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EmploymentVerificationScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accentEmerald.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppGradients.emeraldCyan,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.verified_user, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Employment Verification",
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Review & verify student employment claims",
                    style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.accentEmerald, size: 16),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BANNERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _verificationBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Verification pending — your college hasn't confirmed this record yet.",
              style: TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nudgeBannerWidget(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBlue.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: AppColors.accentBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _nudgeBanner!,
              style: const TextStyle(color: AppColors.accentBlue, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _nudgeBanner = null),
            child: const Icon(Icons.close, color: AppColors.accentBlue, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _pendingAlumniPrompt(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppGradients.purplePink,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.accentPurple.withOpacity(0.3),
              blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Complete alumni verification to unlock your Alumni home.",
              style: TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: const Text("Verify",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED COMPONENTS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _chatBadge(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: uid)
          .snapshots(),
      builder: (context, snap) {
        int totalUnread = 0;
        if (snap.hasData) {
          for (var doc in snap.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final unread = (data['unreadCount'] != null &&
                    data['unreadCount'][uid] != null)
                ? data['unreadCount'][uid] as int
                : 0;
            totalUnread += unread;
          }
        }

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline,
                  color: AppColors.primaryNeon, size: 26),
              onPressed: () => widget.onTabChange(5),
            ),
            if (totalUnread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    totalUnread > 9 ? '9+' : '$totalUnread',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _quickCardWidget(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: theme.dividerColor.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryNeon.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryNeon, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _latestCombinedUpdates(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (_, jobSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (_, eventSnap) {
            if (!jobSnap.hasData || !eventSnap.hasData) return const SizedBox();

            final items = [
              ...jobSnap.data!.docs.map(
                  (d) => {'type': 'job', 'id': d.id, 'data': d.data()}),
              ...eventSnap.data!.docs.map(
                  (d) => {'type': 'event', 'id': d.id, 'data': d.data()}),
            ];

            items.sort((a, b) {
              final aTime =
                  (a['data'] as Map)['createdAt'] as Timestamp?;
              final bTime =
                  (b['data'] as Map)['createdAt'] as Timestamp?;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

            return Column(
              children: items.take(5).map((item) {
                final d = item['data'] as Map<String, dynamic>;
                final isJob = item['type'] == 'job';

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => isJob
                          ? JobDetailScreen(jobId: item['id'] as String)
                          : EventDetailScreen(
                              eventId: item['id'] as String),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: theme.dividerColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isJob ? AppColors.accentEmerald : AppColors.accentBlue)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isJob ? Icons.work_outline : Icons.event_outlined,
                            color: isJob ? AppColors.accentEmerald : AppColors.accentBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isJob
                                    ? (d['designation'] ?? "Job")
                                    : (d['title'] ?? "Event"),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _timeAgo(d['createdAt'] as Timestamp?),
                                style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color,
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _recommendationList(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _getRecommendedAlumni(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final users = snapshot.data!;
        if (users.isEmpty) {
          return Text("No recommendations yet.",
              style: TextStyle(color: theme.textTheme.bodyMedium?.color));
        }

        return SizedBox(
          height: 165,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final d = doc.data() as Map<String, dynamic>;
              final rName = d['name'] ?? "User";
              final rPhoto = d['photoURL'] as String?;
              final role = (d['role'] ?? "Student").toString();
              final isMentor = d['isMentor'] == true;

              return GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AlumniProfileScreen(userId: doc.id))),
                child: Container(
                  width: 145,
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: theme.dividerColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primaryNeon.withOpacity(0.5),
                              width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryNeon.withOpacity(0.12),
                          backgroundImage: rPhoto != null && rPhoto.isNotEmpty
                              ? NetworkImage(rPhoto)
                              : null,
                          child: (rPhoto == null || rPhoto.isEmpty)
                              ? Text(
                                  rName.isNotEmpty ? rName[0].toUpperCase() : "?",
                                  style: const TextStyle(
                                      color: AppColors.primaryNeon,
                                      fontWeight: FontWeight.bold))
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              rName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMentor && role.toLowerCase() == 'staff') ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                color: AppColors.primaryNeon, size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role == "Alumni"
                            ? "${d['designation'] ?? "Alumni"}"
                            : role == "Staff"
                                ? "${d['designation'] ?? "Staff"}"
                                : "Student",
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
