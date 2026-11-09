import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import '../models/trigger.dart';
import 'forecast_accuracy_provider.dart';
import 'mood_entries_provider.dart';

const _moodScores = {
  Mood.happy: 5,
  Mood.good: 4,
  Mood.neutral: 3,
  Mood.sad: 2,
  Mood.awful: 1,
};

/// A qualitative forecast for today's mood.
class MoodForecast {
  final double score;
  final String label;
  final String reason;
  final double confidence;
  final List<Factor> factors;

  const MoodForecast({
    required this.score,
    required this.label,
    required this.reason,
    required this.confidence,
    required this.factors,
  });

  static const _empty = MoodForecast(
    score: 0.5,
    label: 'Not enough data',
    reason: 'Log a few moods to unlock your forecast.',
    confidence: 0,
    factors: [],
  );

  static MoodForecast empty() => _empty;
}

/// A single named contribution to the forecast, for display.
class Factor {
  final String name;
  final double weight;
  final String detail;

  const Factor(this.name, this.weight, this.detail);
}

double _avg(List<MoodEntry> entries) {
  if (entries.isEmpty) return 3;
  final total = entries.fold<int>(0, (s, e) => s + (_moodScores[e.mood] ?? 3));
  return total / entries.length;
}

double _clamp01(double v) => v.clamp(0.0, 1.0);

double _normalized(double score) => (score - 1) / 4; // 1..5 -> 0..1

MoodForecast _build(List<MoodEntry> entries) {
  if (entries.isEmpty) return MoodForecast.empty();

  // 1. Recent-mood momentum (last 3 entries, recency-weighted).
  final recent = entries.take(3).toList();
  final weights = [0.5, 0.3, 0.2];
  double momentum = 0;
  double wSum = 0;
  for (int i = 0; i < recent.length; i++) {
    final double w = i < weights.length ? weights[i] : 0.1;
    momentum += _normalized((_moodScores[recent[i].mood] ?? 3).toDouble()) * w;
    wSum += w;
  }
  momentum = wSum == 0 ? 0.5 : momentum / wSum;

  // 2. Trigger signal: how do days tagged with your most common trigger
  //    compare to your overall average?
  final triggerCounts = <Trigger, int>{};
  for (final e in entries) {
    for (final t in e.triggers) {
      triggerCounts.update(t, (v) => v + 1, ifAbsent: () => 1);
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

  double triggerSignal = 0;
  String? triggerDetail;
  if (topTrigger != null) {
    final tagged =
        entries.where((e) => e.triggers.contains(topTrigger)).toList();
    final taggedAvg = _avg(tagged);
    final overallAvg = _avg(entries);
    // How much better/worse tagged days are vs overall, normalized.
    triggerSignal =
        _normalized((taggedAvg - overallAvg).clamp(-2.0, 2.0) + 3.0);
    triggerDetail =
        '${topTrigger!.label} days are ${(taggedAvg - overallAvg).abs().toStringAsFixed(1)} pts '
        '${taggedAvg >= overallAvg ? 'above' : 'below'} your average';
  }

  // 3. Time-of-day baseline (moods trend lower toward evening).
  final hour = DateTime.now().hour;
  final timeOfDay = (12 - (hour - 12).abs()) / 12; // peaks midday

  // Combine into a 0..1 score.
  double score;
  if (entries.length >= 3 && topTrigger != null) {
    score = momentum * 0.5 + triggerSignal * 0.3 + timeOfDay * 0.2;
  } else if (entries.length >= 3) {
    score = momentum * 0.7 + timeOfDay * 0.3;
  } else {
    score = momentum * 0.8 + timeOfDay * 0.2;
  }
  score = _clamp01(score);

  // Confidence grows with data volume.
  final confidence = _clamp01(entries.length / 10) *
      (topTrigger != null ? 1.0 : 0.7);

  // Label + reason.
  String label;
  String reason;
  if (score >= 0.7) {
    label = 'Trending up';
    reason = 'Your recent moods have been lifting — momentum is on your side.';
  } else if (score >= 0.5) {
    label = 'Steady';
    reason = 'You\'ve been holding steady. A calm day is likely.';
  } else if (score >= 0.35) {
    label = 'A bit low';
    reason = 'Moods have dipped lately. Be gentle with yourself today.';
  } else {
    label = 'Tough stretch';
    reason = 'Recent days have been rough. Consider a lighter plan.';
  }

  final factors = <Factor>[
    Factor('Recent mood', momentum, 'Based on your last ${recent.length} check-in${recent.length == 1 ? '' : 's'}'),
    if (topTrigger != null)
      Factor(topTrigger!.label, triggerSignal, triggerDetail!),
    Factor('Time of day', timeOfDay, hour < 12 ? 'Morning tends to lift moods' : 'Evenings tend to dip'),
  ];

  return MoodForecast(
    score: score,
    label: label,
    reason: reason,
    confidence: confidence,
    factors: factors,
  );
}

/// A one-day-ahead style forecast derived from all logged entries.
///
/// Side effect: whenever the forecast changes, a pending snapshot is recorded
/// so tomorrow's accuracy can be computed.
final moodForecastProvider = Provider<MoodForecast>((ref) {
  final entries = ref.watch(moodEntriesProvider);
  final forecast = _build(entries);
  final today = _dayKey(DateTime.now());
  final predicted = _predictedMood(forecast.score);
  ref
      .read(forecastAccuracyProvider.notifier)
      .recordToday(today: today, predicted: predicted);
  return forecast;
});

String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

Mood _predictedMood(double score) {
  if (score >= 0.7) return Mood.happy;
  if (score >= 0.5) return Mood.good;
  if (score >= 0.35) return Mood.neutral;
  if (score >= 0.2) return Mood.sad;
  return Mood.awful;
}
