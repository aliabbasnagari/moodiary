import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/mood.dart';
import '../state/weekly_recap_provider.dart';

/// A card summarizing the user's last 7 days, with an export action.
class WeeklyRecapCard extends ConsumerWidget {
  const WeeklyRecapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recap = ref.watch(weeklyRecapProvider);
    if (recap.isEmpty) return const SizedBox.shrink();

    final dominant = recap.dominantMood;
    final topTrigger = recap.topTrigger;

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
              const Icon(Icons.auto_awesome, color: Color(0xFFE6A817)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your Week at a Glance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              _IconButton(
                icon: Icons.share_outlined,
                tooltip: 'Share week',
                onPressed: () => _share(recap, context),
              ),
              const SizedBox(width: 4),
              _IconButton(
                icon: Icons.copy_all_outlined,
                tooltip: 'Copy summary',
                onPressed: () => _copy(recap, context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dominant mood + happiness
          if (dominant != null)
            Row(
              children: [
                Icon(
                  dominant == Mood.happy || dominant == Mood.good
                      ? Icons.sentiment_satisfied_alt_outlined
                      : dominant == Mood.neutral
                          ? Icons.sentiment_neutral_outlined
                          : Icons.sentiment_dissatisfied_outlined,
                  color: dominant.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mostly ${dominant.label} · ${recap.happinessScore.toStringAsFixed(0)}% happiness',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          if (topTrigger != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  topTrigger.icon,
                  color: topTrigger.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Most logged trigger: ${topTrigger.label}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${recap.entryCount} moods logged across ${recap.loggingDays} day${recap.loggingDays == 1 ? '' : 's'}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          // Mood mix bar
          _MoodMixBar(counts: recap.countsByMood, total: recap.entryCount),
          const SizedBox(height: 12),
          // Best / worst day
          if (recap.bestDay != null || recap.worstDay != null)
            Row(
              children: [
                if (recap.bestDay != null)
                  _DayChip(
                    label: 'Best',
                    date: recap.bestDay!,
                    color: const Color(0xFF8AC926),
                  ),
                if (recap.bestDay != null && recap.worstDay != null)
                  const SizedBox(width: 8),
                if (recap.worstDay != null)
                  _DayChip(
                    label: 'Hardest',
                    date: recap.worstDay!,
                    color: const Color(0xFFE76F51),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _copy(WeeklyRecap recap, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: recap.toText()));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Weekly summary copied'),
          duration: Duration(milliseconds: 1500),
        ));
    }
  }

  Future<void> _share(WeeklyRecap recap, BuildContext context) async {
    try {
      await Share.share(recap.toText(), subject: 'Moodiary Weekly Recap');
    } catch (_) {
      // Fall back to copy if the share sheet is unavailable.
      await _copy(recap, context);
    }
  }
}

class _MoodMixBar extends StatelessWidget {
  final Map<Mood, int> counts;
  final int total;

  const _MoodMixBar({required this.counts, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                for (final mood in Mood.values)
                  Expanded(
                    flex: (counts[mood] ?? 0) == 0 ? 0 : (counts[mood] ?? 0),
                    child: Container(color: mood.color),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            for (final mood in Mood.values)
              if ((counts[mood] ?? 0) > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: mood.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${mood.label} ${counts[mood]}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
          ],
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final String date;
  final Color color;

  const _DayChip({
    required this.label,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: ${_format(date)}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _format(String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return dayKey;
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]),
        int.parse(parts[2]));
    return DateFormat('EEE, MMM d').format(date);
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
      ),
    );
  }
}

/// Builds a shareable plain-text summary of the week.
extension on WeeklyRecap {
  String toText() {
    final buffer = StringBuffer();
    buffer.writeln('Moodiary — Weekly Recap');
    buffer.writeln('Last 7 days · ${entryCount} moods');
    if (dominantMood != null) {
      buffer.writeln('Mostly: ${dominantMood!.label}');
    }
    buffer.writeln('Happiness: ${happinessScore.toStringAsFixed(0)}%');
    if (topTrigger != null) {
      buffer.writeln('Top trigger: ${topTrigger!.label}');
    }
    final mix = Mood.values
        .where((m) => (countsByMood[m] ?? 0) > 0)
        .map((m) => '${m.label} x${countsByMood[m]}')
        .join(', ');
    if (mix.isNotEmpty) {
      buffer.writeln('Mood mix: $mix');
    }
    return buffer.toString();
  }
}
