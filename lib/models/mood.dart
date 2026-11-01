import 'package:flutter/material.dart';

import 'trigger.dart';

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
  /// Creates a brand-new entry with a generated id.
  MoodEntry({
    required this.mood,
    required this.loggedAt,
    this.note,
    this.promptResponse,
    this.triggers = const [],
  }) : id = _generateId();

  const MoodEntry._({
    required this.id,
    required this.mood,
    required this.loggedAt,
    required this.note,
    required this.promptResponse,
    required this.triggers,
  });

  /// Restores an entry from persistence, keeping its original id.
  factory MoodEntry.restore({
    required String id,
    required Mood mood,
    required DateTime loggedAt,
    String? note,
    String? promptResponse,
    List<Trigger> triggers = const [],
  }) {
    return MoodEntry._(
      id: id,
      mood: mood,
      loggedAt: loggedAt,
      note: note,
      promptResponse: promptResponse,
      triggers: triggers,
    );
  }

  final String id;
  final Mood mood;
  final DateTime loggedAt;
  final String? note;
  final String? promptResponse;
  final List<Trigger> triggers;

  static String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  MoodEntry copyWith({
    Mood? mood,
    DateTime? loggedAt,
    String? note,
    String? promptResponse,
    List<Trigger>? triggers,
    bool clearNote = false,
    bool clearPromptResponse = false,
  }) {
    return MoodEntry._(
      id: id,
      mood: mood ?? this.mood,
      loggedAt: loggedAt ?? this.loggedAt,
      note: clearNote ? null : (note ?? this.note),
      promptResponse:
          clearPromptResponse ? null : (promptResponse ?? this.promptResponse),
      triggers: triggers ?? this.triggers,
    );
  }
}
