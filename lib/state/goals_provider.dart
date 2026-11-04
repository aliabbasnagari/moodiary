import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/goal.dart';
import 'mood_entries_provider.dart';

const _kGoalKey = 'mood_goal_v1';
const _kNudgeDismissed = 'nudge_dismissed_v1';

/// The current goal setting, persisted across restarts.
class GoalsNotifier extends StateNotifier<Goal> {
  GoalsNotifier() : super(const Goal()) {
    _load();
  }

  SharedPreferences? _prefs;

  Future<void> _load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      state = Goal.decode(_prefs?.getString(_kGoalKey));
    } catch (_) {}
  }

  Future<void> set(Goal goal) async {
    state = goal;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      await prefs.setString(_kGoalKey, goal.encode());
    } catch (_) {}
  }

  /// Marks that the user logged today, so nudges stop showing.
  Future<void> markLoggedToday() async {
    await set(state.copyWith(lastLoggedDateKey: dayKeyOf(DateTime.now())));
  }
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, Goal>((ref) => GoalsNotifier());

/// Tracks whether today's gentle nudge was dismissed.
final nudgeDismissedProvider = StateProvider<bool>((ref) => false);

/// The date of the most recent entry, or null.
final latestEntryDateProvider = Provider<DateTime?>((ref) {
  final entries = ref.watch(moodEntriesProvider);
  if (entries.isEmpty) return null;
  DateTime latest = entries.first.loggedAt;
  for (final e in entries) {
    if (e.loggedAt.isAfter(latest)) latest = e.loggedAt;
  }
  return latest;
});

/// Number of entries logged today.
final entriesTodayProvider = Provider<int>((ref) {
  final entries = ref.watch(moodEntriesProvider);
  final today = dayKeyOf(DateTime.now());
  return entries
      .where((e) => dayKeyOf(e.loggedAt) == today)
      .length;
});

/// Number of entries logged in the last 7 days.
final entriesThisWeekProvider = Provider<int>((ref) {
  final entries = ref.watch(moodEntriesProvider);
  final now = DateTime.now();
  final weekAgo = DateTime(now.year, now.month, now.day - 6);
  return entries.where((e) => !e.loggedAt.isBefore(weekAgo)).length;
});

/// True when the user hasn't logged today yet (drives the nudge banner).
final shouldNudgeProvider = Provider<bool>((ref) {
  if (ref.watch(entriesTodayProvider) > 0) return false;
  if (ref.watch(nudgeDismissedProvider)) return false;
  return true;
});
