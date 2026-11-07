import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import '../state/insights_provider.dart';

/// A card surfacing the user's strongest on-device patterns.
class TriggerInsightsCard extends ConsumerWidget {
  const TriggerInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(insightsProvider);

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
            const Icon(Icons.lightbulb_outline, color: Colors.black54),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Keep logging with triggers and I\'ll surface your personal patterns here.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }

    if (result.insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFE6A817)),
            const SizedBox(width: 8),
            Text(
              'Your Patterns',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final insight in result.insights)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InsightTile(insight: insight),
          ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  final Insight insight;

  const _InsightTile({required this.insight});

  @override
  Widget build(BuildContext context) {
    final trigger = insight.trigger;
    final accent = trigger.color;
    final positive = insight.highlightedMood != null &&
        [Mood.happy, Mood.good].contains(insight.highlightedMood);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(trigger.icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.headline,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700, color: accent),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Strength meter
              Container(
                width: 54,
                height: 6,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  widthFactor: insight.strength,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            insight.detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black87,
                ),
          ),
        ],
      ),
    );
  }
}
