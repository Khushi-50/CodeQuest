// lib/screens/language_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:hackmol7/providers/quest_provider.dart';
import 'package:hackmol7/screens/goal_selection_screen.dart';
import 'package:provider/provider.dart';
import '../ui/appcolors.dart';
import '../widgets/cyber_button.dart'; // Using your custom button logic

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedLanguage;
  bool _isSubmitting = false;

  final List<Map<String, String>> languages = [
    {
      'name': 'Python',
      'desc': 'The Easy-Talker',
      'emoji': '🐍',
      'id': 'python',
    },
    {
      'name': 'JavaScript',
      'desc': 'The Web-Wizard',
      'emoji': '🌐',
      'id': 'javascript',
    },
    {'name': 'C++', 'desc': 'The Speed-Demon', 'emoji': '⚡', 'id': 'cpp'},
    {'name': 'C', 'desc': 'The Machine-Master', 'emoji': '⚙️', 'id': 'c'},
  ];

  // Replace _saveLanguageToDB with:
  Future<void> _saveLanguageToDB() async {
    if (_selectedLanguage == null) return;
    setState(() => _isSubmitting = true);
    final provider = Provider.of<QuestProvider>(context, listen: false);
    await provider.enrollLanguage(
      _selectedLanguage!,
    ); // uses your existing method
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                "Pick Your Weapon",
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Which logic language will you master first?",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),

              const SizedBox(height: 32),

              Expanded(
                child: ListView.builder(
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final isSelected = _selectedLanguage == lang['id'];

                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedLanguage = lang['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent, // Cleaned up border
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Use the explicit emoji field
                            Text(
                              lang['emoji']!,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['name']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Use the explicit description field
                                Text(
                                  lang['desc']!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              CyberButton(
                label: "START QUEST",
                isLoading: _isSubmitting,
                onPressed: _selectedLanguage == null
                    ? () {} // Provide empty callback instead of null if CyberButton requires non-nullable
                    : () {
                        _saveLanguageToDB().then((_) {
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GoalSelectionScreen(),
                              ),
                            );
                          }
                        });
                      },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
