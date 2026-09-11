import 'package:flutter/material.dart';
import '../ui/appcolors.dart';

class MatchingWidget extends StatelessWidget {
  final List<String> leftItems;
  final List<String> rightItems;
  final int? selectedLeftIndex;
  final Map<int, int> currentMatches; // Maps LeftIndex to RightIndex
  final bool isAnswerChecked;
  final Function(int) onLeftTap;
  final Function(int) onRightTap;

  const MatchingWidget({
    super.key,
    required this.leftItems,
    required this.rightItems,
    required this.selectedLeftIndex,
    required this.currentMatches,
    required this.isAnswerChecked,
    required this.onLeftTap,
    required this.onRightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Column (Terms)
        Expanded(child: _buildColumn(leftItems, true)),
        const SizedBox(width: 40),
        // Right Column (Definitions)
        Expanded(child: _buildColumn(rightItems, false)),
      ],
    );
  }

  Widget _buildColumn(List<String> items, bool isLeft) {
    return Column(
      children: items.asMap().entries.map((entry) {
        int idx = entry.key;
        String text = entry.value;

        bool isSelected = isLeft
            ? (selectedLeftIndex == idx)
            : currentMatches.containsValue(idx);
        bool isMatched = isLeft
            ? currentMatches.containsKey(idx)
            : currentMatches.containsValue(idx);

        return GestureDetector(
          onTap: isAnswerChecked
              ? null
              : () => isLeft ? onLeftTap(idx) : onRightTap(idx),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.secondary.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.secondary
                    : (isMatched
                          ? Colors.greenAccent.withValues(alpha: 0.5)
                          : Colors.white10),
              ),
            ),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
