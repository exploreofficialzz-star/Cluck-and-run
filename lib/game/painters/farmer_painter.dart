// lib/game/painters/farmer_painter.dart
// Draws the chasing farmer with a full 8-frame run cycle.
// His expression changes (calm → annoyed → enraged) as he closes in.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class FarmerPainter {
  /// [angerLevel] 0.0 = calm, 1.0 = full rage (farmer about to catch chicken)
  static void draw(
    Canvas canvas,
    Offset center,
    double scale, {
    required int frame,
    double angerLevel = 0.0,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    _drawFarmer(canvas, frame, angerLevel);
    canvas.restore();
  }

  static void _drawFarmer(Canvas canvas, int frame, double anger) {
    final t     = (frame % 8) / 8.0;
    final cycle = t * 2 * math.pi;

    final bodyBob   = math.sin(cycle) * 3.0;
    final bodyTilt  = math.sin(cycle) * 0.05 + 0.04; // leans forward
    final armSwing  = math.sin(cycle) * 0.55;

    canvas.save();
    canvas.translate(0, bodyBob);
    canvas.rotate(bodyTilt);

    _drawShadow(canvas, bodyBob, anger);
    _drawLegs(canvas, cycle);
    _drawOveralls(canvas);
    _drawShirt(canvas);
    _drawArms(canvas, armSwing);
    _drawPitchfork(canvas, armSwing, anger);
    _drawHead(canvas, anger);
    _drawHat(canvas);
    _drawSweatDrops(canvas, frame, anger);

    canvas.restore();
  }

  // ── Paints ──────────────────────────────────────────────────────────────────
  static final _skinPaint    = Paint()..color = const Color(0xFFFFCCAA);
  static final _overallPaint = Paint()..color = const Color(0xFF1976D2);
  static final _shirtPaint   = Paint()..color = const Color(0xFFEF5350);
  static final _hatPaint     = Paint()..color = const Color(0xFFF9A825);
  static final _hatBandPaint = Paint()..color = const Color(0xFFB71C1C);
  static final _woodPaint    = Paint()..color = const Color(0xFF6D4C41);
  static final _metalPaint   = Paint()
    ..color = const Color(0xFF90A4AE)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  static final _darkPaint    = Paint()..color = const Color(0xFF212121);
  static final _whitePaint   = Paint()..color = Colors.white;
  static final _legPaint     = Paint()
    ..color = const Color(0xFF0D47A1)
    ..strokeWidth = 9
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final _shoePaint    = Paint()..color = const Color(0xFF3E2723);

  // ─────────────────────────────────────────────────────────────────────────────
  static void _drawShadow(Canvas canvas, double bob, double anger) {
    final op = 0.12 + anger * 0.06;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 54 + bob * 0.3), width: 44, height: 10),
      Paint()..color = Colors.black.withOpacity(op),
    );
  }

  static void _drawLegs(Canvas canvas, double cycle) {
    final back  = math.sin(cycle + math.pi) * 0.65;
    final front = math.sin(cycle) * 0.65;
    _drawOneLeg(canvas, -5, back);
    _drawOneLeg(canvas,  5, front);
  }

  static void _drawOneLeg(Canvas canvas, double xOff, double angle) {
    canvas.save();
    canvas.translate(xOff, 28);
    canvas.rotate(angle);

    // Thigh
    canvas.drawLine(Offset.zero, const Offset(0, 20), _legPaint);
    canvas.save();
    canvas.translate(0, 20);
    canvas.rotate(-angle * 0.9);
    canvas.drawLine(Offset.zero, const Offset(0, 18), _legPaint);

    // Shoe
    canvas.save();
    canvas.translate(0, 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, -4, 18, 10),
        const Radius.circular(4),
      ),
      _shoePaint,
    );
    canvas.restore();

    canvas.restore();
    canvas.restore();
  }

  static void _drawOveralls(Canvas canvas) {
    // Bib + straps
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(-16, -36, 32, 38), const Radius.circular(4)));
    canvas.drawPath(path, _overallPaint);
    // Straps
    canvas.drawRect(const Rect.fromLTWH(-12, -56, 7, 22), _overallPaint);
    canvas.drawRect(const Rect.fromLTWH(5,   -56, 7, 22), _overallPaint);
    // Pocket
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -22, 12, 10), const Radius.circular(2)),
      Paint()..color = const Color(0xFF1565C0),
    );
  }

  static void _drawShirt(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-18, -60, 36, 28), const Radius.circular(5)),
      _shirtPaint,
    );
  }

  static void _drawArms(Canvas canvas, double swing) {
    final armPaint = Paint()
      ..color = _shirtPaint.color
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Left arm (holds pitchfork) — opposite phase
    canvas.drawLine(
      const Offset(16, -50),
      Offset(28 + math.sin(-swing) * 10, -28 + math.cos(-swing) * 6),
      armPaint,
    );
    // Right arm (swinging freely)
    canvas.drawLine(
      const Offset(-16, -50),
      Offset(-26 + math.sin(swing) * 10, -30 + math.cos(swing) * 6),
      armPaint,
    );
    // Hands
    for (final p in [
      Offset(28 + math.sin(-swing) * 10, -28 + math.cos(-swing) * 6),
      Offset(-26 + math.sin(swing) * 10, -30 + math.cos(swing) * 6),
    ]) {
      canvas.drawCircle(p, 5.5, _skinPaint);
    }
  }

  static void _drawPitchfork(Canvas canvas, double swing, double anger) {
    final handX = 28 + math.sin(-swing) * 10;
    final handY = -28 + math.cos(-swing) * 6;

    // Pitchfork handle shakes when angry
    final shake = anger > 0.6 ? math.sin(swing * 4) * 3 : 0.0;

    canvas.save();
    canvas.translate(handX + shake, handY);
    canvas.rotate(-0.25 - anger * 0.2);

    // Handle
    canvas.drawLine(const Offset(0, 0), const Offset(0, -52), _woodPaint..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    // Tines
    for (final dx in [-6.0, 0.0, 6.0]) {
      canvas.drawLine(Offset(dx, -52), Offset(dx, -68), _metalPaint);
    }

    canvas.restore();
  }

  static void _drawHead(Canvas canvas, double anger) {
    // Face changes colour with anger: cream → pink → red
    final faceColor = Color.lerp(
      const Color(0xFFFFCCAA),
      const Color(0xFFFF8A80),
      anger,
    )!;
    canvas.drawCircle(const Offset(0, -70), 16, Paint()..color = faceColor);

    // Eyes
    final eyeColor = anger > 0.5 ? const Color(0xFFD50000) : const Color(0xFF212121);
    canvas.drawCircle(const Offset(-6, -72), 3.5, Paint()..color = eyeColor);
    canvas.drawCircle(const Offset( 6, -72), 3.5, Paint()..color = eyeColor);
    // Pupils
    canvas.drawCircle(const Offset(-6, -72), 1.5, _whitePaint);
    canvas.drawCircle(const Offset( 6, -72), 1.5, _whitePaint);

    // Angry brows (steepen with anger)
    final browPaint = Paint()
      ..color = const Color(0xFF5D3A1A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final browDip = anger * 6;
    canvas.drawLine(Offset(-12, -80 - browDip), const Offset(-2, -76), browPaint);
    canvas.drawLine(Offset( 12, -80 - browDip), const Offset( 2, -76), browPaint);

    // Mouth — frown deepens with anger
    final mouthPaint = Paint()
      ..color = const Color(0xFF5D3A1A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final mouthSweep = anger > 0.4 ? 0.3 + anger * 0.4 : -0.2;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(0, -62 + anger * 2), width: 14, height: 8 + anger * 4),
      0.2,
      mouthSweep > 0 ? math.pi - 0.4 : -(math.pi - 0.4),
      false,
      mouthPaint,
    );
  }

  static void _drawHat(Canvas canvas) {
    // Brim
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -84), width: 38, height: 8),
      _hatPaint,
    );
    // Crown
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-14, -104, 28, 22),
        const Radius.circular(3),
      ),
      _hatPaint,
    );
    // Band
    canvas.drawRect(const Rect.fromLTWH(-14, -86, 28, 5), _hatBandPaint);
  }

  static void _drawSweatDrops(Canvas canvas, int frame, double anger) {
    if (anger < 0.4) return;
    // Two sweat drops that bounce
    final bounce = math.sin(frame * 0.3) * 3;
    final dropPaint = Paint()..color = const Color(0xFF64B5F6).withOpacity(anger);
    for (final off in [const Offset(18, -76), const Offset(-20, -80)]) {
      canvas.save();
      canvas.translate(off.dx, off.dy + bounce);
      final path = Path()
        ..moveTo(0, -6)
        ..cubicTo(-4, -3, -4, 3, 0, 5)
        ..cubicTo(4, 3, 4, -3, 0, -6);
      canvas.drawPath(path, dropPaint);
      canvas.restore();
    }
  }
}
