import 'package:flutter/material.dart';
import '../ui/appcolors.dart';

class TrueFalseWidget extends StatelessWidget {
  final int? selectedIndex;
  final bool isAnswerChecked;
  final bool isCorrect;
  final String correctAnswer;
  final Function(int) onSelected;

  const TrueFalseWidget({
    super.key,
    required this.selectedIndex,
    required this.isAnswerChecked,
    required this.isCorrect,
    required this.correctAnswer,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildTFCard(0, "TRUE", Icons.check_circle_outline),
        const SizedBox(width: 16),
        _buildTFCard(1, "FALSE", Icons.highlight_off),
      ],
    );
  }

  Widget _buildTFCard(int index, String label, IconData icon) {
    bool isThisSelected = selectedIndex == index;
    Color cardColor = AppColors.surface;
    Color contentColor = Colors.white70;

    if (isThisSelected) {
      contentColor = Colors.white;
      if (isAnswerChecked) {
        cardColor = isCorrect
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.red.withValues(alpha: 0.2);
      } else {
        cardColor = AppColors.secondary.withValues(alpha: 0.2);
      }
    }

    return Expanded(
      child: GestureDetector(
        onTap: isAnswerChecked ? null : () => onSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 140,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isThisSelected
                  ? (isAnswerChecked
                        ? (isCorrect ? Colors.greenAccent : Colors.redAccent)
                        : AppColors.secondary)
                  : Colors.white10,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: isThisSelected
                    ? (isAnswerChecked
                          ? (isCorrect ? Colors.greenAccent : Colors.redAccent)
                          : AppColors.secondary)
                    : Colors.white24,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: contentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
