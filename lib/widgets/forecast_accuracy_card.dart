import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import '../state/forecast_accuracy_provider.dart';

/// A card showing how accurate the app's forecasts have been.
class ForecastAccuracyCard extends ConsumerWidget {
  const ForecastAccuracyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hitRate = ref.watch(forecastHitRateProvider);
    final streak = ref.watch(recentForecastStreakProvider);
    final snapshots = ref.watch(forecastAccuracyProvider);

    if (snapshots.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.track_changes, color: Colors.black54),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'I\'ll start tracking forecast accuracy as you log moods.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }

    final pct = (hitRate * 100).toStringAsFixed(0);
    final color = hitRate >= 0.7
        ? const Color(0xFF8AC926)
        : hitRate >= 0.5
            ? const Color(0xFFFFC857)
            : const Color(0xFFE76F51);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: Color(0xFFE6A817)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Forecast accuracy',
                  style:
                      Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                ),
              ),
              Text(
                '$pct% right',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Calibration strip: last N snapshots as hit/miss dots.
          _CalibrationStrip(snapshots: snapshots, color: color),
          const SizedBox(height: 8),
          Text(
            'Based on ${snapshots.length} forecast${snapshots.length == 1 ? '' : 's'} · last $streak in a row correct',
            style:
                Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.black54,
                    ),
          ),
        ],
      ),
    );
  }
}

class _CalibrationStrip extends StatelessWidget {
  final List<ForecastSnapshot> snapshots;
  final Color color;

  const _CalibrationStrip({
    required this.snapshots,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Show the last 14 snapshots, oldest first.
    final recent = snapshots.length > 14
        ? snapshots.sublist(snapshots.length - 14)
        : snapshots;

    return Row(
      children: [
        for (final s in recent)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: '${_day(s.day)}: ${s.predicted.label} → ${s.actual.label} '
                  '${s.hit ? '✓' : '✗'}',
              child: Icon(
                s.hit ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: s.hit ? color : Colors.black26,
              ),
            ),
          ),
        if (snapshots.length > 14) ...[
          const SizedBox(width: 2),
          Text(
            '+${snapshots.length - 14}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ],
    );
  }

  String _day(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return key;
    final d = DateTime(int.parse(parts[0]), int.parse(parts[1]),
        int.parse(parts[2]));
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today';
    }
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${d.month}/${d.day}';
  }
}
