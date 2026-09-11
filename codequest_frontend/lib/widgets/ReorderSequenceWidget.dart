import 'package:flutter/material.dart';
import '../ui/appcolors.dart';

class ReorderSequenceWidget extends StatelessWidget {
  final List<String> items;
  final bool isAnswerChecked;
  final Function(int, int) onReorder;

  const ReorderSequenceWidget({
    super.key,
    required this.items,
    required this.isAnswerChecked,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400, // Fixed height for the scrollable list
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ReorderableListView(
        padding: const EdgeInsets.all(12),
        onReorder: onReorder,
        buildDefaultDragHandles: !isAnswerChecked,
        children: [
          for (int i = 0; i < items.length; i++)
            Container(
              key: ValueKey(items[i]),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1D212B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.drag_indicator, color: Colors.white24),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      items[i],
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
