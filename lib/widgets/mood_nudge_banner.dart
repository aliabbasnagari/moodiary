import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/goals_provider.dart';

/// A gentle, dismissable banner that appears when the user hasn't logged today.
class MoodNudgeBanner extends ConsumerWidget {
  const MoodNudgeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(shouldNudgeProvider)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC857).withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: const Icon(Icons.holiday_village_outlined,
            color: Color(0xFFE6A817)),
        title: const Text(
          'Thinking of you',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'You haven\'t logged a mood yet today.',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () =>
                  ref.read(nudgeDismissedProvider.notifier).state = true,
              child: const Text('Remind me later'),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () =>
                  ref.read(nudgeDismissedProvider.notifier).state = true,
            ),
          ],
        ),
      ),
    );
  }
}
