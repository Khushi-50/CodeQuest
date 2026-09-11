import 'package:flutter/material.dart';
import '../ui/appcolors.dart';

class AssemblyWidget extends StatelessWidget {
  final List<String> wordBank;
  final List<String> assembledParts;
  final bool isAnswerChecked;
  final Function(String) onWordTapped;
  final Function(int) onRemoveTapped;

  const AssemblyWidget({
    super.key,
    required this.wordBank,
    required this.assembledParts,
    required this.isAnswerChecked,
    required this.onWordTapped,
    required this.onRemoveTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The Assembly Area (The Target)
        Container(
          constraints: BoxConstraints(minHeight: 120),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: assembledParts.asMap().entries.map((e) => 
              ActionChip(
                label: Text(e.value, style: const TextStyle(color: Colors.white)),
                backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                onPressed: isAnswerChecked ? null : () => onRemoveTapped(e.key),
              )
            ).toList(),
          ),
        ),
        const SizedBox(height: 30),
        // The Word Bank (The Source)
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: wordBank.map((word) {
            bool isUsed = assembledParts.contains(word);
            return Opacity(
              opacity: isUsed ? 0.3 : 1.0,
              child: ActionChip(
                label: Text(word, style: const TextStyle(color: Colors.white)),
                backgroundColor: AppColors.surfaceLight,
                onPressed: (isAnswerChecked || isUsed) ? null : () => onWordTapped(word),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}