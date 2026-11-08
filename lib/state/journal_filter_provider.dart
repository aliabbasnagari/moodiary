import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import '../models/trigger.dart';

enum JournalDateRange { all, today, last7, last30 }

/// The user's current journal filter state.
class JournalFilter {
  const JournalFilter({
    this.query = '',
    this.mood,
    this.trigger,
    this.dateRange = JournalDateRange.all,
  });

  final String query;
  final Mood? mood;
  final Trigger? trigger;
  final JournalDateRange dateRange;

  bool get isActive =>
      query.isNotEmpty || mood != null || trigger != null ||
          dateRange != JournalDateRange.all;

  bool matches(MoodEntry entry) {
    if (mood != null && entry.mood != mood) return false;
    if (trigger != null && !entry.triggers.contains(trigger!)) return false;

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      final note = entry.note?.toLowerCase() ?? '';
      final response = entry.promptResponse?.toLowerCase() ?? '';
      if (!note.contains(q) && !response.contains(q)) return false;
    }

    if (dateRange != JournalDateRange.all) {
      final now = DateTime.now();
      switch (dateRange) {
        case JournalDateRange.today:
          if (entry.loggedAt.year != now.year ||
              entry.loggedAt.month != now.month ||
              entry.loggedAt.day != now.day) {
            return false;
          }
        case JournalDateRange.last7:
          if (entry.loggedAt.isBefore(
              DateTime(now.year, now.month, now.day - 6))) {
            return false;
          }
        case JournalDateRange.last30:
          if (entry.loggedAt.isBefore(
              DateTime(now.year, now.month, now.day - 29))) {
            return false;
          }
        case JournalDateRange.all:
          break;
      }
    }

    return true;
  }

  JournalFilter copyWith({
    String? query,
    Mood? mood,
    Trigger? trigger,
    JournalDateRange? dateRange,
    bool clearMood = false,
    bool clearTrigger = false,
  }) {
    return JournalFilter(
      query: query ?? this.query,
      mood: clearMood ? null : (mood ?? this.mood),
      trigger: clearTrigger ? null : (trigger ?? this.trigger),
      dateRange: dateRange ?? this.dateRange,
    );
  }

  JournalFilter clear() => const JournalFilter();
}

final journalFilterProvider = StateProvider<JournalFilter>((ref) {
  return const JournalFilter();
});
