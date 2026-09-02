import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';
import 'home/home_screen.dart';
import 'alumni/alumni_list_screen.dart';
import 'staff/staff_list_screen.dart';
import 'jobs/jobs_list_screen.dart';
import 'events/events_list_screen.dart';
import 'chat/chat_list_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(onTabChange: _onTabChange),
      const AlumniListScreen(),
      const StaffListScreen(), // ✅ ADDED STAFF AT INDEX 2
      const JobsListScreen(),
      const EventsListScreen(),
      const ChatListScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabChange,
      ),
    );
  }
}
