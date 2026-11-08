import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import '../state/recovery_provider.dart';

/// A card showing mood recovery patterns (mood -> next mood transitions).
class MoodRecoveryCard extends ConsumerWidget {
  const MoodRecoveryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(recoveryProvider);

    if (!result.enoughData) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.swap_horiz, color: Colors.black54),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Keep logging — I\'ll learn how your moods flow from one to the next.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }

    if (result.topTransitions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.swap_horiz, color: Color(0xFFE6A817)),
            const SizedBox(width: 8),
            Text(
              'Mood Recovery Patterns',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'How your mood usually flows from one day to the next.',
          style:
              Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
        ),
        const SizedBox(height: 12),
        // Transition grid: rows = "from" moods, cols = "to" moods.
        _TransitionGrid(result: result),
        const SizedBox(height: 12),
        for (final insight in result.topTransitions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TransitionTile(insight: insight, result: result),
          ),
      ],
    );
  }
}

class _TransitionGrid extends StatelessWidget {
  final RecoveryResult result;

  const _TransitionGrid({required this.result});

  @override
  Widget build(BuildContext context) {
    final moods = Mood.values;
    final maxProb = 1.0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header row (the "to" moods).
          Row(
            children: [
              const SizedBox(width: 24),
              for (final m in moods)
                Expanded(
                  child: Center(
                    child: Icon(_moodIcon(m), size: 14, color: m.color),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (final from in moods)
            if ((result.rowTotals[from] ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    // Row label.
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: Icon(_moodIcon(from),
                            size: 14, color: from.color),
                      ),
                    ),
                    for (final to in moods)
                      Expanded(
                        child: _Cell(
                          probability: result.probabilityOf(from, to),
                          fromColor: from.color,
                          toColor: to.color,
                          maxProb: maxProb,
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

class _Cell extends StatelessWidget {
  final double probability;
  final Color fromColor;
  final Color toColor;
  final double maxProb;

  const _Cell({
    required this.probability,
    required this.fromColor,
    required this.toColor,
    required this.maxProb,
  });

  @override
  Widget build(BuildContext context) {
    final intensity = probability > 0 ? (probability / maxProb) : 0.0;
    return Container(
      decoration: BoxDecoration(
        color: toColor.withValues(alpha: 0.08 + intensity * 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          probability > 0 ? '${(probability * 100).toStringAsFixed(0)}%' : '',
          style: TextStyle(
            fontSize: 10,
            color: intensity > 0.5 ? Colors.white : Colors.black87,
            fontWeight: intensity > 0.5 ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TransitionTile extends StatelessWidget {
  final RecoveryInsight insight;
  final RecoveryResult result;

  const _TransitionTile({required this.insight, required this.result});

  @override
  Widget build(BuildContext context) {
    final from = insight.from;
    final to = insight.to;
    final accent = insight.isRecovery
        ? const Color(0xFF8AC926)
        : from.color;

    final verb = insight.isRecovery ? 'recovers to' : 'tends to become';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _MiniMood(mood: from),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          _MiniMood(mood: to),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${from.label} $verb ${to.label} '
              'in ${(insight.probability * 100).toStringAsFixed(0)}% of cases '
              '(${insight.count}×)',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMood extends StatelessWidget {
  final Mood mood;

  const _MiniMood({required this.mood});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: mood.color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mood.color),
      ),
      child: Center(
        child: Icon(_moodIcon(mood), size: 12, color: mood.color),
      ),
    );
  }
}

IconData _moodIcon(Mood mood) {
  switch (mood) {
    case Mood.happy:
      return Icons.emoji_emotions;
    case Mood.good:
      return Icons.emoji_emotions;
    case Mood.neutral:
      return Icons.sentiment_neutral;
    case Mood.sad:
      return Icons.emoji_emotions;
    case Mood.awful:
      return Icons.emoji_emotions;
  }
}
