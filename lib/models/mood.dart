import 'package:flutter/material.dart';

/// The set of moods a user can log.
///
/// Each mood carries a label and an accent color used across the UI
/// (timeline cards, the tap button, etc).
enum Mood {
  happy('Happy', Color(0xFFFFC857)),
  good('Good', Color(0xFF8AC926)),
  neutral('Neutral', Color(0xFF90A4AE)),
  sad('Sad', Color(0xFF4A90E2)),
  awful('Awful', Color(0xFFE76F51));

  const Mood(this.label, this.color);

  final String label;
  final Color color;
}

/// A single mood log entry.
class MoodEntry {
  const MoodEntry({required this.mood, required this.loggedAt});

  final Mood mood;
  final DateTime loggedAt;
}
