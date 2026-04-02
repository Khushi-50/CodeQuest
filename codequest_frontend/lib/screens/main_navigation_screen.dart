import 'package:flutter/material.dart';
import '../ui/appcolors.dart';
import 'home.dart'; // Your Zig-Zag Map
import 'rank-2.dart';
import 'profile.dart';
import 'today.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // 1. List of your actual screens
  final List<Widget> _pages = [
    const HomeScreen(), // The Zig-Zag Map from your screenshot
    const RankScreen(), // Leaderboard
    const TodayScreen(), // Daily Goals
    const ProfileScreen(), // User Stats
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // 2. IndexedStack keeps all pages "alive" in the background
      body: IndexedStack(index: _selectedIndex, children: _pages),

      // 3. Bottom Nav matching your screenshot
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary, // That Electric Blue
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: 'RANK',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'TODAY',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
          ],
        ),
      ),
    );
  }
}
