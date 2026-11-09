import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import 'mood_entries_provider.dart';

const _moodScores = {
  Mood.happy: 5,
  Mood.good: 4,
  Mood.neutral: 3,
  Mood.sad: 2,
  Mood.awful: 1,
};

/// A single "highlight day" — the best day in a given period.
class HighlightDay {
  final DateTime date;
  final double happiness;
  final Mood? dominantMood;
  final int entryCount;

  const HighlightDay({
    required this.date,
    required this.happiness,
    required this.dominantMood,
    required this.entryCount,
  });
}

/// A summary of the user's all-time highlights.
class Highlights {
  final int longestStreak;
  final int totalDaysLogged;
  final List<HighlightDay> topDays;
  final String? firstEntryDate;

  const Highlights({
    required this.longestStreak,
    required this.totalDaysLogged,
    required this.topDays,
    required this.firstEntryDate,
  });

  static Highlights empty() => const Highlights(
        longestStreak: 0,
        totalDaysLogged: 0,
        topDays: [],
        firstEntryDate: null,
      );
}

String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

Highlights _compute(List<MoodEntry> entries) {
  if (entries.isEmpty) return Highlights.empty();

  // Group by day.
  final byDay = <String, List<MoodEntry>>{};
  for (final e in entries) {
    byDay.putIfAbsent(_dayKey(e.loggedAt), () => []).add(e);
  }

  final days = byDay.keys.toList()
    ..sort((a, b) => b.compareTo(a));

  final totalDaysLogged = days.length;

  // Longest streak.
  final daySet = days.toSet();
  int longest = 0;
  int streak = 0;
  DateTime? cursor;
  for (final key in days) {
    final parts = key.split('-');
    final d = DateTime(int.parse(parts[0]), int.parse(parts[1]),
        int.parse(parts[2]));
    if (cursor != null) {
      final diff = cursor!.difference(d).inDays;
      if (diff == 1) {
        streak++;
      } else {
        streak = 1;
      }
    } else {
      streak = 1;
    }
    if (streak > longest) longest = streak;
    cursor = d;
  }

  // Top days by happiness.
  final topDays = <HighlightDay>[];
  for (final key in days) {
    final dayEntries = byDay[key]!;
    final total = dayEntries.fold<int>(
        0, (s, e) => s + (_moodScores[e.mood] ?? 3));
    final happiness = (total / dayEntries.length / 5) * 100;

    final moodCounts = <Mood, int>{};
    for (final m in Mood.values) {
      moodCounts[m] = 0;
    }
    for (final e in dayEntries) {
      moodCounts.update(e.mood, (v) => v + 1);
    }
    Mood? dominant;
    int max = 0;
    for (final e in moodCounts.entries) {
      if (e.value > max) {
        max = e.value;
        dominant = e.key;
      }
    }

    final parts = key.split('-');
    final d = DateTime(int.parse(parts[0]), int.parse(parts[1]),
        int.parse(parts[2]));
    topDays.add(HighlightDay(
      date: d,
      happiness: happiness,
      dominantMood: dominant,
      entryCount: dayEntries.length,
    ));
  }
  topDays.sort((a, b) => b.happiness.compareTo(a.happiness));

  // First entry date.
  final firstEntry = entries.fold(entries.first,
      (a, b) => b.loggedAt.isBefore(a.loggedAt) ? b : a);
  final firstDate = _dayKey(firstEntry.loggedAt);

  return Highlights(
    longestStreak: longest,
    totalDaysLogged: totalDaysLogged,
    topDays: topDays.take(5).toList(),
    firstEntryDate: firstDate,
  );
}

final highlightsProvider = Provider<Highlights>((ref) {
  final entries = ref.watch(moodEntriesProvider);
  return _compute(entries);
});
