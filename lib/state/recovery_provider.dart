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

/// A mood->mood transition insight.
class RecoveryInsight {
  final Mood from;
  final Mood to;
  final int count;
  final double probability; // 0..1 — P(to | from)
  final Mood? highlightMood;

  const RecoveryInsight({
    required this.from,
    required this.to,
    required this.count,
    required this.probability,
    this.highlightMood,
  });

  /// Positive when the transition goes "up" (e.g. awful -> good).
  bool get isRecovery =>
      (_moodScores[to] ?? 3) > (_moodScores[from] ?? 3);
}

class RecoveryResult {
  final Map<Mood, Map<Mood, int>> matrix;
  final Map<Mood, int> rowTotals;
  final List<RecoveryInsight> topTransitions;
  final bool enoughData;

  const RecoveryResult({
    required this.matrix,
    required this.rowTotals,
    required this.topTransitions,
    required this.enoughData,
  });

  static RecoveryResult empty() => RecoveryResult(
        matrix: const {},
        rowTotals: const {},
        topTransitions: const [],
        enoughData: false,
      );

  double probabilityOf(Mood from, Mood to) {
    final row = rowTotals[from] ?? 0;
    if (row == 0) return 0;
    return (matrix[from]?[to] ?? 0) / row;
  }
}

RecoveryResult _compute(List<MoodEntry> entries) {
  if (entries.length < 4) return RecoveryResult.empty();

  // Sort by loggedAt ascending.
  final sorted = entries.toList()
    ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

  final matrix = <Mood, Map<Mood, int>>{
    for (final m in Mood.values) m: <Mood, int>{
      for (final t in Mood.values) t: 0,
    },
  };

  for (int i = 0; i < sorted.length - 1; i++) {
    final from = sorted[i].mood;
    final to = sorted[i + 1].mood;
    matrix[from]![to] = (matrix[from]![to] ?? 0) + 1;
  }

  final rowTotals = <Mood, int>{};
  for (final m in Mood.values) {
    rowTotals[m] = matrix[m]!.values.fold<int>(0, (a, b) => a + b);
  }

  // Collect non-zero transitions, sort by probability * count.
  final insights = <RecoveryInsight>[];
  for (final from in Mood.values) {
    final rowTotal = rowTotals[from] ?? 0;
    if (rowTotal == 0) continue;
    for (final to in Mood.values) {
      final count = matrix[from]![to] ?? 0;
      if (count == 0) continue;
      final probability = count / rowTotal;
      insights.add(
        RecoveryInsight(
          from: from,
          to: to,
          count: count,
          probability: probability,
          highlightMood: to,
        ),
      );
    }
  }

  insights.sort((a, b) {
    final aScore = a.probability * a.count;
    final bScore = b.probability * b.count;
    if (aScore != bScore) return bScore.compareTo(aScore);
    return b.count.compareTo(a.count);
  });

  return RecoveryResult(
    matrix: matrix,
    rowTotals: rowTotals,
    topTransitions: insights.take(5).toList(),
    enoughData: true,
  );
}

final recoveryProvider = Provider<RecoveryResult>((ref) {
  final entries = ref.watch(moodEntriesProvider);
  return _compute(entries);
});
