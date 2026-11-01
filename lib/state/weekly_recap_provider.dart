import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import '../models/trigger.dart';
import 'mood_entries_provider.dart';

const _moodScores = {
  Mood.happy: 5,
  Mood.good: 4,
  Mood.neutral: 3,
  Mood.sad: 2,
  Mood.awful: 1,
};

/// A summary of the user's moods over the last 7 days.
class WeeklyRecap {
  final int entryCount;
  final DateTime weekStart;
  final Map<Mood, int> countsByMood;
  final Mood? dominantMood;
  final double happinessScore;
  final String? bestDay;
  final String? worstDay;
  final Trigger? topTrigger;
  final int loggingDays;

  const WeeklyRecap({
    required this.entryCount,
    required this.weekStart,
    required this.countsByMood,
    required this.dominantMood,
    required this.happinessScore,
    required this.bestDay,
    required this.worstDay,
    required this.topTrigger,
    required this.loggingDays,
  });

  bool get isEmpty => entryCount == 0;

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month}-${d.day}';

  static double _happinessFor(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;
    final total = entries.fold<int>(
        0, (sum, e) => sum + (_moodScores[e.mood] ?? 3));
    return (total / entries.length / 5) * 100;
  }

  /// Builds a recap from all [entries], scoped to [weekStart] .. now.
  static WeeklyRecap build(List<MoodEntry> entries, DateTime weekStart) {
    if (entries.isEmpty) {
      return WeeklyRecap(
        entryCount: 0,
        weekStart: weekStart,
        countsByMood: const {},
        dominantMood: null,
        happinessScore: 0,
        bestDay: null,
        worstDay: null,
        topTrigger: null,
        loggingDays: 0,
      );
    }

    final inWeek = entries
        .where((e) => !e.loggedAt.isBefore(weekStart))
        .toList();

    if (inWeek.isEmpty) {
      return WeeklyRecap(
        entryCount: 0,
        weekStart: weekStart,
        countsByMood: const {},
        dominantMood: null,
        happinessScore: 0,
        bestDay: null,
        worstDay: null,
        topTrigger: null,
        loggingDays: 0,
      );
    }

    final counts = <Mood, int>{};
    for (final m in Mood.values) {
      counts[m] = 0;
    }
    for (final e in inWeek) {
      counts.update(e.mood, (v) => v! + 1);
    }

    Mood? dominant;
    int max = 0;
    for (final e in counts.entries) {
      if (e.value > max) {
        max = e.value;
        dominant = e.key;
      }
    }

    // Best / worst day by average happiness score.
    final byDay = <String, List<MoodEntry>>{};
    for (final e in inWeek) {
      byDay.putIfAbsent(_dayKey(e.loggedAt), () => []).add(e);
    }

    String? bestDay;
    String? worstDay;
    double bestScore = -1;
    double worstScore = 101;
    for (final e in byDay.entries) {
      final score = _happinessFor(e.value);
      if (score > bestScore) {
        bestScore = score;
        bestDay = e.key;
      }
      if (score < worstScore) {
        worstScore = score;
        worstDay = e.key;
      }
    }

    // Top trigger within the week.
    final triggerCounts = <Trigger, int>{};
    for (final e in inWeek) {
      for (final t in e.triggers) {
        triggerCounts.update(t, (v) => v! + 1, ifAbsent: () => 1);
      }
    }
    Trigger? topTrigger;
    int topCount = 0;
    for (final e in triggerCounts.entries) {
      if (e.value > topCount) {
        topCount = e.value;
        topTrigger = e.key;
      }
    }

    return WeeklyRecap(
      entryCount: inWeek.length,
      weekStart: weekStart,
      countsByMood: counts,
      dominantMood: dominant,
      happinessScore: _happinessFor(inWeek),
      bestDay: bestDay,
      worstDay: worstDay,
      topTrigger: topTrigger,
      loggingDays: byDay.length,
    );
  }
}

/// The start of the current 7-day window (7 days ago, start of day).
DateTime _weekStart() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - 6);
}

final weeklyRecapProvider = Provider<WeeklyRecap>((ref) {
  final entries = ref.watch(moodEntriesProvider);
  return WeeklyRecap.build(entries, _weekStart());
});
