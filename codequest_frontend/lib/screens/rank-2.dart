import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';
import '../ui/appcolors.dart';

class LeaderboardEntry {
  final String username;
  final int xp;
  final int rank;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.username,
    required this.xp,
    required this.rank,
    this.isCurrentUser = false,
  });
}

class RankScreen extends StatefulWidget {
  const RankScreen({super.key});

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen>
    with SingleTickerProviderStateMixin {
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _animController;

  // ── Android emulator needs 10.0.2.2, iOS uses localhost.
  // Adjust this to your LAN IP for physical device testing.
  static const String _baseUrl = 'http://10.0.2.2:5050/api';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fetchLeaderboard();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/user/leaderboard'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle multiple possible response shapes from backend
        final List rawList =
            data['leaderboard'] ?? data['users'] ?? data['data'] ?? [];

        final currentUsername =
            context.read<QuestProvider>().user?.username ?? '';

        setState(() {
          _entries = rawList.asMap().entries.map((e) {
            final u = e.value as Map<String, dynamic>;
            return LeaderboardEntry(
              username: u['username'] ?? 'Unknown',
              xp: u['xp'] ?? 0,
              rank: e.key + 1,
              isCurrentUser: (u['username'] ?? '') == currentUsername,
            );
          }).toList();
          _isLoading = false;
        });

        _animController.forward(from: 0);
        return;
      }

      // Non-200 → fall through to mock
      _loadMockData();
    } catch (e) {
      // Network error → show mock data so UI is always useful at hackathon
      _loadMockData();
    }
  }

  /// Shows realistic-looking placeholder data when the server is unreachable.
  /// Great for demos — remove/disable before production.
  void _loadMockData() {
    final currentUsername = context.read<QuestProvider>().user?.username ?? '';

    final mock = [
      {'username': 'Aryan Sharma', 'xp': 1240},
      {
        'username': currentUsername.isNotEmpty ? currentUsername : 'You',
        'xp': 980,
      },
      {'username': 'Priya Mehta', 'xp': 870},
      {'username': 'Rahul Dev', 'xp': 750},
      {'username': 'Sneha K', 'xp': 640},
      {'username': 'Vikram S', 'xp': 520},
      {'username': 'Anita R', 'xp': 410},
    ];

    // Sort descending by XP
    mock.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));

    setState(() {
      _entries = mock.asMap().entries.map((e) {
        return LeaderboardEntry(
          username: e.value['username'] as String,
          xp: e.value['xp'] as int,
          rank: e.key + 1,
          isCurrentUser:
              e.value['username'] == currentUsername ||
              (currentUsername.isEmpty && e.key == 1),
        );
      }).toList();
      _isLoading = false;
      _error = null; // Don't show error — show mock gracefully
    });

    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Leaderboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Top coders this week',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
          IconButton(
            onPressed: _fetchLeaderboard,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: Colors.white24,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No rankings yet.\nBe the first to complete a lesson!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _fetchLeaderboard,
              child: const Text(
                'Refresh',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    final topThree = _entries.take(3).toList();
    final rest = _entries.skip(3).toList();

    return Column(
      children: [
        const SizedBox(height: 24),

        // Podium
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (topThree.length > 1)
                _podiumItem(topThree[1], 110, Colors.grey[400]!),
              const SizedBox(width: 10),
              if (topThree.isNotEmpty)
                _podiumItem(topThree[0], 150, Colors.amber),
              const SizedBox(width: 10),
              if (topThree.length > 2)
                _podiumItem(topThree[2], 90, Colors.orangeAccent),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Rest of list
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: rest.length,
              itemBuilder: (context, i) {
                return AnimatedBuilder(
                  animation: _animController,
                  builder: (_, child) {
                    final delay = (i * 0.1).clamp(0.0, 0.8);
                    final progress = Curves.easeOut.transform(
                      ((_animController.value - delay) / (1 - delay)).clamp(
                        0.0,
                        1.0,
                      ),
                    );
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - progress)),
                      child: Opacity(opacity: progress, child: child),
                    );
                  },
                  child: _listTile(rest[i]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _podiumItem(LeaderboardEntry entry, double height, Color color) {
    final medals = ['🥇', '🥈', '🥉'];
    final medal = entry.rank <= 3 ? medals[entry.rank - 1] : '#${entry.rank}';

    return Column(
      children: [
        if (entry.isCurrentUser) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'You',
              style: TextStyle(color: AppColors.primary, fontSize: 10),
            ),
          ),
          const SizedBox(height: 4),
        ] else
          const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.15),
            child: Text(
              entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          entry.username.length > 8
              ? '${entry.username.substring(0, 7)}…'
              : entry.username,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          '${entry.xp} XP',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Container(
          width: 82,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Center(
            child: Text(medal, style: const TextStyle(fontSize: 24)),
          ),
        ),
      ],
    );
  }

  Widget _listTile(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isCurrentUser ? AppColors.primary : Colors.white10,
          width: entry.isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.secondary.withOpacity(0.25),
            child: Text(
              entry.username[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.isCurrentUser ? '${entry.username} (You)' : entry.username,
              style: TextStyle(
                color: entry.isCurrentUser ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${entry.xp} XP',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
