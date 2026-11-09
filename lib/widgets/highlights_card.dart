import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/mood.dart';
import '../state/highlights_provider.dart';

/// A card celebrating the user's all-time highlights.
class HighlightsCard extends ConsumerWidget {
  const HighlightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlights = ref.watch(highlightsProvider);

    if (highlights.totalDaysLogged == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF3D6),
            const Color(0xFFFDF8F2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC857), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFE6A817)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your Highlights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                'Day 1: ${DateFormat('MMM d, yyyy').format(highlights.firstEntryDate != null ? _parse(highlights.firstEntryDate!) : DateTime.now())}',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Streak hero.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: highlights.longestStreak >= 3
                  ? const Color(0xFFFFC857).withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlights.longestStreak >= 3
                    ? const Color(0xFFFFC857)
                    : Colors.orange,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: Color(0xFFE64A19)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${highlights.longestStreak}-day streak',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Longest run · ${highlights.totalDaysLogged} day${highlights.totalDaysLogged == 1 ? '' : 's'} logged total',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Top days.
          Text(
            'Your happiest days',
            style:
                Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
          ),
          const SizedBox(height: 8),
          for (final day in highlights.topDays)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _TopDayTile(day: day),
            ),
        ],
      ),
    );
  }

  DateTime _parse(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}

class _TopDayTile extends StatelessWidget {
  final HighlightDay day;

  const _TopDayTile({required this.day});

  @override
  Widget build(BuildContext context) {
    final mood = day.dominantMood;
    final accent = mood?.color ?? const Color(0xFF8AC926);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Mini mood face.
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent),
            ),
            child: Center(
              child: Icon(
                _moodIcon(mood),
                size: 14,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(day.date),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${day.entryCount} check-in${day.entryCount == 1 ? '' : 's'} · mostly ${mood?.label ?? 'mixed'}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          // Happiness ring.
          SizedBox(
            width: 44,
            height: 44,
            child: CustomPaint(
              painter: _MiniRing(
                progress: day.happiness / 100,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _moodIcon(Mood? mood) {
  if (mood == null) return Icons.sentiment_neutral;
  switch (mood) {
    case Mood.happy:
    case Mood.good:
      return Icons.emoji_emotions;
    case Mood.neutral:
      return Icons.sentiment_neutral;
    default:
      return Icons.emoji_emotions;
  }
}

class _MiniRing extends CustomPainter {
  final double progress;
  final Color color;

  _MiniRing({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.18);

    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
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
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniRing old) =>
      old.progress != progress || old.color != color;
}
