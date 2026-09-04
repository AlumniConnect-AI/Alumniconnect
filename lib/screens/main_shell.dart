import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/bottom_nav_bar.dart';
import 'home/home_screen.dart';
import 'alumni/alumni_list_screen.dart';
import 'alumni/alumni_mentees_screen.dart';
import 'alumni/post_referral_screen.dart';
import 'alumni/employment_verification_screen.dart';
import 'staff/staff_list_screen.dart';
import 'jobs/jobs_list_screen.dart';
import 'events/events_list_screen.dart';
import 'chat/chat_list_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        final role = snapshot.hasData && snapshot.data!.exists
            ? (snapshot.data!.data() as Map<String, dynamic>)['role'] ?? 'student'
            : 'student';

        final isAlumni = role.toString().toLowerCase() == 'alumni';

        // ── Page lists per role ──────────────────────────────────────────
        final studentPages = [
          HomeScreen(onTabChange: _onTabChange),
          const AlumniListScreen(),
          const StaffListScreen(),
          const JobsListScreen(),
          const EventsListScreen(),
          const ChatListScreen(),
        ];

        final alumniPages = [
          HomeScreen(onTabChange: _onTabChange),
          const AlumniMenteesScreen(),
          const PostReferralScreen(),
          const EmploymentVerificationScreen(),
          const ProfileScreen(),
        ];

        final pages = isAlumni ? alumniPages : studentPages;

        // Guard current index in case of role switch
        final safeIndex = _currentIndex.clamp(0, pages.length - 1);

        return Scaffold(
          body: IndexedStack(
            index: safeIndex,
            children: pages,
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: safeIndex,
            onTap: _onTabChange,
            role: role.toString(),
          ),
        );
      },
    );
  }
}
