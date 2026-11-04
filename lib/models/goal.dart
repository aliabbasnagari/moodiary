import 'dart:convert';

/// A user's logging goal and the date they last logged.
class Goal {
  const Goal({
    this.type = GoalType.daily,
    this.dailyTarget = 1,
    this.weeklyTarget = 5,
    this.lastLoggedDateKey,
  });

  /// `daily` tracks entries today; `weekly` tracks entries this week.
  final GoalType type;
  final int dailyTarget;
  final int weeklyTarget;
  final String? lastLoggedDateKey;

  Goal copyWith({
    GoalType? type,
    int? dailyTarget,
    int? weeklyTarget,
    String? lastLoggedDateKey,
    bool clearLastLogged = false,
  }) {
    return Goal(
      type: type ?? this.type,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      lastLoggedDateKey:
          clearLastLogged ? null : (lastLoggedDateKey ?? this.lastLoggedDateKey),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'dailyTarget': dailyTarget,
        'weeklyTarget': weeklyTarget,
        if (lastLoggedDateKey != null) 'lastLoggedDateKey': lastLoggedDateKey,
      };

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      type: GoalType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => GoalType.daily,
      ),
      dailyTarget: (json['dailyTarget'] as int?) ?? 1,
      weeklyTarget: (json['weeklyTarget'] as int?) ?? 5,
      lastLoggedDateKey: json['lastLoggedDateKey'] as String?,
    );
  }

  String encode() => jsonEncode(toJson());

  factory Goal.decode(String? raw) {
    if (raw == null || raw.isEmpty) return const Goal();
    try {
      return Goal.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Exception {
      return const Goal();
    }
  }
}

enum GoalType { daily, weekly }

/// Key for a calendar day, e.g. `2026-11-04`.
String dayKeyOf(DateTime d) => '${d.year}-${d.month}-${d.day}';
