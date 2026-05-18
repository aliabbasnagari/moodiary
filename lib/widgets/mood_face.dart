import 'package:flutter/material.dart';

import '../models/mood.dart';
import 'mood_face_painter.dart';

/// Convenience wrapper around [MoodFacePainter] so callers don't have to
/// build a `CustomPaint` + `SizedBox` every time.
class MoodFace extends StatelessWidget {
  const MoodFace({
    super.key,
    required this.mood,
    required this.size,
    this.animation = 0,
  });

  final Mood mood;
  final double size;
  final double animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: MoodFacePainter(mood: mood, animation: animation),
      ),
    );
  }
}
