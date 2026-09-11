import 'package:flutter/material.dart';
import '../ui/appcolors.dart';

/// Data model for a single day's activity
class StreakDayData {
  final DateTime date;
  final int xp;
  final int questionsAnswered;
  final bool dailyGoalMet;

  const StreakDayData({
    required this.date,
    required this.xp,
    required this.questionsAnswered,
    required this.dailyGoalMet,
  });

  factory StreakDayData.fromJson(Map<String, dynamic> json) {
    return StreakDayData(
      date: DateTime.parse(json['date'] as String),
      xp: (json['xpEarned'] as num?)?.toInt() ?? 0,
      questionsAnswered: (json['questionsAnswered'] as num?)?.toInt() ?? 0,
      dailyGoalMet: json['dailyGoalMet'] as bool? ?? false,
    );
  }
}

/// HeatmapWidget
/// LeetCode-style 52-week activity grid showing daily XP.
/// Renders as a horizontally scrollable calendar.
///
/// Usage:
/// HeatmapWidget(
///   data: streakDays,      // list of StreakDayData from API
///   onDayTapped: (day) {}  // show tooltip/modal
/// )
class HeatmapWidget extends StatefulWidget {
  final List<StreakDayData> data;
  final Function(StreakDayData)? onDayTapped;

  const HeatmapWidget({
    super.key,
    required this.data,
    this.onDayTapped,
  });

  @override
  State<HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends State<HeatmapWidget> {
  StreakDayData? _tooltipDay;
  final double _cellSize = 14.0;
  final double _cellGap = 3.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendRow(),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,   // most recent on the right
          child: _buildGrid(),
        ),
        if (_tooltipDay != null) ...[
          const SizedBox(height: 12),
          _buildTooltip(_tooltipDay!),
        ],
        const SizedBox(height: 12),
        _buildIntensityLegend(),
      ],
    );
  }

  /// Build a map of date → data for fast lookup
  Map<String, StreakDayData> _buildDataMap() {
    return {
      for (final d in widget.data)
        '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}': d
    };
  }

  Widget _buildGrid() {
    final dataMap = _buildDataMap();
    final today = DateTime.now();

    // Find the Sunday of the week containing today
    final dayOfWeek = today.weekday % 7; // 0 = Sunday
    final startOfThisWeek = today.subtract(Duration(days: dayOfWeek));

    // Go back 52 weeks from start of this week
    final gridStart = startOfThisWeek.subtract(const Duration(days: 52 * 7));

    final dayLabels = ['', 'M', '', 'W', '', 'F', ''];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day-of-week labels on the left
        Column(
          children: dayLabels.map((label) {
            return SizedBox(
              height: _cellSize + _cellGap,
              width: 16,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(width: 4),
        // 53 week columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(53, (weekIndex) {
            return Column(
              children: List.generate(7, (dayIndex) {
                final cellDate = gridStart.add(Duration(days: weekIndex * 7 + dayIndex));
                if (cellDate.isAfter(today)) {
                  return SizedBox(
                    width: _cellSize + _cellGap,
                    height: _cellSize + _cellGap,
                  );
                }
                final key =
                    '${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}';
                final dayData = dataMap[key];
                return _buildCell(cellDate, dayData);
              }),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCell(DateTime date, StreakDayData? data) {
    final xp = data?.xp ?? 0;
    final color = _cellColor(xp, data?.dailyGoalMet ?? false);

    return GestureDetector(
      onTap: () {
        if (data != null) {
          setState(() {
            _tooltipDay = (_tooltipDay?.date == data.date) ? null : data;
          });
          widget.onDayTapped?.call(data);
        }
      },
      child: Container(
        width: _cellSize,
        height: _cellSize,
        margin: EdgeInsets.only(
          right: _cellGap / 2,
          left: _cellGap / 2,
          bottom: _cellGap,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: (_tooltipDay?.date.day == date.day &&
                  _tooltipDay?.date.month == date.month &&
                  _tooltipDay?.date.year == date.year)
              ? Border.all(color: AppColors.primary, width: 1)
              : null,
        ),
      ),
    );
  }

  Color _cellColor(int xp, bool goalMet) {
    if (xp == 0) return AppColors.surfaceLight.withValues(alpha: 0.4);
    if (goalMet) return AppColors.primary; // full glow = goal met
    if (xp >= 100) return AppColors.primary.withValues(alpha: 0.75);
    if (xp >= 50) return AppColors.primary.withValues(alpha: 0.5);
    return AppColors.primary.withValues(alpha: 0.25);
  }

  Widget _buildTooltip(StreakDayData day) {
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${monthNames[day.date.month - 1]} ${day.date.day}, ${day.date.year}';

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cellColor(day.xp, day.dailyGoalMet),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${day.xp} XP · ${day.questionsAnswered} questions',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (day.dailyGoalMet) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Goal ✓',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow() {
    return Row(
      children: const [
        Text(
          'Activity',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildIntensityLegend() {
    return Row(
      children: [
        const Text(
          'Less',
          style: TextStyle(color: Colors.white24, fontSize: 11),
        ),
        const SizedBox(width: 6),
        ...['empty', 'low', 'mid', 'high', 'full'].map((level) {
          Color color;
          switch (level) {
            case 'empty': color = AppColors.surfaceLight.withValues(alpha: 0.4); break;
            case 'low':   color = AppColors.primary.withValues(alpha: 0.25); break;
            case 'mid':   color = AppColors.primary.withValues(alpha: 0.5); break;
            case 'high':  color = AppColors.primary.withValues(alpha: 0.75); break;
            default:      color = AppColors.primary;
          }
          return Container(
            width: 13,
            height: 13,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 6),
        const Text(
          'More',
          style: TextStyle(color: Colors.white24, fontSize: 11),
        ),
        const Spacer(),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'Daily goal met',
          style: TextStyle(color: Colors.white24, fontSize: 11),
        ),
      ],
    );
  }
}
