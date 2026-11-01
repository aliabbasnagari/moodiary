import 'dart:convert';

import 'mood.dart';
import 'trigger.dart';

/// Converts [MoodEntry] lists to/from a JSON string for persistence.
///
/// The wire format is a JSON array of objects:
/// ```json
/// [
///   {
///     "id": "1234567890",
///     "mood": "happy",
///     "loggedAt": 1717000000000,
///     "note": "great day",
///     "promptResponse": "sunshine",
///     "triggers": ["sleep", "exercise"]
///   }
/// ]
/// ```
class MoodEntrySerializers {
  const MoodEntrySerializers._();

  static String encode(List<MoodEntry> entries) {
    return jsonEncode([
      for (final entry in entries) {
        {
          'id': entry.id,
          'mood': entry.mood.name,
          'loggedAt': entry.loggedAt.millisecondsSinceEpoch,
          if (entry.note != null) 'note': entry.note,
          if (entry.promptResponse != null)
            'promptResponse': entry.promptResponse,
          'triggers': [for (final t in entry.triggers) t.name],
        }
      },
    ]);
  }

  static List<MoodEntry> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];

    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) _decodeEntry(item),
    ];
  }

  static MoodEntry _decodeEntry(Map<String, dynamic> json) {
    return MoodEntry.restore(
      id: (json['id'] as String?) ?? _fallbackId(),
      mood: Mood.values.firstWhere(
        (m) => m.name == json['mood'],
        orElse: () => Mood.neutral,
      ),
      loggedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['loggedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      note: json['note'] as String?,
      promptResponse: json['promptResponse'] as String?,
      triggers: [
        for (final name in (json['triggers'] as List? ?? const []))
          if (name is String)
            Trigger.values.firstWhere(
              (t) => t.name == name,
              orElse: () => Trigger.sleep,
            ),
      ],
    );
  }

  static String _fallbackId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
