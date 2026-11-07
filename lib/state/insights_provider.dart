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

double _avg(List<MoodEntry> entries) {
  if (entries.isEmpty) return 3;
  final total = entries.fold<int>(
      0, (s, e) => s + (_moodScores[e.mood] ?? 3));
  return total / entries.length;
}

/// A single actionable insight derived from the user's data.
class Insight {
  final Trigger trigger;
  final String headline;
  final String detail;
  final double strength; // 0..1, higher = stronger signal
  final Mood? highlightedMood;

  const Insight({
    required this.trigger,
    required this.headline,
    required this.detail,
    required this.strength,
    this.highlightedMood,
  });
}

class InsightsResult {
  final List<Insight> insights;
  final bool enoughData;

  const InsightsResult({
    required this.insights,
    required this.enoughData,
  });

  static InsightsResult empty() =>
      const InsightsResult(insights: [], enoughData: false);
}

InsightsResult _compute(List<MoodEntry> entries) {
  if (entries.length < 5) return InsightsResult.empty();

  final overallAvg = _avg(entries);
  final results = <Insight>[];

  for (final trigger in Trigger.values) {
    final tagged =
        entries.where((e) => e.triggers.contains(trigger)).toList();
    if (tagged.length < 3) continue;

    final taggedAvg = _avg(tagged);
    final diff = taggedAvg - overallAvg;
    final absDiff = diff.abs();
    if (absDiff < 0.35) continue;

    // Determine the dominant mood among tagged entries.
    final moodCounts = <Mood, int>{};
    for (final m in Mood.values) {
      moodCounts[m] = 0;
    }
    for (final e in tagged) {
      moodCounts.update(e.mood, (v) => v + 1);
    }
    Mood? highlight;
    int max = 0;
    for (final e in moodCounts.entries) {
      if (e.value > max) {
        max = e.value;
        highlight = e.key;
      }
    }

    final positive = diff > 0;
    final moodWord = highlight != null ? highlight!.label : 'mood';
    final headline = positive
        ? 'Days with ${trigger.label} lift your mood'
        : 'Days with ${trigger.label} drag your mood';
    final detail = positive
        ? 'When you tag ${trigger.label}, your mood is on average ${absDiff.toStringAsFixed(1)} points higher than usual — most often feeling $moodWord.'
        : 'When you tag ${trigger.label}, your mood is on average ${absDiff.toStringAsFixed(1)} points lower than usual — most often feeling $moodWord.';

    results.add(
      Insight(
        trigger: trigger,
        headline: headline,
        detail: detail,
        strength: (absDiff / 2).clamp(0.0, 1.0),
        highlightedMood: highlight,
      ),
    );
  }

  // Sort by strength, take the top 3.
  results.sort((a, b) => b.strength.compareTo(a.strength));
  return InsightsResult(
    insights: results.take(3).toList(),
    enoughData: true,
  );
}

final insightsProvider = Provider<InsightsResult>((ref) {
  final entries = ref.watch(moodEntriesProvider);
  return _compute(entries);
});
