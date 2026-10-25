import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import 'mood_entries_provider.dart';

class MoodTrends {
  final int totalEntries;
  final Map<Mood, int> countsByMood;
  final Map<String, int> countsByDay;
  final Mood mostCommonMood;
  final double happinessScore;

  const MoodTrends({
    required this.totalEntries,
    required this.countsByMood,
    required this.countsByDay,
    required this.mostCommonMood,
    required this.happinessScore,
  });

  factory MoodTrends.fromEntries(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return const MoodTrends(
        totalEntries: 0,
        countsByMood: {},
        countsByDay: {},
        mostCommonMood: Mood.neutral,
        happinessScore: 0.0,
      );
    }

    final countsByMood = <Mood, int>{};
    for (final mood in Mood.values) {
      countsByMood[mood] = 0;
    }

    for (final entry in entries) {
      countsByMood.update(entry.mood, (value) => value! + 1);
    }

    final dayMap = <String, int>{};
    for (final entry in entries) {
      final dayKey = '${entry.loggedAt.year}-${entry.loggedAt.month}-${entry.loggedAt.day}';
      dayMap.update(dayKey, (value) => value! + 1, ifAbsent: () => 1);
    }

    Mood mostCommonMood = Mood.neutral;
    int maxCount = 0;
    for (final entry in countsByMood.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommonMood = entry.key;
      }
    }

    final moodScores = {
      Mood.happy: 5,
      Mood.good: 4,
      Mood.neutral: 3,
      Mood.sad: 2,
      Mood.awful: 1,
    };
    final totalScore = entries.fold<int>(0, (sum, e) => sum + (moodScores[e.mood] ?? 3));
    final happinessScore = (totalScore / entries.length / 5) * 100;

    return MoodTrends(
      totalEntries: entries.length,
      countsByMood: countsByMood,
      countsByDay: dayMap,
      mostCommonMood: mostCommonMood,
      happinessScore: happinessScore,
    );
  }
}

final moodTrendsProvider = Provider<MoodTrends>((ref) {
  final entries = ref.watch(moodEntriesProvider);
  return MoodTrends.fromEntries(entries);
});

final recentTrendsProvider = Provider<MoodTrends>((ref) {
  final entries = ref.watch(recentMoodEntriesProvider);
  return MoodTrends.fromEntries(entries);
});

final journalEntriesProvider = Provider<List<MoodEntry>>((ref) {
  final entries = ref.watch(moodEntriesProvider);
  return entries.toList();
});
