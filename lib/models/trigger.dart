import 'package:flutter/material.dart';

/// Common life factors that influence mood.
enum Trigger {
  sleep('Sleep', Icons.bedtime_outlined, Color(0xFF7986CB)),
  exercise('Exercise', Icons.directions_run, Color(0xFF66BB6A)),
  food('Food', Icons.restaurant, Color(0xFFFFB74D)),
  weather('Weather', Icons.wb_sunny_outlined, Color(0xFF4FC3F7)),
  work('Work', Icons.work_outline, Color(0xFF90A4AE)),
  relationships('People', Icons.people_outline, Color(0xFFEF5350)),
  money('Money', Icons.account_balance_wallet_outlined, Color(0xFF8D6E63)),
  health('Health', Icons.favorite_outline, Color(0xFFEC407A)),
  social('Social', Icons.group_work_outlined, Color(0xFF26A69A)),
  entertainment('Fun', Icons.movie_outlined, Color(0xFFAB47BC));

  const Trigger(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
