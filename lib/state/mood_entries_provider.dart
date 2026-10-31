import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import '../models/trigger.dart';

/// Holds the user's logged moods.
///
/// In a real app this would be backed by persistent storage; for the
/// scope of this exercise the list lives in-memory for the session.
class MoodEntriesNotifier extends StateNotifier<List<MoodEntry>> {
  MoodEntriesNotifier() : super(const []);

  void log(
    Mood mood,
    String? note, {
    String? promptResponse,
    List<Trigger> triggers = const [],
  }) {
    final entry = MoodEntry(
      mood: mood,
      loggedAt: DateTime.now(),
      note: note,
      promptResponse: promptResponse,
      triggers: triggers,
    );
    // Newest first — that's how the timeline reads.
    state = [entry, ...state];
  }

  void updateEntry(MoodEntry updated) {
    state = [
      for (final entry in state)
        if (entry.id == updated.id) updated else entry,
    ];
  }

  void removeEntry(String id) {
    state = [
      for (final entry in state)
        if (entry.id != id) entry,
    ];
  }

  void clear() => state = const [];
}

final moodEntriesProvider =
    StateNotifierProvider<MoodEntriesNotifier, List<MoodEntry>>(
  (ref) => MoodEntriesNotifier(),
);

/// The most recent 7 entries, in newest-first order.
final recentMoodEntriesProvider = Provider<List<MoodEntry>>((ref) {
  final all = ref.watch(moodEntriesProvider);
  return all.take(7).toList(growable: false);
});
