import 'package:flutter/material.dart';
import '../ui/appcolors.dart';

/// BugFixWidget
/// Shows buggy code in a dark editor-style block with the buggy line highlighted.
/// User selects the correct fix from MCQ-style options.
///
/// question_type: "bug_fix"
class BugFixWidget extends StatelessWidget {
  final String buggyCode;        // full code string (newline-separated)
  final int bugLineNumber;       // 1-indexed line number containing the bug
  final List<String> options;    // fix options
  final int? selectedIndex;      // currently selected option index
  final bool isAnswerChecked;
  final bool isCorrect;
  final String correctAnswer;
  final Function(int) onSelected;

  const BugFixWidget({
    super.key,
    required this.buggyCode,
    required this.bugLineNumber,
    required this.options,
    required this.selectedIndex,
    required this.isAnswerChecked,
    required this.isCorrect,
    required this.correctAnswer,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final lines = buggyCode.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildCodeBlock(lines),
        const SizedBox(height: 28),
        _buildOptionsLabel(),
        const SizedBox(height: 12),
        ...options.asMap().entries.map((e) => _buildOption(e.key, e.value)),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.bug_report_outlined, size: 14, color: AppColors.accent),
              SizedBox(width: 6),
              Text(
                'Find the Bug',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodeBlock(List<String> lines) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Editor title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F56)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF27C93F)),
                const SizedBox(width: 12),
                const Text(
                  'main.c',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // Code lines
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: lines.asMap().entries.map((e) {
                final lineNum = e.key + 1;
                final isBugLine = lineNum == bugLineNumber;
                return _buildCodeLine(lineNum, e.value, isBugLine);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeLine(int lineNum, String code, bool isBug) {
    return Container(
      width: double.infinity,
      color: isBug ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line number gutter
          Container(
            width: 44,
            padding: const EdgeInsets.only(right: 16, left: 16),
            child: Text(
              '$lineNum',
              style: TextStyle(
                color: isBug ? AppColors.accent.withValues(alpha: 0.8) : Colors.white24,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
            ),
          ),
          // Bug indicator
          SizedBox(
            width: 18,
            child: isBug
                ? const Icon(Icons.arrow_right, size: 16, color: AppColors.accent)
                : const SizedBox(),
          ),
          // Code text
          Expanded(
            child: Text(
              code,
              style: TextStyle(
                color: isBug ? AppColors.accent.withValues(alpha: 0.9) : Colors.white70,
                fontSize: 14,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _buildOptionsLabel() {
    return const Text(
      'What is wrong?',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildOption(int index, String text) {
    final isSelected = selectedIndex == index;
    final isThisCorrect = isAnswerChecked && text == correctAnswer;
    final isThisWrong = isAnswerChecked && isSelected && !isCorrect;

    Color borderColor = Colors.white12;
    Color bgColor = AppColors.surface;

    if (isThisCorrect) {
      borderColor = Colors.greenAccent.withValues(alpha: 0.7);
      bgColor = Colors.green.withValues(alpha: 0.1);
    } else if (isThisWrong) {
      borderColor = AppColors.accent.withValues(alpha: 0.7);
      bgColor = AppColors.accent.withValues(alpha: 0.08);
    } else if (isSelected) {
      borderColor = AppColors.secondary;
      bgColor = AppColors.secondary.withValues(alpha: 0.1);
    }

    return GestureDetector(
      onTap: isAnswerChecked ? null : () => onSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Option letter badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.secondary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: isSelected ? AppColors.secondary : Colors.white12,
                ),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C...
                  style: TextStyle(
                    color: isSelected ? AppColors.secondary : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            if (isAnswerChecked)
              Icon(
                isThisCorrect ? Icons.check_circle : (isThisWrong ? Icons.cancel : null),
                color: isThisCorrect ? Colors.greenAccent : AppColors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
