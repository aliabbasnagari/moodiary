import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/mood.dart';
import '../state/mood_entries_provider.dart';
import 'mood_face.dart';

/// Horizontal scrollable list of the user's most recent mood entries.
///
/// Tapping a card briefly animates that face — see [_TimelineCard].
class MoodTimeline extends ConsumerWidget {
  const MoodTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(recentMoodEntriesProvider);

    if (entries.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No moods yet — tap a face above to log one.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _TimelineCard(entry: entries[i]),
      ),
    );
  }
}

class _TimelineCard extends StatefulWidget {
  const _TimelineCard({required this.entry});

  final MoodEntry entry;

  @override
  State<_TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<_TimelineCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playAnimation() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final dateLabel = _formatDate(entry.loggedAt);
    final timeLabel = DateFormat.jm().format(entry.loggedAt);

    return GestureDetector(
      onTap: _playAnimation,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Card bounces gently and the face plays its expression beat.
          final t = _controller.value;
          final wobble = t == 0
              ? 0.0
              : (1 - (2 * t - 1) * (2 * t - 1));
          final scale = 1 + 0.06 * wobble;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: entry.mood.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: entry.mood.color,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MoodFace(
                    mood: entry.mood,
                    size: 80,
                    animation: _controller.value,
                  ),
                  Column(
                    children: [
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        timeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime when) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(when.year, when.month, when.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(when);
  }
}
