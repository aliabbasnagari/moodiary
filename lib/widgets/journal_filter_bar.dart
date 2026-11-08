import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import '../models/trigger.dart';
import '../state/journal_filter_provider.dart';

/// A bar of filters + a search field for the journal.
class JournalFilterBar extends ConsumerWidget {
  const JournalFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(journalFilterProvider);

    return Column(
      children: [
        // Search field.
        _SearchField(
          key: ValueKey(filter.query),
          ref: ref,
        ),
        const SizedBox(height: 10),
        // Filter chips.
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // Mood chips.
            for (final mood in Mood.values)
              _FilterChip(
                label: mood.label,
                selected: filter.mood == mood,
                color: mood.color,
                onToggled: (on) => ref
                    .read(journalFilterProvider.notifier)
                    .update((f) => on ? f.copyWith(mood: mood) : f.copyWith(clearMood: true)),
              ),
            const _VerticalDivider(),
            // Date range chips.
            _FilterChip(
              label: 'Today',
              selected: filter.dateRange == JournalDateRange.today,
              color: const Color(0xFF8AC926),
              onToggled: (on) => ref
                  .read(journalFilterProvider.notifier)
                  .update((f) => f.copyWith(dateRange: on ? JournalDateRange.today : JournalDateRange.all)),
            ),
            _FilterChip(
              label: '7 days',
              selected: filter.dateRange == JournalDateRange.last7,
              color: const Color(0xFF4FC3F7),
              onToggled: (on) => ref
                  .read(journalFilterProvider.notifier)
                  .update((f) => f.copyWith(dateRange: on ? JournalDateRange.last7 : JournalDateRange.all)),
            ),
            _FilterChip(
              label: '30 days',
              selected: filter.dateRange == JournalDateRange.last30,
              color: const Color(0xFFAB47BC),
              onToggled: (on) => ref
                  .read(journalFilterProvider.notifier)
                  .update((f) => f.copyWith(dateRange: on ? JournalDateRange.last30 : JournalDateRange.all)),
            ),
            if (filter.isActive) ...[
              const _VerticalDivider(),
              _FilterChip(
                label: 'Clear all',
                selected: false,
                color: const Color(0xFFE76F51),
                onToggled: (on) => ref
                    .read(journalFilterProvider.notifier)
                    .update((f) => f.clear()),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _SearchField({super.key, required this.ref});

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final current =
        widget.ref.read(journalFilterProvider).query;
    _controller = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: _controller,
        onChanged: (v) => widget.ref
            .read(journalFilterProvider.notifier)
            .update((f) => f.copyWith(query: v)),
        decoration: InputDecoration(
          hintText: 'Search notes or responses…',
          prefixIcon: const Icon(Icons.search, size: 18),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final ValueChanged<bool> onToggled;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      backgroundColor: color.withValues(alpha: 0.08),
      selectedColor: color.withValues(alpha: 0.35),
      side: BorderSide(color: color, width: 1),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontSize: 12,
      ),
      onSelected: onToggled,
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 2,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black12),
      ),
    );
  }
}
