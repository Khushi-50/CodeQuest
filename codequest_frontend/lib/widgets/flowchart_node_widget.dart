import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/appcolors.dart';

enum NodeStatus { locked, visible, inProgress, completed }

/// Data model for a learning node
class LearningNodeData {
  final String id;
  final String title;
  final String emoji;
  final String storyText;
  final NodeStatus status;
  final double positionX;
  final double positionY;
  final String? parentId;

  const LearningNodeData({
    required this.id,
    required this.title,
    required this.emoji,
    required this.storyText,
    required this.status,
    required this.positionX,
    required this.positionY,
    this.parentId,
  });
}

/// FlowchartNodeWidget
/// A single node on the learning map. Has 4 states:
///   locked     → gray, padlock
///   visible    → pulsing cyan glow, ready
///   inProgress → progress ring, partially filled
///   completed  → solid checkmark, glowing line to next
///
/// Use inside a Stack+InteractiveViewer on the map screen.
class FlowchartNodeWidget extends StatefulWidget {
  final LearningNodeData node;
  final VoidCallback? onTap;
  final double progress; // 0.0 to 1.0, used only for inProgress state

  const FlowchartNodeWidget({
    super.key,
    required this.node,
    this.onTap,
    this.progress = 0.0,
  });

  @override
  State<FlowchartNodeWidget> createState() => _FlowchartNodeWidgetState();
}

class _FlowchartNodeWidgetState extends State<FlowchartNodeWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnim;

  @override
  void initState() {
    super.initState();
    if (widget.node.status == NodeStatus.visible) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat(reverse: true);
      _pulseAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.node.status == NodeStatus.locked
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onTap?.call();
            },
      child: _buildNodeBody(),
    );
  }

  Widget _buildNodeBody() {
    switch (widget.node.status) {
      case NodeStatus.locked:
        return _buildLockedNode();
      case NodeStatus.visible:
        return _buildVisibleNode();
      case NodeStatus.inProgress:
        return _buildInProgressNode();
      case NodeStatus.completed:
        return _buildCompletedNode();
    }
  }

  // ─────────── LOCKED ───────────
  Widget _buildLockedNode() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF21262D), Color(0xFF0B0E14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white12, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.lock_outline, color: Colors.white24, size: 24),
      ),
    );
  }

  // ─────────── VISIBLE (pulsing, ready to start) ───────────
  Widget _buildVisibleNode() {
    return AnimatedBuilder(
      animation: _pulseAnim ?? kAlwaysDismissedAnimation,
      builder: (context, child) {
        final glow = _pulseAnim?.value ?? 0.5;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: glow * 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            // Main node
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.6 + glow * 0.4),
                  width: 2.5,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.node.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────── IN PROGRESS ───────────
  Widget _buildInProgressNode() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 74,
          height: 74,
          child: CircularProgressIndicator(
            value: widget.progress,
            strokeWidth: 3,
            backgroundColor: Colors.white12,
            color: AppColors.secondary,
          ),
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4), width: 1),
          ),
          child: Center(
            child: Text(
              widget.node.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────── COMPLETED ───────────
  Widget _buildCompletedNode() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              widget.node.emoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(Icons.check, size: 13, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

/// NodeLabel — small text label below a node on the map
class NodeLabel extends StatelessWidget {
  final String title;
  final NodeStatus status;

  const NodeLabel({super.key, required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == NodeStatus.locked
        ? Colors.white24
        : status == NodeStatus.completed
            ? AppColors.primary
            : AppColors.textSecondary;

    return Container(
      constraints: const BoxConstraints(maxWidth: 90),
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: status == NodeStatus.visible ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

/// NodeConnector — draws lines between nodes using CustomPaint
/// Use this as the background layer in your InteractiveViewer Stack.
class NodeConnectorPainter extends CustomPainter {
  final List<LearningNodeData> nodes;

  NodeConnectorPainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final completedPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pendingPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final nodeMap = {for (final n in nodes) n.id: n};

    for (final node in nodes) {
      if (node.parentId == null) continue;
      final parent = nodeMap[node.parentId];
      if (parent == null) continue;

      // Node center is at (posX + 35, posY + 35) since node width = 70
      final start = Offset(parent.positionX + 35, parent.positionY + 35);
      final end = Offset(node.positionX + 35, node.positionY + 35);

      // Use a curved path for a nicer flow
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx,
          (start.dy + end.dy) / 2,
          end.dx,
          (start.dy + end.dy) / 2,
          end.dx,
          end.dy,
        );

      final isCompleted = parent.status == NodeStatus.completed;
      canvas.drawPath(path, isCompleted ? completedPaint : pendingPaint);
    }
  }

  @override
  bool shouldRepaint(NodeConnectorPainter oldDelegate) =>
      oldDelegate.nodes != nodes;
}

/// NodeStoryModal — bottom sheet shown when user taps a node
/// Shows the story/metaphor text before they start the chapter.
class NodeStoryModal extends StatelessWidget {
  final LearningNodeData node;
  final VoidCallback onStartChapter;

  const NodeStoryModal({
    super.key,
    required this.node,
    required this.onStartChapter,
  });

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 24),
          // Chapter header
          Row(
            children: [
              Text(node.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (node.status == NodeStatus.completed)
                      const Text(
                        'Completed ✓',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Divider
          Container(height: 1, color: Colors.white10),
          const SizedBox(height: 20),
          // Story text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_stories_outlined,
                        size: 16, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Text(
                      'The Story',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  node.storyText,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // CTA button
          if (node.status != NodeStatus.locked)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onStartChapter();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  node.status == NodeStatus.completed
                      ? 'Review Chapter'
                      : 'Start Chapter →',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
