import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import '../models/trigger.dart';
import '../state/mood_entries_provider.dart';

/// Dialog for editing an existing mood entry.
///
/// Lets the user change the mood, note, and triggers. The original
/// prompt response is preserved and shown read-only.
class MoodEntryEditDialog extends StatefulWidget {
  final MoodEntry entry;

  const MoodEntryEditDialog({super.key, required this.entry});

  @override
  State<MoodEntryEditDialog> createState() => _MoodEntryEditDialogState();
}

class _MoodEntryEditDialogState extends State<MoodEntryEditDialog> {
  late Mood _selectedMood;
  late Set<Trigger> _selectedTriggers;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.entry.mood;
    _selectedTriggers = widget.entry.triggers.toSet();
    _noteController = TextEditingController(text: widget.entry.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit entry · ${DateFormatHelper.format(widget.entry.loggedAt)}'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood selector
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mood in Mood.values)
                  ChoiceChip(
                    label: Text(mood.label),
                    selected: _selectedMood == mood,
                    backgroundColor:
                        mood.color.withValues(alpha: _selectedMood == mood ? 0.25 : 0.08),
                    selectedColor: mood.color.withValues(alpha: 0.4),
                    onSelected: (_) => setState(() => _selectedMood = mood),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Prompt response (read-only, if present)
            if (widget.entry.promptResponse != null &&
                widget.entry.promptResponse!.isNotEmpty) ...[
              Text(
                'Prompt response',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.entry.promptResponse!),
              ),
              const SizedBox(height: 16),
            ],
            // Triggers
            Text(
                'Triggers',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final trigger in Trigger.values)
                    ActionChip(
                      avatar: Icon(
                        trigger.icon,
                        size: 14,
                        color: _selectedTriggers.contains(trigger)
                            ? Colors.white
                            : trigger.color,
                      ),
                      label: Text(trigger.label),
                      selected: _selectedTriggers.contains(trigger),
                      backgroundColor: _selectedTriggers.contains(trigger)
                          ? trigger.color
                          : trigger.color.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: _selectedTriggers.contains(trigger)
                            ? Colors.white
                            : Colors.black87,
                        fontSize: 12,
                      ),
                      side: BorderSide(color: trigger.color, width: 1),
                      onPressed: () {
                        setState(() {
                          if (_selectedTriggers.contains(trigger)) {
                            _selectedTriggers.remove(trigger);
                          } else {
                            _selectedTriggers.add(trigger);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
            // Note
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final updated = widget.entry.copyWith(
              mood: _selectedMood,
              note: _noteController.text.isEmpty ? null : _noteController.text,
              triggers: _selectedTriggers.toList(),
            );
            context
                .read(moodEntriesProvider.notifier)
                .updateEntry(updated);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Simple date formatter used by the dialog title.
class DateFormatHelper {
  static String format(DateTime date) {
    final now = DateTime.now();
    final day =
        '${date.year}-${date.month}-${date.day}';
    final today = '${now.year}-${now.month}-${now.day}';
    if (day == today) return 'Today';
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${monthNames[date.month - 1]} ${date.day}';
  }
}
