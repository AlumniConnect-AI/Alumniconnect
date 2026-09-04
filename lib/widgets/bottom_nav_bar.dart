import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String role; // "student" | "alumni" | other

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role = 'student',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final isAlumni = role.toLowerCase() == 'alumni';

    // ── Tab configs per role ─────────────────────────────────────────────
    final studentItems = [
      _NavItem(Icons.home_rounded, Icons.home_outlined, "Home"),
      _NavItem(Icons.people_rounded, Icons.people_outline_rounded, "Community"),
      _NavItem(Icons.badge_rounded, Icons.badge_outlined, "Staff"),
      _NavItem(Icons.work_rounded, Icons.work_outline_rounded, "Jobs"),
      _NavItem(Icons.event_available_rounded, Icons.event_available_outlined, "Events"),
      _NavItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, "Messages"),
    ];

    final alumniItems = [
      _NavItem(Icons.home_rounded, Icons.home_outlined, "Home"),
      _NavItem(Icons.people_rounded, Icons.people_outline_rounded, "Mentees"),
      _NavItem(Icons.card_giftcard, Icons.card_giftcard_outlined, "Referrals"),
      _NavItem(Icons.verified_user_rounded, Icons.verified_user_outlined, "Verify"),
      _NavItem(Icons.person_rounded, Icons.person_outline_rounded, "Profile"),
    ];

    final items = isAlumni ? alumniItems : studentItems;
    // Messages badge is at index 5 for student, no badge for alumni
    final messagesIndex = isAlumni ? -1 : 5;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardDark.withValues(alpha: 0.75)
                : theme.cardColor.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNeon.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.primaryNeon.withValues(alpha: 0.2)
                    : theme.dividerColor.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 65,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final selected = index == currentIndex;

                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onTap(index);
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // ── Glow pill background ─────────────────
                              AnimatedScale(
                                duration: const Duration(milliseconds: 300),
                                scale: selected ? 1.0 : 0.0,
                                curve: Curves.easeOutBack,
                                child: Container(
                                  height: 36,
                                  width: 36,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.neonCyanPurple,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryNeon
                                            .withValues(alpha: 0.4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Icon(
                                selected
                                    ? items[index].activeIcon
                                    : items[index].inactiveIcon,
                                size: 20,
                                color: selected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary),
                              ),
                              // ── Unread badge (student Messages) ──────
                              if (index == messagesIndex && uid != null)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: _UnreadBadge(uid: uid),
                                ),
                              // ── Pending mentorship badge (alumni) ────
                              if (isAlumni && index == 1 && uid != null)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: _MentorshipBadge(uid: uid),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[index].label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selected
                                  ? (isDark
                                      ? AppColors.primaryNeon
                                      : AppColors.accentPurple)
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Unread chat badge (student) ──────────────────────────────────────────────
class _UnreadBadge extends StatelessWidget {
  final String uid;
  const _UnreadBadge({required this.uid});

  @override
  Widget build(BuildContext context) {
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

        if (totalUnread == 0) return const SizedBox.shrink();

        return _badge('$totalUnread', AppColors.accentPink);
      },
    );
  }
}

// ── Pending mentorship badge (alumni Mentees tab) ────────────────────────────
class _MentorshipBadge extends StatelessWidget {
  final String uid;
  const _MentorshipBadge({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mentorship')
          .where('mentorUid', isEqualTo: uid)
          .where('requestStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return _badge('$count', AppColors.accentPurple);
      },
    );
  }
}

Widget _badge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
      ],
    ),
    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
    child: Text(
      int.tryParse(label) != null && int.parse(label) > 9 ? '9+' : label,
      style: const TextStyle(
          color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    ),
  );
}

class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  _NavItem(this.activeIcon, this.inactiveIcon, this.label);
}
