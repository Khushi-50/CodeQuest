import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/appcolors.dart';

/// ErrorSpotWidget
/// Shows code line-by-line. User taps the line they think contains the error.
///
/// question_type: "error_spot"
class ErrorSpotWidget extends StatelessWidget {
  final String buggyCode;        // full code string (newline-separated)
  final int correctLineIndex;    // 0-indexed correct answer
  final int? selectedLineIndex;  // 0-indexed user selection (null = none)
  final bool isAnswerChecked;
  final Function(int) onLineTapped;

  const ErrorSpotWidget({
    super.key,
    required this.buggyCode,
    required this.correctLineIndex,
    required this.selectedLineIndex,
    required this.isAnswerChecked,
    required this.onLineTapped,
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
        if (!isAnswerChecked) ...[
          const SizedBox(height: 16),
          _buildHint(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.touch_app_outlined, size: 14, color: AppColors.warning),
              SizedBox(width: 6),
              Text(
                'Tap the Error Line',
                style: TextStyle(
                  color: AppColors.warning,
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
                const Spacer(),
                const Text(
                  'Find the error →',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // Lines
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: lines.asMap().entries.map((e) {
                return _buildTappableLine(e.key, e.value, lines.length);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappableLine(int index, String code, int total) {
    final isSelected = selectedLineIndex == index;
    final isCorrect = isAnswerChecked && index == correctLineIndex;
    final isWrong = isAnswerChecked && isSelected && index != correctLineIndex;

    Color lineColor = Colors.transparent;
    Color lineNumColor = Colors.white24;
    Color codeColor = Colors.white70;

    if (isCorrect) {
      lineColor = Colors.green.withValues(alpha: 0.12);
      lineNumColor = Colors.greenAccent;
      codeColor = Colors.white;
    } else if (isWrong) {
      lineColor = AppColors.accent.withValues(alpha: 0.1);
      lineNumColor = AppColors.accent;
      codeColor = AppColors.accent.withValues(alpha: 0.8);
    } else if (isSelected) {
      lineColor = AppColors.warning.withValues(alpha: 0.1);
      lineNumColor = AppColors.warning;
      codeColor = Colors.white;
    }

    // Empty lines (blank) are not tappable
    final isBlank = code.trim().isEmpty;

    return GestureDetector(
      onTap: (isAnswerChecked || isBlank)
          ? null
          : () {
              HapticFeedback.selectionClick();
              onLineTapped(index);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        color: lineColor,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line number
            SizedBox(
              width: 44,
              child: Text(
                isBlank ? '' : '${index + 1}',
                style: TextStyle(
                  color: lineNumColor,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 16),
            // Status icon
            SizedBox(
              width: 16,
              child: isCorrect
                  ? const Icon(Icons.check_circle, size: 14, color: Colors.greenAccent)
                  : isWrong
                      ? const Icon(Icons.cancel, size: 14, color: AppColors.accent)
                      : isSelected
                          ? const Icon(Icons.arrow_right, size: 14, color: AppColors.warning)
                          : const SizedBox(),
            ),
            const SizedBox(width: 4),
            // Code
            Expanded(
              child: Text(
                code,
                style: TextStyle(
                  color: codeColor,
                  fontSize: 14,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
            // Tap indicator (shown only when not checked and not blank)
            if (!isAnswerChecked && !isBlank)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.touch_app,
                  size: 14,
                  color: isSelected
                      ? AppColors.warning
                      : Colors.white12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 13, color: Colors.white24),
        const SizedBox(width: 6),
        const Text(
          'Tap any line to select it as the error',
          style: TextStyle(color: Colors.white24, fontSize: 12),
        ),
      ],
    );
  }

  Widget _dot(Color color) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
