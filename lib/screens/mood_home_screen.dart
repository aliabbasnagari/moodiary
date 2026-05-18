import 'package:flutter/material.dart';

import '../widgets/mood_picker.dart';
import '../widgets/mood_timeline.dart';

class MoodHomeScreen extends StatelessWidget {
  const MoodHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F2),
      appBar: AppBar(
        title: const Text('Moodiary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'How are you feeling?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap a face to log it.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 24),
                  const MoodPicker(),
                  const SizedBox(height: 40),
                  Text(
                    'Recent moods',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  const MoodTimeline(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
