import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../services/role_flip_service.dart';
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
    final cleaned = url?.trim() ?? '';
    if (cleaned.isEmpty || !cleaned.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid link')),
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
          return Column(
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 13,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── SECTION TITLE ──────────────────────────────────────────────────────────
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

  // ── CARD ───────────────────────────────────────────────────────────────────
  Widget _card(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }

  // ── INFO ROW ───────────────────────────────────────────────────────────────
  Widget _infoRow(BuildContext context, String label, String? value) {
    final theme = Theme.of(context);
    return Text(
      '$label: ${value ?? '-'}',
      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
    );
  }

  // ── ACTIVITY TILE ──────────────────────────────────────────────────────────
  Widget _activityTile(
    BuildContext context, {
    required String title,
    required Query query,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (_, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: Icon(Icons.settings, color: theme.textTheme.bodyMedium?.color),
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
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final userData = snap.data!.data() as Map<String, dynamic>?;
          if (userData == null) {
            return const Center(child: Text('User not found'));
          }

          final name = userData['name'] ?? '';
          final photoUrl = userData['photoURL'] as String?;
          final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
          final rawRole = (userData['role'] ?? 'Student').toString();
          final isMentor = userData['isMentor'] == true;

          final isAlumni = rawRole.toLowerCase() == 'alumni';
          final isStaff = rawRole.toLowerCase() == 'staff';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════ HEADER ═══════════════════════════════════
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? Text(
                                firstLetter,
                                style: const TextStyle(
                                  fontSize: 34,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Name + verified tick
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isMentor && (isAlumni || isStaff)) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.verified,
                                color: AppColors.primary, size: 22),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Role / designation subtitle
                      Text(
                        isAlumni
                            ? '${userData['designation'] ?? ''} @ ${userData['company'] ?? ''}'
                            : isStaff
                                ? '${userData['designation'] ?? ''} • ${userData['company'] ?? ''}'
                                : 'Student',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        isStaff
                            ? (userData['department'] ?? '')
                            : '${userData['batch'] ?? ''} • ${userData['department'] ?? ''}',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),

                      // Mentor badge
                      if (isMentor && (isAlumni || isStaff)) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user,
                                  size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Mentor',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // Follow stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _followCount(context,
                              title: 'Followers',
                              uid: uid,
                              collection: 'followers'),
                          _followCount(context,
                              title: 'Following',
                              uid: uid,
                              collection: 'following'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ═══════════════ ABOUT ════════════════════════════════════
                _sectionTitle('About'),
                _card(
                  context,
                  child: Text(
                    userData['bio'] ?? 'No bio added',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ═══════════════ CONTACT ══════════════════════════════════
                _infoRow(context, 'Email', userData['email']),

                if (!isStaff) ...[
                  const SizedBox(height: 10),
                  _infoRow(context, 'Location', userData['location']),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View LinkedIn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () =>
                        _openLink(context, userData['linkedin']),
                  ),
                ],

                const SizedBox(height: 30),

                // ═══════════════ MY ACTIVITY ══════════════════════════════
                _sectionTitle('My Activity'),
                _activityTile(
                  context,
                  title: 'My Jobs',
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
                  title: 'My Events',
                  query: FirebaseFirestore.instance
                      .collection('events')
                      .where('ownerId', isEqualTo: uid),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyEventsScreen()),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Role-Flip Trigger B (students only) ────────────────────
                if (!isAlumni && !isStaff)
                  _RoleFlipButton(uid: uid, userData: userData),

                const SizedBox(height: 8),

                // ═══════════════ SAVED ════════════════════════════════════
                _sectionTitle('Saved'),
                _activityTile(
                  context,
                  title: 'Saved Jobs',
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
                  title: 'Saved Events',
                  query: FirebaseFirestore.instance
                      .collection('saved_events')
                      .where('userId', isEqualTo: uid),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SavedEventsScreen()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Role Flip Trigger B Widget
// ════════════════════════════════════════════════════════════════════════════

class _RoleFlipButton extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> userData;

  const _RoleFlipButton({required this.uid, required this.userData});

  @override
  State<_RoleFlipButton> createState() => _RoleFlipButtonState();
}

class _RoleFlipButtonState extends State<_RoleFlipButton> {
  final _collegeIdCtrl = TextEditingController();
  int? _selectedYear;
  bool _loading = false;

  @override
  void dispose() {
    _collegeIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _showFlipDialog() async {
    final theme = Theme.of(context);
    final gradYear = widget.userData['graduationYear'] as int?;
    // Only pre-select the year if it actually exists in the dropdown items list.
    // The dropdown covers [currentYear-10 .. currentYear+6].
    final now = DateTime.now().year;
    if (gradYear != null && gradYear >= now - 10 && gradYear <= now + 6) {
      _selectedYear = gradYear;
    } else {
      _selectedYear = null; // prevent dropdown assertion crash
    }
    _collegeIdCtrl.text = '';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: AppColors.accentPurple),
              SizedBox(width: 10),
              Text('Become an Alumnus'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your College ID and graduation year to verify your alumni status.',
                style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _collegeIdCtrl,
                decoration: InputDecoration(
                  hintText: 'College ID (e.g. STU2022001)',
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedYear,
                dropdownColor: theme.cardColor,
                decoration: InputDecoration(
                  hintText: 'Graduation Year',
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                // Range: 10 years back to 6 years forward — covers all realistic
                // student (expected) and alumni (past) graduation years.
                items: List.generate(
                  17,
                  (i) => DateTime.now().year - 10 + i,
                ).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (v) => setDialog(() => _selectedYear = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                if (_collegeIdCtrl.text.isEmpty ||
                    _selectedYear == null) {
                  return;
                }
                Navigator.pop(ctx);
                await _performFlip();
              },
              child: const Text('Verify & Upgrade'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performFlip() async {
    if (_selectedYear == null) return;
    setState(() => _loading = true);

    final result = await RoleFlipService.triggerManualFlip(
      uid: widget.uid,
      collegeId: _collegeIdCtrl.text.trim(),
      graduationYear: _selectedYear!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.verificationStatus == 'verified'
              ? AppColors.accentEmerald
              : AppColors.warning,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.purplePink,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPurple.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _showFlipDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.workspace_premium,
                  color: Colors.white, size: 22),
          label: const Text(
            "I've graduated — become an alumnus",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ),
      ),
    );
  }
}
