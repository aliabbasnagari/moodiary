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
                onTap: () {
                  ref.read(moodEntriesProvider.notifier).log(mood);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        duration: const Duration(milliseconds: 1200),
                        backgroundColor: mood.color,
                        content: Text(
                          'Logged: ${mood.label}',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    );
                },
              ),
          ],
        );
      },
    );
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
