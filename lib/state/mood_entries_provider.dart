import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood.dart';
import '../models/mood_entry_serializers.dart';
import '../models/trigger.dart';

const _kEntriesKey = 'mood_entries_v1';

/// Holds the user's logged moods.
///
/// Entries are persisted to [SharedPreferences] so the journal, trends,
/// and streaks survive app restarts. The in-memory list is the source of
/// truth for the UI; writes are debounced before hitting storage.
class MoodEntriesNotifier extends StateNotifier<List<MoodEntry>> {
  MoodEntriesNotifier() : super(const []) {
    load();
  }

  SharedPreferences? _prefs;
  Timer? _saveTimer;
  bool _loading = true;

  /// Restores previously saved entries from storage.
  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs?.getString(_kEntriesKey);
      if (!mounted) return;
      final entries = MoodEntrySerializers.decode(raw);
      if (entries.isNotEmpty) {
        state = entries;
      }
    } catch (_) {
      // Storage unavailable (e.g. early startup) — stay in-memory.
    } finally {
      if (mounted) _loading = false;
    }
  }

  /// Whether the initial load from storage has completed.
  bool get isLoading => _loading;

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _persist);
  }

  Future<void> _persist() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    try {
      await prefs.setString(_kEntriesKey, MoodEntrySerializers.encode(state));
    } catch (_) {
      // Ignore write failures; in-memory state remains valid.
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

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
    _scheduleSave();
  }

  void updateEntry(MoodEntry updated) {
    state = [
      for (final entry in state)
        if (entry.id == updated.id) updated else entry,
    ];
    _scheduleSave();
  }

  void removeEntry(String id) {
    state = [
      for (final entry in state)
        if (entry.id != id) entry,
    ];
    _scheduleSave();
  }

  void clear() {
    state = const [];
    _scheduleSave();
  }
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
