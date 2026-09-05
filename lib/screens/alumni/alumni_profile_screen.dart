import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../chat/chat_screen.dart';
import 'followers_following_screen.dart';

class AlumniProfileScreen extends StatefulWidget {
  final String userId;
  const AlumniProfileScreen({super.key, required this.userId});

  @override
  State<AlumniProfileScreen> createState() => _AlumniProfileScreenState();
}

class _AlumniProfileScreenState extends State<AlumniProfileScreen>
    with SingleTickerProviderStateMixin {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide =
        Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(_fade);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _chatId(String a, String b) {
    final ids = [a, b]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  // OPEN LINK
  Future<void> _openLink(BuildContext context, String? url) async {
    final cleaned = url?.trim() ?? "";
    if (cleaned.isEmpty || !cleaned.startsWith("http")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("LinkedIn profile not available")),
      );
      return;
    }
    try {
      await launchUrl(
        Uri.parse(cleaned),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  // FULL SCREEN IMAGE VIEWER
  void _openFullScreenImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // REPORT USER
  Future<void> _reportUser() async {
    final theme = Theme.of(context);
    final reasons = ["Spam", "Inappropriate Content", "Fake Profile", "Other"];
    String? selectedReason;
    final otherController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.cardColor,
          title: const Text("Report User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...reasons.map((r) => RadioListTile<String>(
                title: Text(r),
                value: r,
                groupValue: selectedReason,
                activeColor: AppColors.primary,
                onChanged: (v) => setDialogState(() => selectedReason = v),
              )),
              
              if (selectedReason == "Other")
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: otherController,
                    decoration: const InputDecoration(
                      hintText: "Enter reason...",
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            TextButton(
              onPressed: selectedReason == null ? null : () => Navigator.pop(context, true),
              child: const Text("Submit", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && selectedReason != null) {
      String finalReason = (selectedReason == "Other" && otherController.text.trim().isNotEmpty) 
          ? "Other: ${otherController.text.trim()}" 
          : selectedReason!;

      await FirebaseFirestore.instance.collection('reports').add({
        'reportedUserId': widget.userId,
        'reportedBy': uid,
        'reason': finalReason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User reported successfully")));
    }
  }

  // ================= CHAT =================
  Future<void> _openChat() async {
    try {
      final chatId = _chatId(uid, widget.userId);

      // Create or update the chat metadata
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': FieldValue.arrayUnion([uid, widget.userId]),
        'users': [uid, widget.userId],
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Ensure unreadCount map exists
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'unreadCount.$uid': FieldValue.increment(0),
        'unreadCount.${widget.userId}': FieldValue.increment(0),
      }).catchError((e) async {
        await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
          'unreadCount': {
            uid: 0,
            widget.userId: 0,
          }
        }, SetOptions(merge: true));
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: chatId, peerId: widget.userId),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening chat: $e")),
        );
      }
    }
  }

  // ================= MUTUAL FOLLOW CHECK =================
  Stream<bool> _isMutualFollow() {
    final myFollowing = FirebaseFirestore.instance
        .collection('following')
        .doc(uid)
        .collection('users')
        .doc(widget.userId);

    final theirFollowing = FirebaseFirestore.instance
        .collection('following')
        .doc(widget.userId)
        .collection('users')
        .doc(uid);

    return myFollowing.snapshots().asyncMap((mySnap) async {
      if (!mySnap.exists) return false;
      final theirSnap = await theirFollowing.get();
      return theirSnap.exists;
    });
  }

  // ================= FOLLOW BUTTON =================
  Widget _followButton() {
    final followingRef = FirebaseFirestore.instance
        .collection('following')
        .doc(uid)
        .collection('users')
        .doc(widget.userId);

    final followersRef = FirebaseFirestore.instance
        .collection('followers')
        .doc(widget.userId)
        .collection('users')
        .doc(uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: followingRef.snapshots(),
      builder: (_, snap) {
        final isFollowing = snap.data?.exists ?? false;

        return SizedBox(
          height: 38,
          width: 110,
          child: isFollowing
              ? OutlinedButton(
            onPressed: () async {
              await followingRef.delete();
              await followersRef.delete();
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Unfollow"),
          )
              : ElevatedButton(
            onPressed: () async {
              await followingRef.set({'at': Timestamp.now()});
              await followersRef.set({'at': Timestamp.now()});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Follow"),
          ),
        );
      },
    );
  }

  // ================= FOLLOW COUNT =================
  Widget _countTile(String title, String collection) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .doc(widget.userId)
          .collection('users')
          .snapshots(),
      builder: (_, snap) {
        final count = snap.data?.docs.length ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FollowersFollowingScreen(
                  profileUserId: widget.userId,
                  title: title,
                  collection: collection,
                ),
              ),
            );
          },
          child: Column(
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= JOBS POSTED =================
  Widget _jobsByUser() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('ownerId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();

        if (snap.data!.docs.isEmpty) {
          return _emptyText("No jobs posted yet.");
        }

        return Column(
          children: snap.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _infoCard(
              Icons.work,
              d['designation'] ?? 'Job',
              d['company'] ?? '',
            );
          }).toList(),
        );
      },
    );
  }

  // ================= EVENTS POSTED =================
  Widget _eventsByUser() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('ownerId', isEqualTo: widget.userId)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();

        if (snap.data!.docs.isEmpty) {
          return _emptyText("No events posted yet.");
        }

        return Column(
          children: snap.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _infoCard(
              Icons.event,
              d['title'] ?? 'Event',
              d['date'] ?? '',
            );
          }).toList(),
        );
      },
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(elevation: 0, centerTitle: true, title: const Text("Profile")),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final d = snap.data!.data() as Map<String, dynamic>? ?? {};
        final photoUrl = d['photoURL'] as String?;
        final name = d['name'] ?? "User";
        final role = (d['role'] ?? "Student").toString();
        final isMentor = d['isMentor'] == true;
        
        final isAlumni = role.toLowerCase() == 'alumni';
        final isStaff = role.toLowerCase() == 'staff';

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            title: Text(
              isAlumni ? "Alumni Profile" : isStaff ? "Staff Profile" : "Student Profile",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (uid != widget.userId)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'report') _reportUser();
                  },
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 20, color: Colors.red),
                          SizedBox(width: 10),
                          Text("Report User", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Avatar
                    Center(
                      child: GestureDetector(
                        onTap: (photoUrl != null && photoUrl.isNotEmpty)
                            ? () => _openFullScreenImage(context, photoUrl)
                            : null,
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : "U",
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // VERIFICATION MARK (Only for Staff Mentors)
                          if (isMentor && isStaff) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.verified, color: AppColors.primary, size: 22),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    Center(
                      child: Column(
                        children: [
                          // CONDITIONAL ROLE/DESIGNATION DISPLAY
                          Text(
                            isAlumni
                              ? "${d['designation'] ?? ""} @ ${d['company'] ?? ""}"
                              : isStaff
                                ? "${d['designation'] ?? ""} • ${d['company'] ?? ""}"
                                : "Student",
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isStaff 
                              ? (d['department'] ?? "")
                              : "${d['batch'] ?? ''} • ${d['department'] ?? ''}",
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                          ),

                          // MENTOR BADGE (Only for Staff Mentors)
                          if (isMentor && isStaff) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user, size: 16, color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    "Mentor",
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
                        ],
                      ),
                    ),

                    if (!isAlumni) ...[
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _countTile("Followers", "followers"),
                          _countTile("Following", "following"),
                        ],
                      ),
                    ],

                    const SizedBox(height: 22),

                    if (uid != widget.userId)
                      Center(
                        child: StreamBuilder<bool>(
                          stream: _isMutualFollow(),
                          builder: (_, mutualSnap) {
                            final isMutual = mutualSnap.data == true;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _followButton(),
                                    if (isMutual) ...[
                                      const SizedBox(width: 12),
                                      OutlinedButton.icon(
                                        onPressed: _openChat,
                                        icon: const Icon(Icons.chat_bubble_outline),
                                        label: const Text("Chat"),
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (isMutual && d['linkedin'] != null && d['linkedin'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.open_in_new, size: 18),
                                    label: const Text("View LinkedIn"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed: () => _openLink(context, d['linkedin']),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 32),

                    _sectionTitle("About"),
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Text(
                        (d['bio'] ?? '').toString().trim().isEmpty
                            ? "No bio added yet."
                            : d['bio'],
                        style: const TextStyle(
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    _sectionTitle("Jobs Posted"),
                    const SizedBox(height: 10),
                    _jobsByUser(),

                    const SizedBox(height: 26),

                    _sectionTitle("Events Posted"),
                    const SizedBox(height: 10),
                    _eventsByUser(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyText(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        text,
        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
      ),
    );
  }
}
