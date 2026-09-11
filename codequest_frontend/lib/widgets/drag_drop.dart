import 'package:flutter/material.dart';
import '../ui/appcolors.dart';

class DragDropWidget extends StatelessWidget {
  final List<String> codeParts;
  final List<String> placedTokens;
  final List<String> availableTokens;
  final bool isAnswerChecked;
  final Function(int, String) onTokenDropped;

  const DragDropWidget({
    super.key,
    required this.codeParts,
    required this.placedTokens,
    required this.availableTokens,
    required this.isAnswerChecked,
    required this.onTokenDropped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The Code Area with Blanks
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: _buildCodeContent(),
          ),
        ),
        const SizedBox(height: 30),
        // The Available Tokens Pool
        if (!isAnswerChecked)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableTokens
                .map((token) => _buildDraggableToken(token))
                .toList(),
          ),
      ],
    );
  }

  List<Widget> _buildCodeContent() {
    List<Widget> widgets = [];
    for (int i = 0; i < codeParts.length; i++) {
      widgets.add(
        Text(
          codeParts[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'monospace',
          ),
        ),
      );
      if (i < codeParts.length - 1) {
        widgets.add(_buildDropTarget(i));
      }
    }
    return widgets;
  }

  Widget _buildDropTarget(int index) {
    String content = placedTokens[index];
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onTokenDropped(index, details.data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: content.isEmpty
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.secondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: content.isEmpty ? Colors.white24 : AppColors.secondary,
              style: content.isEmpty ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          constraints: const BoxConstraints(minWidth: 50, minHeight: 30),
          child: Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableToken(String token) {
    return Draggable<String>(
      data: token,
      feedback: Material(
        color: Colors.transparent,
        child: _tokenChip(token, true),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _tokenChip(token, false)),
      child: _tokenChip(token, false),
    );
  }

  Widget _tokenChip(String text, bool isFeedback) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
        boxShadow: isFeedback
            ? [BoxShadow(color: AppColors.secondaryGlow, blurRadius: 10)]
            : [],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
