import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import '../models/trigger.dart';
import '../state/mood_entries_provider.dart';
import '../state/mood_prompts_provider.dart';
import 'mood_face.dart';

/// A single, well-organized bottom sheet for logging a mood.
///
/// Replaces the old three-dialog flow (prompt selector -> trigger picker ->
/// note dialog) with one screen: prompt, triggers, and note in one place,
/// with a single prominent save action.
class MoodLoggingSheet extends ConsumerStatefulWidget {
  const MoodLoggingSheet({
    super.key,
    required this.mood,
    this.prompts = const [],
  });

  final Mood mood;
  final List<MoodPrompt> prompts;

  @override
  ConsumerState<MoodLoggingSheet> createState() => _MoodLoggingSheetState();
}

class _MoodLoggingSheetState extends ConsumerState<MoodLoggingSheet> {
  int _promptIndex = 0;
  final _responseController = TextEditingController();
  final _noteController = TextEditingController();
  final _selectedTriggers = <Trigger>{};

  @override
  void dispose() {
    _responseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(moodEntriesProvider.notifier).log(
          widget.mood,
          _noteController.text,
          promptResponse:
              _responseController.text.isEmpty ? null : _responseController.text,
          triggers: _selectedTriggers.toList(),
        );
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1200),
          backgroundColor: widget.mood.color,
          content: Text(
            'Logged: ${widget.mood.label}',
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final mood = widget.mood;
    final hasPrompt = widget.prompts.isNotEmpty;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  // Drag handle.
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header.
                  Row(
                    children: [
                      MoodFace(mood: mood, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Logging ${mood.label}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Add as much or as little as you like.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  if (hasPrompt) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: mood.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: mood.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.prompts[_promptIndex].question,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.swap_horiz,
                                    size: 18, color: Colors.black54),
                                tooltip: 'Another prompt',
                                onPressed: () => setState(
                                  () => _promptIndex =
                                      (_promptIndex + 1) % widget.prompts.length,
                                ),
                              ),
                            ],
                          ),
                          TextField(
                            controller: _responseController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Your response (optional)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Triggers.
                  Text(
                    'What played a part?',
                    style:
                        Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.black54,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final trigger in Trigger.values)
                        ActionChip(
                          avatar: Icon(
                            trigger.icon,
                            size: 15,
                            color: _selectedTriggers.contains(trigger)
                                ? Colors.white
                                : trigger.color,
                          ),
                          label: Text(trigger.label),
                          backgroundColor: _selectedTriggers.contains(trigger)
                              ? trigger.color
                              : trigger.color.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: _selectedTriggers.contains(trigger)
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 13,
                          ),
                          side: BorderSide(color: trigger.color),
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
                  // Note.
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Add a note (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  // Save.
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: mood.color,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _save,
                      child: Text(
                        'Log ${mood.label}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
