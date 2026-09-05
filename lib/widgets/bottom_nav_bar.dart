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
    final messagesIndex = isAlumni ? -1 : 5;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNeon.withOpacity(0.18),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardDark.withOpacity(0.70)
                    : theme.cardColor.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark
                      ? AppColors.primaryNeon.withOpacity(0.3)
                      : theme.dividerColor.withOpacity(0.6),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final selected = index == currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onTap(index);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            duration: const Duration(milliseconds: 250),
                            scale: selected ? 1.12 : 1.0,
                            curve: Curves.easeOutCubic,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // ── Liquid Glass Hover Pill ─────────────────
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutBack,
                                  height: selected ? 38 : 0,
                                  width: selected ? 38 : 0,
                                  decoration: BoxDecoration(
                                    gradient: selected
                                        ? AppGradients.neonCyanPurple
                                        : null,
                                    shape: BoxShape.circle,
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryNeon
                                                  .withOpacity(0.45),
                                              blurRadius: 12,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : [],
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
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
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
                            child: Text(
                              items[index].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
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
