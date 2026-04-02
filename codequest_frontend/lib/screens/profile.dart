import 'package:flutter/material.dart';
import 'package:hackmol7/screens/account_screen.dart';
import 'package:hackmol7/screens/login_screen.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';
import '../ui/appcolors.dart';
// Ensure AccountScreen exists or comment this out for now
// import 'account_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider for real-time XP/Streak updates
    final provider = context.watch<QuestProvider>();
    final user = provider.user;

    // Show loading if data hasn't arrived yet
    if (provider.isLoading && user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Dynamic Header (Name, Email, Avatar)
            _buildHeader(user),
            const SizedBox(height: 10),

            // 2. Real-time Stats from Provider
            _buildStatsCard(provider),
            const SizedBox(height: 30),

            // 3. Interactive Menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SETTINGS",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _menuTile(
                    Icons.person_outline,
                    "Account Details",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountScreen(),
                        ),
                      );
                      // Navigate to Account Screen logic
                    },
                  ),
                  _toggleTile(
                    Icons.leaderboard_outlined,
                    "Public Profile",
                    true,
                  ),
                  _toggleTile(
                    Icons.notifications_none,
                    "Learning Reminders",
                    true,
                  ),
                  const SizedBox(height: 20),

                  // LOGOUT LOGIC
                  _menuTile(
                    Icons.logout_rounded,
                    "Log Out",
                    color: Colors.redAccent,
                    onTap: () {
                      _showLogoutDialog(context, provider);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(user) {
    final String name = user?.username ?? "Explorer";
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : "U";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withOpacity(0.2), AppColors.background],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.surface,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 40,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user?.email ?? "connecting...",
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(QuestProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("${provider.xp}", "XP", Icons.bolt, Colors.amber),
          _statItem(
            "${provider.streak}",
            "STREAK",
            Icons.fireplace,
            Colors.orange,
          ),
          _statItem(
            "${provider.hearts}",
            "HEARTS",
            Icons.favorite,
            Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  Widget _menuTile(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    Color color = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: color == Colors.white ? AppColors.primary : color,
        ),
        title: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white10,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _toggleTile(IconData icon, String label, bool value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        value: value,
        onChanged: (v) {},
        activeColor: Colors.greenAccent,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, QuestProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Log Out", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to leave?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              provider.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: TextButton.styleFrom(),
            child: const Text(
              "LOGOUT",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
