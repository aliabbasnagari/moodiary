import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';

/// Holds the user's logged moods.
///
/// In a real app this would be backed by persistent storage; for the
/// scope of this exercise the list lives in-memory for the session.
class MoodEntriesNotifier extends StateNotifier<List<MoodEntry>> {
  MoodEntriesNotifier() : super(const []);

  void log(Mood mood) {
    final entry = MoodEntry(mood: mood, loggedAt: DateTime.now());
    // Newest first — that's how the timeline reads.
    state = [entry, ...state];
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
