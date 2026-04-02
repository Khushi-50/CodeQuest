import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/appcolors.dart';
import '../providers/quest_provider.dart';
import '../models/quest_models.dart';
import '../services/notification_service.dart';
import '../widgets/language_switcher.dart'; // ← new

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<QuestProvider>(context, listen: false);
      if (provider.courseMap.isEmpty && !provider.isLoading) {
        await provider.loadUserData();
      }
      await NotificationService().onAppOpen(
        didActivityToday: provider.didActivityToday,
        streak: provider.streak,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildMapContent(context, provider),
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildStickyHeader(context, provider),
          ),
        ],
      ),
    );
  }

  // ── MAP CONTENT ────────────────────────────────────────────────────────────
  Widget _buildMapContent(BuildContext context, QuestProvider provider) {
    if (provider.isLoading && provider.courseMap.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.courseMap.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          const Text('Unable to connect to Quest Server',
              style: TextStyle(color: Colors.white70)),
          TextButton(
            onPressed: () => provider.loadUserData(),
            child: const Text('RETRY CONNECTION',
                style: TextStyle(color: AppColors.primary)),
          ),
        ]),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 220),
          ...provider.courseMap.map((chapter) => Column(children: [
            _buildChapterHeader(chapter.chapterName),
            ...chapter.subtopics.asMap().entries.map((entry) {
              final index   = entry.key;
              final subtopic = entry.value;
              final status  = provider.getSubtopicStatus(subtopic.subtopicId);
              final isLocked = status == 'locked';

              Alignment alignment = Alignment.center;
              if (index % 4 == 1) alignment = Alignment.centerLeft;
              if (index % 4 == 3) alignment = Alignment.centerRight;

              return Column(children: [
                Align(
                  alignment: alignment,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: _buildProgressNode(context,
                        subtopic: subtopic, status: status),
                  ),
                ),
                _buildConnector(isLocked: isLocked),
              ]);
            }),
          ])),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildProgressNode(BuildContext context,
      {required SubtopicFolder subtopic, required String status}) {
    final provider  = Provider.of<QuestProvider>(context, listen: false);
    final isLocked  = status == 'locked';
    final isCompleted = status == 'completed';

    return Opacity(
      opacity: isLocked ? 0.35 : 1.0,
      child: Stack(alignment: Alignment.center, children: [
        if (isCompleted)
          const SizedBox(
            width: 95, height: 95,
            child: CircularProgressIndicator(
              value: 1.0, strokeWidth: 6,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
            ),
          ),
        _buildMapNode(
          label: subtopic.subtopicName,
          isLocked: isLocked,
          type: isCompleted ? 'star' : (isLocked ? 'lock' : 'play'),
          onTap: () {
            if (!isLocked) {
              provider.startQuiz(context, subtopic.subtopicId,
                  subtopic.subtopicName, subtopic.allQuestions, quizLength: 7);
            }
          },
        ),
      ]),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildStickyHeader(BuildContext context, QuestProvider questData) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Logo | Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CodeQuest',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              Row(children: [
                _statChip('🔥', '${questData.streak}'),
                const SizedBox(width: 12),
                _statChip('💎', '${questData.xp}'),
                const SizedBox(width: 12),
                _statChip('❤️', '${questData.hearts}'),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Language pill + current module card
          Row(
            children: [
              // Language switcher pill ← new
              const LanguageSwitcherPill(),
              const SizedBox(width: 10),
              Expanded(child: _buildProgressCard(questData)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(QuestProvider provider) {
    final chapterName = provider.courseMap.isNotEmpty
        ? provider.courseMap.first.chapterName
        : 'Loading Modules...';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(children: [
        const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('MODULE',
                style: TextStyle(color: AppColors.primary, fontSize: 9,
                    fontWeight: FontWeight.bold, letterSpacing: 1)),
            Text(chapterName,
                style: const TextStyle(color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }

  // ── SMALL WIDGETS ──────────────────────────────────────────────────────────
  Widget _buildChapterHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Text(title.toUpperCase(),
        style: const TextStyle(
            color: Colors.white38, fontWeight: FontWeight.bold,
            letterSpacing: 2, fontSize: 14)),
  );

  Widget _buildConnector({required bool isLocked}) => Container(
    width: 4, height: 40,
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: isLocked ? Colors.white.withOpacity(0.05) : Colors.white10,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _buildMapNode({required String label, required bool isLocked,
      required String type, VoidCallback? onTap}) {
    final icon = type == 'lock'
        ? Icons.lock_outline
        : type == 'star'
            ? Icons.auto_awesome
            : Icons.play_arrow_rounded;
    final color = isLocked ? Colors.grey[900]! : AppColors.secondary;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Column(children: [
        Container(
          width: 75, height: 75,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: color,
            border: isLocked ? Border.all(color: Colors.white10, width: 2) : null,
            boxShadow: isLocked ? [] : [BoxShadow(
                color: AppColors.secondaryGlow.withOpacity(0.3),
                blurRadius: 20, spreadRadius: 2)],
          ),
          child: Icon(icon,
              color: isLocked ? Colors.white10 : Colors.white, size: 35),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                color: isLocked ? Colors.white12 : Colors.white,
                fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }

  Widget _statChip(String emoji, String count) => Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    const SizedBox(width: 4),
    Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  ]);
}
