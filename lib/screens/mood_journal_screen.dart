import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/mood.dart';
import '../state/mood_entries_provider.dart';
import '../widgets/mood_face.dart';

class MoodJournalScreen extends ConsumerWidget {
  const MoodJournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(moodEntriesProvider);

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No moods logged yet.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      );
    }

    final groupedEntries = <String, List<MoodEntry>>{};
    for (final entry in entries) {
      final dayKey = DateFormat('yyyy-MM-dd').format(entry.loggedAt);
      groupedEntries.update(
        dayKey,
        (value) => value..add(entry),
        ifAbsent: () => [entry],
      );
    }

    final sortedDays = groupedEntries.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDays.length,
      itemBuilder: (context, i) {
        final dayKey = sortedDays[i];
        final dayEntries = groupedEntries[dayKey]!;
        final date = DateFormat(
          'EEEE, MMMM d, yyyy',
        ).format(dayEntries[0].loggedAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                date,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            for (final entry in dayEntries) _JournalEntryCard(entry: entry),
          ],
        );
      },
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  final MoodEntry entry;

  const _JournalEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: entry.mood.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: entry.mood.color, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoodFace(mood: entry.mood, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.mood.label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.note!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat.jm().format(entry.loggedAt),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
