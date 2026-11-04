import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal.dart';
import '../state/goals_provider.dart';

/// A compact card showing today's progress toward the user's logging goal.
///
/// Tapping it opens the goal settings dialog.
class GoalProgressCard extends ConsumerWidget {
  const GoalProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalsProvider);
    final today = ref.watch(entriesTodayProvider);
    final thisWeek = ref.watch(entriesThisWeekProvider);

    final isDaily = goal.type == GoalType.daily;
    final target = isDaily ? goal.dailyTarget : goal.weeklyTarget;
    final current = isDaily ? today : thisWeek;
    final progress = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    final done = current >= target;
    final color = done ? const Color(0xFF8AC926) : const Color(0xFFFFC857);

    return Tooltip(
      message: 'Edit logging goal',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showGoalDialog(context, ref),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: progress,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDaily ? 'Daily goal' : 'Weekly goal',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                      Text(
                        done
                            ? 'Goal reached! '
                            : '$current of $target logged',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: done ? const Color(0xFF8AC926) : null,
                            ),
                      ),
                      Text(
                        isDaily
                            ? 'Tap to change your daily target'
                            : 'Tap to change your weekly target',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: Colors.black45),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGoalDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(goalsProvider);
    GoalType type = current.type;
    int daily = current.dailyTarget;
    int weekly = current.weeklyTarget;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Logging goal'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<GoalType>(
                      segments: const [
                        ButtonSegment(
                          value: GoalType.daily,
                          label: Text('Daily'),
                          icon: Icon(Icons.today),
                        ),
                        ButtonSegment(
                          value: GoalType.weekly,
                          label: Text('Weekly'),
                          icon: Icon(Icons.date_range),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: (s) => setState(() => type = s.first),
                    ),
                    const SizedBox(height: 16),
                    if (type == GoalType.daily) ...[
                      const Text('How many check-ins per day?'),
                      const SizedBox(height: 8),
                      _Stepper(
                        value: daily,
                        min: 1,
                        max: 10,
                        onChanged: (v) => setState(() => daily = v),
                      ),
                    ] else ...[
                      const Text('How many check-ins per week?'),
                      const SizedBox(height: 8),
                      _Stepper(
                        value: weekly,
                        min: 1,
                        max: 28,
                        onChanged: (v) => setState(() => weekly = v),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    ref
                        .read(goalsProvider.notifier)
                        .set(Goal(
                          type: type,
                          dailyTarget: daily,
                          weeklyTarget: weekly,
                        ));
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.18);

    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2,
      false,
      track,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      valuePaint,
    );

    final painter = TextPainter(
      text: TextSpan(
        text: '${(progress * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
        canvas,
        Offset(center.dx - painter.width / 2, center.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
