import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/forecast_snapshot.dart';
import '../models/mood.dart';
import 'mood_entries_provider.dart';

const _kSnapshotsKey = 'forecast_snapshots_v1';
const _kPendingKey = 'forecast_pending_v1';

class _PendingForecast {
  final String day;
  final Mood predicted;
  final String savedOnDay;

  const _PendingForecast({
    required this.day,
    required this.predicted,
    required this.savedOnDay,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'predicted': predicted.name,
        'savedOnDay': savedOnDay,
      };

  factory _PendingForecast.fromJson(Map<String, dynamic> json) {
    return _PendingForecast(
      day: (json['day'] as String?) ?? '',
      predicted: Mood.values.firstWhere(
        (m) => m.name == json['predicted'],
        orElse: () => Mood.neutral,
      ),
      savedOnDay: (json['savedOnDay'] as String?) ?? '',
    );
  }
}

/// Records one snapshot per day, then computes accuracy metrics.
class ForecastAccuracyNotifier extends StateNotifier<List<ForecastSnapshot>> {
  ForecastAccuracyNotifier() : super(const []) {
    _load();
  }

  SharedPreferences? _prefs;
  Timer? _saveTimer;

  Future<void> _load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final raw = _prefs?.getString(_kSnapshotsKey);
      if (raw == null || raw.isEmpty) return;
      final dynamic decoded;
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        return;
      }
      if (decoded is! List) return;
      state = [
        for (final item in decoded)
          if (item is Map<String, dynamic>)
            ForecastSnapshot.fromJson(item),
      ];
    } catch (_) {}
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _persist);
  }

  Future<void> _persist() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    try {
      final encoded = jsonEncode([
        for (final s in state) s.toJson(),
      ]);
      await prefs.setString(_kSnapshotsKey, encoded);
    } catch (_) {}
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  /// Records today's forecast (called whenever the forecast changes).
  /// If a pending forecast from yesterday exists and the user has logged a
  /// mood today, it is finalized into a snapshot.
  Future<void> recordToday({
    required String today,
    required Mood predicted,
    Mood? actualToday,
  }) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;

      // 1. Try to finalize a pending forecast from yesterday.
      final pendingRaw = prefs.getString(_kPendingKey);
      if (pendingRaw != null && pendingRaw.isNotEmpty) {
        final pending = _PendingForecast.fromJson(
            jsonDecode(pendingRaw) as Map<String, dynamic>);
        if (actualToday != null && pending.day != today) {
          final hit = pending.predicted == actualToday;
          state = [
            ForecastSnapshot(
              day: pending.day,
              predicted: pending.predicted,
              actual: actualToday,
              hit: hit,
            ),
            ...state,
          ];
          await prefs.remove(_kPendingKey);
        }
      }

      // 2. Save today's forecast as pending for tomorrow.
      final pending = _PendingForecast(
        day: today,
        predicted: predicted,
        savedOnDay: today,
      );
      await prefs.setString(_kPendingKey, jsonEncode(pending.toJson()));

      _scheduleSave();
    } catch (_) {}
  }
}

final forecastAccuracyProvider =
    StateNotifierProvider<ForecastAccuracyNotifier, List<ForecastSnapshot>>(
  (ref) => ForecastAccuracyNotifier(),
);

/// The user's overall forecast accuracy (0..1), 0 when no data.
final forecastHitRateProvider = Provider<double>((ref) {
  final snapshots = ref.watch(forecastAccuracyProvider);
  if (snapshots.isEmpty) return 0;
  final hits = snapshots.where((s) => s.hit).length;
  return hits / snapshots.length;
});

/// How many of the last N snapshots were hits.
final recentForecastStreakProvider = Provider<int>((ref) {
  final snapshots = ref.watch(forecastAccuracyProvider);
  if (snapshots.isEmpty) return 0;
  int streak = 0;
  for (final s in snapshots) {
    if (!s.hit) break;
    streak++;
  }
  return streak;
});
