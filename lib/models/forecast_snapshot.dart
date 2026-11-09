import 'dart:convert';

import 'mood.dart';

/// A one-day forecast snapshot: what the app predicted for [day] and what
/// actually happened.
class ForecastSnapshot {
  const ForecastSnapshot({
    required this.day,
    required this.predicted,
    required this.actual,
    required this.hit,
  });

  final String day;
  final Mood predicted;
  final Mood actual;
  final bool hit;

  Map<String, dynamic> toJson() => {
        'day': day,
        'predicted': predicted.name,
        'actual': actual.name,
        'hit': hit,
      };

  factory ForecastSnapshot.fromJson(Map<String, dynamic> json) {
    return ForecastSnapshot(
      day: (json['day'] as String?) ?? '',
      predicted: Mood.values.firstWhere(
        (m) => m.name == json['predicted'],
        orElse: () => Mood.neutral,
      ),
      actual: Mood.values.firstWhere(
        (m) => m.name == json['actual'],
        orElse: () => Mood.neutral,
      ),
      hit: (json['hit'] as bool?) ?? false,
    );
  }

  String encode() => jsonEncode(toJson());

  factory ForecastSnapshot.decode(String? raw) {
    if (raw == null || raw.isEmpty) return const ForecastSnapshot(
          day: '',
          predicted: Mood.neutral,
          actual: Mood.neutral,
          hit: false,
        );
    try {
      return ForecastSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Exception {
      return const ForecastSnapshot(
        day: '',
        predicted: Mood.neutral,
        actual: Mood.neutral,
        hit: false,
      );
    }
  }
}
