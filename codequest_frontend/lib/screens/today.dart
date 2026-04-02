import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';
import '../ui/appcolors.dart';

class _DailyTask {
  final String title;
  final String description;
  final String emoji;
  final int xpReward;
  final int target;
  int current;
  bool get isDone => current >= target;

  _DailyTask({
    required this.title,
    required this.description,
    required this.emoji,
    required this.xpReward,
    required this.target,
    this.current = 0,
  });
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  // These would come from your backend in a real implementation.
  // For now, progress is driven by the provider's XP/streak values.
  late List<_DailyTask> _tasks;

  @override
  void initState() {
    super.initState();
    _buildTasks();
  }

  void _buildTasks() {
    final provider = Provider.of<QuestProvider>(context, listen: false);
    _tasks = [
      _DailyTask(
        title: 'Complete a lesson',
        description: 'Finish any subtopic on the map',
        emoji: '📚',
        xpReward: 20,
        target: 1,
        current: provider.xp > 0 ? 1 : 0, // rough proxy
      ),
      _DailyTask(
        title: 'Answer 10 questions',
        description: 'Keep tapping through quiz questions',
        emoji: '❓',
        xpReward: 30,
        target: 10,
        current: (provider.xp ~/ 5).clamp(0, 10),
      ),
      _DailyTask(
        title: 'Maintain your streak',
        description: 'Log in and complete at least one lesson',
        emoji: '🔥',
        xpReward: 15,
        target: 1,
        current: provider.streak > 0 ? 1 : 0,
      ),
      _DailyTask(
        title: 'Earn 50 XP today',
        description: 'Complete lessons and answer correctly',
        emoji: '💎',
        xpReward: 25,
        target: 50,
        current: provider.xp.clamp(0, 50),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestProvider>();
    final doneCount = _tasks.where((t) => t.isDone).length;
    final totalXpAvailable = _tasks.fold<int>(0, (sum, t) => sum + t.xpReward);
    final earnedXp = _tasks
        .where((t) => t.isDone)
        .fold<int>(0, (sum, t) => sum + t.xpReward);
    final overallProgress = doneCount / _tasks.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Quest',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _streakBadge(provider.streak),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _todayDateString(),
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),

              const SizedBox(height: 24),

              // Daily progress summary card
              _summaryCard(
                doneCount,
                earnedXp,
                totalXpAvailable,
                overallProgress,
              ),

              const SizedBox(height: 28),

              const Text(
                'TODAY\'S TASKS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              // Task cards
              ...(_tasks.map((task) => _taskCard(task))),

              const SizedBox(height: 28),

              // XP earned today
              _xpCard(provider),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _streakBadge(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: streak > 0 ? Colors.orange.withOpacity(0.15) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: streak > 0 ? Colors.orange.withOpacity(0.4) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '$streak day${streak == 1 ? '' : 's'}',
            style: TextStyle(
              color: streak > 0 ? Colors.orange : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(int done, int earned, int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$done / ${_tasks.length} tasks complete',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '+$earned XP earned',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              color: progress == 1.0 ? Colors.greenAccent : AppColors.primary,
              minHeight: 8,
            ),
          ),
          if (progress == 1.0) ...[
            const SizedBox(height: 10),
            const Text(
              'All tasks complete! Amazing work today 🎉',
              style: TextStyle(color: Colors.greenAccent, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _taskCard(_DailyTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: task.isDone
            ? Colors.greenAccent.withOpacity(0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isDone
              ? Colors.greenAccent.withOpacity(0.3)
              : Colors.white10,
          width: task.isDone ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Emoji icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: task.isDone
                  ? Colors.greenAccent.withOpacity(0.12)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(task.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),

          // Title & progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: task.isDone
                              ? Colors.greenAccent
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '+${task.xpReward} XP',
                      style: TextStyle(
                        color: task.isDone ? Colors.greenAccent : Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (task.current / task.target).clamp(0.0, 1.0),
                          backgroundColor: Colors.white10,
                          color: task.isDone
                              ? Colors.greenAccent
                              : AppColors.primary,
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${task.current.clamp(0, task.target)} / ${task.target}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Checkmark
          const SizedBox(width: 10),
          Icon(
            task.isDone
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: task.isDone ? Colors.greenAccent : Colors.white12,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _xpCard(QuestProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Text('💎', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total XP',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  '${provider.xp} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Level',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                '${(provider.xp ~/ 100) + 1}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _todayDateString() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}
