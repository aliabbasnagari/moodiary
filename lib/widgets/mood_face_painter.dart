import 'package:flutter/material.dart';

import '../models/mood.dart';

/// Paints a mood face onto the canvas using primitive draw calls
/// (`drawCircle`, `drawArc`, `drawPath`, `drawLine`).
///
/// All geometry is computed relative to the painter size so the face
/// scales cleanly from a small timeline card up to a hero-size display.
///
/// [animation] is an optional 0..1 value used to give the face a tiny
/// bit of life when an entry is tapped:
///   - eyes blink (close briefly around t=0.5)
///   - mouth amplitude pulses slightly
class MoodFacePainter extends CustomPainter {
  MoodFacePainter({
    required this.mood,
    this.animation = 0,
  }) : super(repaint: null);

  final Mood mood;

  /// 0..1 — when non-zero, the face plays a small expression beat.
  final double animation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;

    _paintHead(canvas, center, radius);
    _paintEyes(canvas, center, radius);
    _paintEyebrows(canvas, center, radius);
    _paintMouth(canvas, center, radius);
  }

  // ---------------------------------------------------------------------------
  // Head
  // ---------------------------------------------------------------------------

  void _paintHead(Canvas canvas, Offset center, double radius) {
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = mood.color;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..color = Colors.black.withValues(alpha: 0.85);

    canvas.drawCircle(center, radius * 0.95, fill);
    canvas.drawCircle(center, radius * 0.95, stroke);
  }

  // ---------------------------------------------------------------------------
  // Eyes
  // ---------------------------------------------------------------------------

  void _paintEyes(Canvas canvas, Offset center, double radius) {
    final eyeOffsetX = radius * 0.35;
    final eyeOffsetY = -radius * 0.15;
    final left = center.translate(-eyeOffsetX, eyeOffsetY);
    final right = center.translate(eyeOffsetX, eyeOffsetY);

    final eyePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black87;

    // Tiny "blink" near the middle of the animation.
    final blink = (animation > 0)
        ? (1 - (4 * (animation - 0.5) * (animation - 0.5))).clamp(0.0, 1.0)
        : 0.0;
    final openness = (1 - blink * 0.85).clamp(0.05, 1.0);

    final eyeR = radius * 0.11;

    switch (mood) {
      case Mood.happy:
      case Mood.good:
      case Mood.neutral:
      case Mood.sad:
        // Round eyes, scaled vertically by `openness` for the blink.
        _drawScaledCircle(canvas, left, eyeR, openness, eyePaint);
        _drawScaledCircle(canvas, right, eyeR, openness, eyePaint);
      case Mood.awful:
        // Squeezed-shut "X"-style eyes drawn with two line strokes each.
        final linePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = radius * 0.07
          ..color = Colors.black87;
        _drawCross(canvas, left, eyeR * 1.1, linePaint);
        _drawCross(canvas, right, eyeR * 1.1, linePaint);
    }
  }

  void _drawScaledCircle(
    Canvas canvas,
    Offset c,
    double r,
    double yScale,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1, yScale);
    canvas.drawCircle(Offset.zero, r, paint);
    canvas.restore();
  }

  void _drawCross(Canvas canvas, Offset c, double r, Paint paint) {
    canvas.drawLine(c.translate(-r, -r), c.translate(r, r), paint);
    canvas.drawLine(c.translate(-r, r), c.translate(r, -r), paint);
  }

  // ---------------------------------------------------------------------------
  // Eyebrows — these are what give each face its character.
  // ---------------------------------------------------------------------------

  void _paintEyebrows(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.07
      ..color = Colors.black87;

    final eyeOffsetX = radius * 0.35;
    final browY = center.dy - radius * 0.42;
    final browLen = radius * 0.28;

    // Angle in radians: negative tilts the outer end up, positive tilts it down.
    final double angle;
    switch (mood) {
      case Mood.happy:
        angle = -0.25; // raised, friendly arch
      case Mood.good:
        angle = -0.12;
      case Mood.neutral:
        angle = 0.0;
      case Mood.sad:
        angle = 0.35; // inner-up worried brows
      case Mood.awful:
        angle = 0.55; // strong furrow
    }

    _drawBrow(
      canvas,
      Offset(center.dx - eyeOffsetX, browY),
      browLen,
      angle,
      paint,
      mirror: false,
    );
    _drawBrow(
      canvas,
      Offset(center.dx + eyeOffsetX, browY),
      browLen,
      angle,
      paint,
      mirror: true,
    );
  }

  void _drawBrow(
    Canvas canvas,
    Offset c,
    double length,
    double angle,
    Paint paint, {
    required bool mirror,
  }) {
    // Each brow is drawn as a small `Path` so the two endpoints can be
    // angled independently — that's what produces "worried" vs "happy" brows.
    final dir = mirror ? -1 : 1;
    final start = Offset(
      c.dx - length / 2 * dir,
      c.dy + (angle * length / 2),
    );
    final end = Offset(
      c.dx + length / 2 * dir,
      c.dy - (angle * length / 2),
    );
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  // ---------------------------------------------------------------------------
  // Mouth
  // ---------------------------------------------------------------------------

  void _paintMouth(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.08
      ..color = Colors.black87;

    final mouthCenter = Offset(center.dx, center.dy + radius * 0.28);
    final mouthWidth = radius * 0.7;
    final mouthHeight = radius * 0.45;

    // Subtle animated bounce on tap.
    final pulse = 1 + 0.15 * (animation == 0
        ? 0
        : (1 - (2 * animation - 1) * (2 * animation - 1)));

    final rect = Rect.fromCenter(
      center: mouthCenter,
      width: mouthWidth,
      height: mouthHeight * pulse,
    );

    switch (mood) {
      case Mood.happy:
        // Big upward arc — a wide smile drawn from 0° to 180°.
        canvas.drawArc(rect, 0, 3.14159, false, paint);
      case Mood.good:
        // Gentler smile.
        final smaller = Rect.fromCenter(
          center: mouthCenter,
          width: mouthWidth * 0.85,
          height: mouthHeight * 0.6 * pulse,
        );
        canvas.drawArc(smaller, 0.2, 3.14159 - 0.4, false, paint);
      case Mood.neutral:
        // Flat line.
        final path = Path()
          ..moveTo(mouthCenter.dx - mouthWidth / 2, mouthCenter.dy)
          ..lineTo(mouthCenter.dx + mouthWidth / 2, mouthCenter.dy);
        canvas.drawPath(path, paint);
      case Mood.sad:
        // Downward arc (frown) — flipped rect, arc swept from 180° to 360°.
        final frownRect = Rect.fromCenter(
          center: mouthCenter.translate(0, mouthHeight * 0.4),
          width: mouthWidth,
          height: mouthHeight * pulse,
        );
        canvas.drawArc(frownRect, 3.14159, 3.14159, false, paint);
      case Mood.awful:
        // Wobbly frown rendered as a custom path (3 cubic-ish segments).
        final w = mouthWidth;
        final h = mouthHeight * 0.5 * pulse;
        final y = mouthCenter.dy + h * 0.3;
        final path = Path()
          ..moveTo(mouthCenter.dx - w / 2, y)
          ..quadraticBezierTo(
            mouthCenter.dx - w / 4,
            y - h,
            mouthCenter.dx,
            y,
          )
          ..quadraticBezierTo(
            mouthCenter.dx + w / 4,
            y - h,
            mouthCenter.dx + w / 2,
            y,
          );
        canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MoodFacePainter old) =>
      old.mood != mood || old.animation != animation;
}
