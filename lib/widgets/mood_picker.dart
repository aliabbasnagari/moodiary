import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import '../state/mood_entries_provider.dart';
import 'mood_face.dart';

/// Row of tappable mood faces that lets the user log how they feel.
class MoodPicker extends ConsumerWidget {
  const MoodPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Pick a face size that fits all 5 moods with a bit of breathing room.
        final faceSize =
            ((constraints.maxWidth - 16 * (Mood.values.length - 1)) /
                    Mood.values.length)
                .clamp(56.0, 92.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final mood in Mood.values)
              _MoodPickerButton(
                mood: mood,
                size: faceSize,
                onTap: () => _showNoteDialog(context, ref, mood),
              ),
          ],
        );
      },
    );
  }

  void _showNoteDialog(
    BuildContext context,
    WidgetRef ref,
    Mood mood,
  ) async {
    final note = await showDialog<String?>(
      context: context,
      builder: (context) => _NoteDialog(mood: mood),
    );

    if (note != null) {
      ref.read(moodEntriesProvider.notifier).log(mood, note);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1200),
            backgroundColor: mood.color,
            content: Text(
              note.isEmpty
                  ? 'Logged: ${mood.label}'
                  : 'Logged: ${mood.label} - ${note}',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        );
    }
  }
}

class _MoodPickerButton extends StatefulWidget {
  const _MoodPickerButton({
    required this.mood,
    required this.size,
    required this.onTap,
  });

  final Mood mood;
  final double size;
  final VoidCallback onTap;

  @override
  State<_MoodPickerButton> createState() => _MoodPickerButtonState();
}

class _MoodPickerButtonState extends State<_MoodPickerButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _hovering ? 1.06 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MoodFace(mood: widget.mood, size: widget.size),
              const SizedBox(height: 6),
              Text(
                widget.mood.label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for entering an optional note when logging a mood.
class _NoteDialog extends StatefulWidget {
  final Mood mood;

  const _NoteDialog({required this.mood});

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log ${widget.mood.label}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How are you feeling?'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Add a note (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Log'),
        ),
      ],
    );
  }
}

