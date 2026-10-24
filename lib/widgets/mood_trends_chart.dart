import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/mood.dart';
import '../state/mood_trends_provider.dart';

class MoodTrendsChart extends ConsumerWidget {
  const MoodTrendsChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trends = ref.watch(moodTrendsProvider);

    if (trends.totalEntries == 0) {
      return _EmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummarySection(trends: trends),
        const SizedBox(height: 16),
        _DistributionChart(trends: trends),
        const SizedBox(height: 16),
        _RecentActivity(trends: trends),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Log some moods to see trends.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black54,
            ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final MoodTrends trends;

  const _SummarySection({required this.trends});

  @override
  Widget build(BuildContext context) {
    final moodColors = {
      Mood.happy: Color(0xFFFFC857),
      Mood.good: Color(0xFF8AC926),
      Mood.neutral: Color(0xFF90A4AE),
      Mood.sad: Color(0xFF4A90E2),
      Mood.awful: Color(0xFFE76F51),
    };

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: trends.mostCommonMood.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: trends.mostCommonMood.color,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${trends.mostCommonMood.label}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  'Most common',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${trends.totalEntries} entries',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  'Total logged',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DistributionChart extends StatelessWidget {
  final MoodTrends trends;

  const _DistributionChart({required this.trends});

  @override
  Widget build(BuildContext context) {
    final maxCount = trends.countsByMood.values.fold(0, max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribution',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: Mood.values.map((mood) {
            final count = trends.countsByMood[mood] ?? 0;
            final height = maxCount > 0 ? (count / maxCount) * 100 : 0;
            final color = mood.color;

            return Column(
              children: [
                Container(
                  height: 80,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: height * 0.8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${mood.label}\n($count)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final MoodTrends trends;

  const _RecentActivity({required this.trends});

  @override
  Widget build(BuildContext context) {
    final sortedDays = trends.countsByDay.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most active days',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        for (final entry in sortedDays.take(3))
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDay(context, entry.key),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(0xFF8AC926),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value} entries',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  String _formatDay(BuildContext context, String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return dayKey;
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final date = DateTime(year, month, day);
    return DateFormat('EEE, MMM d').format(date);
  }
}
