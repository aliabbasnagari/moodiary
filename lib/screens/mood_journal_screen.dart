import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/mood.dart';
import '../state/journal_filter_provider.dart';
import '../state/mood_entries_provider.dart';
import '../widgets/journal_filter_bar.dart';
import '../widgets/mood_entry_edit_dialog.dart';
import '../widgets/mood_face.dart';
import '../widgets/mood_recovery_card.dart';
import '../widgets/trigger_insights_card.dart';
import '../widgets/weekly_recap_card.dart';

class MoodJournalScreen extends ConsumerWidget {
  const MoodJournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEntries = ref.watch(moodEntriesProvider);
    final filter = ref.watch(journalFilterProvider);

    if (allEntries.isEmpty) {
      return Center(
        child: Text(
          'No moods logged yet.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      );
    }

    final entries =
        allEntries.where(filter.matches).toList(growable: false);

    if (entries.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: JournalFilterBar(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_alt_off,
                      size: 36, color: Colors.black38),
                  const SizedBox(height: 8),
                  Text(
                    'No entries match your filters.',
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

    return CustomScrollView(
      slivers: [
        // Filter bar pinned at the very top.
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: JournalFilterBar(),
          ),
        ),
        // Weekly recap pinned at the top (only shown when the week has data).
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: WeeklyRecapCard(),
          ),
        ),
        // Personal pattern insights (shown only when there's enough data).
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TriggerInsightsCard(),
          ),
        ),
        // Mood recovery patterns (mood -> next mood transitions).
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: MoodRecoveryCard(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
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
                        ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    for (final entry in dayEntries)
                      _JournalEntryCard(entry: entry),
                  ],
                );
              },
              childCount: sortedDays.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _JournalEntryCard extends ConsumerWidget {
  final MoodEntry entry;

  const _JournalEntryCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CardActionButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit entry',
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => MoodEntryEditDialog(entry: entry),
                  );
                },
              ),
              const SizedBox(height: 8),
              _CardActionButton(
                icon: Icons.delete_outline,
                tooltip: 'Delete entry',
                onTap: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text(
          'This will remove the mood entry from your journal and timeline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(moodEntriesProvider.notifier).removeEntry(entry.id);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Entry deleted'),
          duration: Duration(milliseconds: 1200),
        ));
    }
  }
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CardActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Icon(icon, size: 18, color: Colors.black54),
      ),
    );
  }
}
