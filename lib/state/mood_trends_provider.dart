import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import 'mood_entries_provider.dart';

final dayOfWeekNames = {
  '1': 'Mon',
  '2': 'Tue',
  '3': 'Wed',
  '4': 'Thu',
  '5': 'Fri',
  '6': 'Sat',
  '7': 'Sun',
};

class MoodTrends {
  final int totalEntries;
  final Map<Mood, int> countsByMood;
  final Map<String, int> countsByDay;
  final Mood mostCommonMood;
  final double happinessScore;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> countsByDayOfWeek;

  const MoodTrends({
    required this.totalEntries,
    required this.countsByMood,
    required this.countsByDay,
    required this.mostCommonMood,
    required this.happinessScore,
    required this.currentStreak,
    required this.longestStreak,
    required this.countsByDayOfWeek,
  });

  factory MoodTrends.fromEntries(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return const MoodTrends(
        totalEntries: 0,
        countsByMood: {},
        countsByDay: {},
        mostCommonMood: Mood.neutral,
        happinessScore: 0.0,
        currentStreak: 0,
        longestStreak: 0,
        countsByDayOfWeek: {},
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

    final dayOfWeekMap = <String, int>{};
    for (final entry in entries) {
      final dayKey = entry.loggedAt.weekday.toString();
      dayOfWeekMap.update(dayKey, (value) => value! + 1, ifAbsent: () => 1);
    }

    int currentStreak = 0;
    int longestStreak = 0;
    final uniqueDays = <String>{};
    for (final entry in entries) {
      final dayKey = '${entry.loggedAt.year}-${entry.loggedAt.month}-${entry.loggedAt.day}';
      uniqueDays.add(dayKey);
    }
    final sortedDays = uniqueDays.toList()
      ..sort((a, b) => b.compareTo(a));
    
    if (sortedDays.isNotEmpty) {
      final todayKey = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
      if (uniqueDays.contains(todayKey)) {
        currentStreak = 1;
        for (int i = 1; i < 365; i++) {
          final date = DateTime.now().subtract(Duration(days: i));
          final dayKey = '${date.year}-${date.month}-${date.day}';
          if (uniqueDays.contains(dayKey)) {
            currentStreak++;
          } else {
            break;
          }
        }
      }
      
      int streak = 0;
      for (int i = 0; i < 365; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dayKey = '${date.year}-${date.month}-${date.day}';
        if (uniqueDays.contains(dayKey)) {
          streak++;
        } else {
          if (streak > longestStreak) {
            longestStreak = streak;
          }
          streak = 0;
        }
      }
      if (streak > longestStreak) {
        longestStreak = streak;
      }
    }

    return MoodTrends(
      totalEntries: entries.length,
      countsByMood: countsByMood,
      countsByDay: dayMap,
      mostCommonMood: mostCommonMood,
      happinessScore: happinessScore,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      countsByDayOfWeek: dayOfWeekMap,
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

final dayOfWeekTrendsProvider = Provider<Map<String, int>>((ref) {
  final trends = ref.watch(moodTrendsProvider);
  return trends.countsByDayOfWeek;
});

final journalEntriesProvider = Provider<List<MoodEntry>>((ref) {
  final entries = ref.watch(moodEntriesProvider);
  return entries.toList();
});
