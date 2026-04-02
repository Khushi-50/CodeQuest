// language_switcher.dart
// Drop-in widget that shows the current language pill in the home header.
// Tap it → bottom sheet lets user switch or enroll in new languages.
// Usage: place _LanguageSwitcherPill() anywhere in hom.dart's header row.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';
import '../ui/appcolors.dart';

class LanguageSwitcherPill extends StatelessWidget {
  const LanguageSwitcherPill({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestProvider>();
    final lang = provider.currentLanguageInfo;

    return GestureDetector(
      onTap: () => _showSwitcher(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              lang.name,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }

  void _showSwitcher(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _LanguageSwitcherSheet(),
    );
  }
}

class _LanguageSwitcherSheet extends StatelessWidget {
  const _LanguageSwitcherSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Switch Language',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your progress is saved per language.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Language cards
          ...kAvailableLanguages.map((lang) {
            final isEnrolled = provider.enrolledLanguages.contains(lang.id);
            final isCurrent = provider.currentLanguage == lang.id;

            return GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                if (isEnrolled) {
                  await provider.switchLanguage(lang.id);
                } else {
                  await provider.enrollLanguage(lang.id);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.primary
                        : (isEnrolled ? Colors.white70 : Colors.white10),
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(lang.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.name,
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.primary
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            lang.tagline,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _badge(isCurrent, isEnrolled),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _badge(bool isCurrent, bool isEnrolled) {
    if (isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'ACTIVE',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    if (isEnrolled) {
      return const Icon(
        Icons.check_circle_outline,
        color: Colors.white38,
        size: 20,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: const Text(
        '+ ADD',
        style: TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
