import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/theme.dart';
import '../../widgets/theme/glass_card.dart';
import '../../widgets/theme/neon_button.dart';
import '../alumni/alumni_profile_screen.dart';
import '../profile/profile_screen.dart';
import '../search/global_search_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../events/event_detail_screen.dart';
import '../ai/ai_hub_screen.dart';
import '../ai/career_twin_screen.dart';
import '../ai/career_gps_screen.dart';
import 'home_skeleton.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

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

  String _getQuoteOfTheDay() {
    final dayIndex = DateTime.now().day % _quotes.length;
    return _quotes[dayIndex];
  }

  // 🎭 Dynamic Greeting with Role
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

  // 🕒 Time ago helper
  String _timeAgo(Timestamp? ts) {
    if (ts == null) return "Recently";
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    return "Just now";
  }

  // ================= RANDOM RECOMMENDED ALUMNI FUNCTION =================
  Future<List<QueryDocumentSnapshot>> _getRecommendedAlumni() async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('profileCompleted', isEqualTo: true)
        .get();

    // Filter out current user
    final docs = query.docs.where((doc) => doc.id != uid).toList();
    
    // Shuffle the list to get random profiles
    docs.shuffle();
    
    return docs.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {}); 
          },
          color: AppColors.primary,
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
              final role = user['role'] ?? "Student";
              final photoUrl = user['photoURL'] as String?;
              final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "U";

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= HEADER =================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              backgroundImage: photoUrl != null && photoUrl.isNotEmpty 
                                  ? NetworkImage(photoUrl) 
                                  : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                ? Text(
                                    firstLetter,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Stay Connected. Stay Engaged.",
                                  style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _chatBadge(context),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ================= QUOTE OF THE DAY =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.format_quote_rounded, color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  "Quote of the Day",
                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _getQuoteOfTheDay(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ================= AI HUB FEATURE CARD =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        borderColor: AppColors.primaryNeon.withValues(alpha: 0.5),
                        backgroundColor: AppColors.cardDark.withValues(alpha: 0.8),
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
                                        color: AppColors.primaryNeon.withValues(alpha: 0.4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.psychology, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "AI Hub",
                                            style: TextStyle(
                                              color: theme.textTheme.bodyLarge?.color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              gradient: AppGradients.purplePink,
                                              borderRadius: BorderRadius.circular(8),
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
                                          color: theme.textTheme.bodyMedium?.color,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: AppColors.primaryNeon),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AiHubScreen()),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ── TWO GLOWING BUTTONS ──────────────────────────────────
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
                                      MaterialPageRoute(builder: (_) => const CareerTwinScreen()),
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
                                      MaterialPageRoute(builder: (_) => const CareerGpsScreen()),
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

                    // ================= QUICK ACTIONS =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        crossAxisCount: 3, 
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.9,
                        children: [
                          _quickCardWidget(context, "AI Hub", Icons.psychology,
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiHubScreen()))),
                          _quickCardWidget(context, "Community", Icons.school,
                              () => widget.onTabChange(1)),
                          _quickCardWidget(context, "Staff", Icons.badge, 
                              () => widget.onTabChange(2)),
                          _quickCardWidget(context, "Jobs", Icons.work, 
                              () => widget.onTabChange(3)),
                          _quickCardWidget(context, "Events", Icons.event, 
                              () => widget.onTabChange(4)),
                          _quickCardWidget(context, "Search", Icons.search, 
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen()))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ================= LATEST UPDATES =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _sectionHeader(context, "Latest Updates"),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _latestCombinedUpdates(context),
                    ),

                    const SizedBox(height: 30),

                    // ================= RECOMMENDATIONS =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _sectionHeader(context, "People You May Know"),
                    ),
                    const SizedBox(height: 12),
                    _recommendationList(context),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ================= REUSABLE COMPONENTS =================

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
            final unread = (data['unreadCount'] != null && data['unreadCount'][uid] != null) 
                ? data['unreadCount'][uid] as int 
                : 0;
            totalUnread += unread;
          }
        }

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 28),
              onPressed: () => widget.onTabChange(5), 
            ),
            if (totalUnread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    totalUnread > 9 ? '9+' : '$totalUnread',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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

  Widget _quickCardWidget(BuildContext context, String title, IconData icon, VoidCallback onTap) {
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
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color, 
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
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
      stream: FirebaseFirestore.instance.collection('jobs').orderBy('createdAt', descending: true).limit(5).snapshots(),
      builder: (_, jobSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').orderBy('createdAt', descending: true).limit(5).snapshots(),
          builder: (_, eventSnap) {
            if (!jobSnap.hasData || !eventSnap.hasData) return const SizedBox();

            final items = [
              ...jobSnap.data!.docs.map((d) => {'type': 'job', 'id': d.id, 'data': d.data()}),
              ...eventSnap.data!.docs.map((d) => {'type': 'event', 'id': d.id, 'data': d.data()}),
            ];

            items.sort((a, b) {
              final aTime = (a['data'] as Map)['createdAt'] as Timestamp?;
              final bTime = (b['data'] as Map)['createdAt'] as Timestamp?;
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
                        : EventDetailScreen(eventId: item['id'] as String),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(isJob ? Icons.work_outline : Icons.event_outlined, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isJob ? (d['designation'] ?? "Job") : (d['title'] ?? "Event"), 
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(_timeAgo(d['createdAt'] as Timestamp?), 
                                  style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
                            ],
                          ),
                        ),
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
        if (users.isEmpty) return Text("No recommendations yet.", style: TextStyle(color: theme.textTheme.bodyMedium?.color));

        return SizedBox(
          height: 160,
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
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlumniProfileScreen(userId: doc.id))),
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primarySoft, 
                        backgroundImage: rPhoto != null && rPhoto.isNotEmpty ? NetworkImage(rPhoto) : null,
                        child: (rPhoto == null || rPhoto.isEmpty)
                          ? Text(rName.isNotEmpty ? rName[0].toUpperCase() : "?", style: const TextStyle(color: AppColors.primary))
                          : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              rName, 
                              style: const TextStyle(fontWeight: FontWeight.bold), 
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // ✅ ONLY SHOW VERIFICATION FOR STAFF
                          if (isMentor && role.toLowerCase() == 'staff') ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: AppColors.primary, size: 14),
                          ],
                        ],
                      ),
                      Text(
                        role == "Alumni" 
                          ? "${d['designation'] ?? "Alumni"}" 
                          : role == "Staff"
                            ? "${d['designation'] ?? "Staff"}"
                            : "Student", 
                        style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color), 
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
