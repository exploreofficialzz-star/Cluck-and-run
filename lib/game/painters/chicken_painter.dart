// lib/game/painters/chicken_painter.dart
// Draws the player chicken with a full 8-frame run cycle, jump pose,
// slide pose, and invincibility flash — all using Canvas primitives.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class ChickenPainter {
  /// [frame]    – animation tick (incremented each game tick)
  /// [isJumping]– in the air
  /// [isSliding]– ducking under fence
  /// [invincible] – flashing after revive
  static void draw(
    Canvas canvas,
    Offset center,
    double scale, {
    required int frame,
    bool isJumping  = false,
    bool isSliding  = false,
    bool invincible = false,
  }) {
    // Invincibility flash — skip every other 4 frames
    if (invincible && (frame ~/ 4) % 2 == 1) return;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    if (isSliding) {
      _drawSlide(canvas, frame);
    } else if (isJumping) {
      _drawJump(canvas, frame);
    } else {
      _drawRun(canvas, frame);
    }

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // RUN CYCLE  (8 natural frames)
  // ─────────────────────────────────────────────────────────────────────────────
  static void _drawRun(Canvas canvas, int frame) {
    final t = (frame % 8) / 8.0; // 0..1 over one full stride
    final cycle = t * 2 * math.pi;

    // Body bob — slight vertical oscillation
    final bodyBob   = math.sin(cycle) * 3.5;
    // Body lean — leans slightly forward mid-stride
    final bodyTilt  = math.sin(cycle) * 0.06;
    // Wing flap — opposite phase to legs
    final wingAngle = math.sin(cycle + math.pi) * 0.3 + 0.1;

    canvas.save();
    canvas.translate(0, bodyBob);
    canvas.rotate(bodyTilt);

    _drawShadow(canvas, bodyBob);
    _drawTailFeathers(canvas, cycle);
    _drawLegs(canvas, cycle, false);
    _drawBody(canvas);
    _drawWing(canvas, wingAngle);
    _drawNeck(canvas);
    _drawHead(canvas, bodyTilt * -1);
    _drawComb(canvas);
    _drawBeak(canvas);
    _drawEye(canvas);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // JUMP POSE
  // ─────────────────────────────────────────────────────────────────────────────
  static void _drawJump(Canvas canvas, int frame) {
    // Legs tucked up, wings spread wide
    final wingSpread = 0.55 + math.sin(frame * 0.18) * 0.1;

    canvas.save();
    canvas.rotate(-0.12); // slight backward lean

    _drawTailFeathers(canvas, 0);
    _drawLegsJump(canvas);
    _drawBody(canvas);
    _drawWing(canvas, wingSpread);
    _drawWingLeft(canvas, wingSpread); // both wings out
    _drawNeck(canvas);
    _drawHead(canvas, 0.1);
    _drawComb(canvas);
    _drawBeak(canvas);
    _drawEye(canvas);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SLIDE POSE
  // ─────────────────────────────────────────────────────────────────────────────
  static void _drawSlide(Canvas canvas, int frame) {
    canvas.save();
    canvas.rotate(0.18);            // tilted forward, low body
    canvas.translate(12, 14);      // shift down

    _drawShadow(canvas, 0);
    _drawTailFeathers(canvas, 0);
    _drawLegsSlide(canvas);
    _drawBody(canvas);
    _drawWing(canvas, -0.2);
    _drawNeck(canvas);
    _drawHead(canvas, -0.15);
    _drawComb(canvas);
    _drawBeak(canvas);
    _drawEye(canvas);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BODY PARTS
  // ─────────────────────────────────────────────────────────────────────────────
  static final _bodyFill   = Paint()..color = const Color(0xFFFFF8E7);
  static final _bodyShade  = Paint()..color = const Color(0xFFFFECB3);
  static final _orangeFill = Paint()..color = const Color(0xFFFF8F00);
  static final _redFill    = Paint()..color = const Color(0xFFE53935);
  static final _darkFill   = Paint()..color = const Color(0xFF1A1A1A);
  static final _whiteFill  = Paint()..color = Colors.white;
  static final _legPaint   = Paint()
    ..color = const Color(0xFFFF8F00)
    ..strokeWidth = 5.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final _toePaint   = Paint()
    ..color = const Color(0xFFFF8F00)
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  static void _drawShadow(Canvas canvas, double bob) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18 - bob.abs() * 0.01);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(4, 56 + bob * 0.4), width: 52, height: 12),
      shadowPaint,
    );
  }

  static void _drawBody(Canvas canvas) {
    // Main body ellipse
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 14), width: 62, height: 52), _bodyFill);
    // Belly highlight
    canvas.drawOval(Rect.fromCenter(center: const Offset(4, 18), width: 38, height: 28), _bodyShade);
  }

  static void _drawTailFeathers(Canvas canvas, double cycle) {
    final tailSwing = math.sin(cycle) * 0.15;
    for (int i = 0; i < 3; i++) {
      final angle = -0.45 + i * 0.25 + tailSwing;
      final p = Paint()..color = const Color(0xFFFF8F00).withOpacity(0.85 + i * 0.05);
      canvas.save();
      canvas.translate(-28, 8);
      canvas.rotate(angle);
      canvas.drawOval(Rect.fromCenter(center: const Offset(0, -18), width: 11, height: 26), p);
      canvas.restore();
    }
  }

  static void _drawWing(Canvas canvas, double angle) {
    canvas.save();
    canvas.translate(-6, 6);
    canvas.rotate(-angle);
    final wingPaint = Paint()..color = const Color(0xFFFFE082);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-8, 10), width: 34, height: 20), wingPaint);
    final featherPaint = Paint()..color = const Color(0xFFFFCA28);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-6, 14), width: 22, height: 12), featherPaint);
    canvas.restore();
  }

  static void _drawWingLeft(Canvas canvas, double angle) {
    canvas.save();
    canvas.translate(8, 4);
    canvas.rotate(angle);
    final wingPaint = Paint()..color = const Color(0xFFFFE082);
    canvas.drawOval(Rect.fromCenter(center: const Offset(10, 10), width: 34, height: 20), wingPaint);
    canvas.restore();
  }

  static void _drawNeck(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(22, -10), width: 22, height: 26),
      _bodyFill,
    );
  }

  static void _drawHead(Canvas canvas, double tilt) {
    canvas.save();
    canvas.translate(34, -40);
    canvas.rotate(tilt);
    canvas.drawCircle(Offset.zero, 22, _bodyFill);
    canvas.drawCircle(const Offset(2, -1), 18, _bodyShade);
    canvas.restore();
  }

  static void _drawComb(Canvas canvas) {
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(24 + i * 8.0, -60 + (i == 1 ? -4.0 : 0)), 7 - i * 0.5, _redFill);
    }
  }

  static void _drawBeak(Canvas canvas) {
    final beakPath = Path()
      ..moveTo(53, -40)
      ..lineTo(72, -34)
      ..lineTo(53, -28)
      ..close();
    canvas.drawPath(beakPath, _orangeFill);
    canvas.drawLine(const Offset(53, -34), const Offset(69, -34),
        Paint()..color = const Color(0xFFE65100)..strokeWidth = 1.5);
    // Wattle
    canvas.drawOval(Rect.fromCenter(center: const Offset(52, -26), width: 9, height: 13),
        Paint()..color = const Color(0xFFEF5350));
  }

  static void _drawEye(Canvas canvas) {
    canvas.drawCircle(const Offset(46, -44), 7, _whiteFill);
    canvas.drawCircle(const Offset(47, -44), 5, _darkFill);
    canvas.drawCircle(const Offset(49, -46), 2, _whiteFill); // catchlight
    // Eyebrow — determined look
    final browPaint = Paint()
      ..color = const Color(0xFF5D3A1A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(const Rect.fromLTWH(36, -56, 20, 10), 0.2, -1.5, false, browPaint);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // LEGS
  // ─────────────────────────────────────────────────────────────────────────────
  static void _drawLegs(Canvas canvas, double cycle, bool slide) {
    // Back leg (right side of screen = slightly behind)
    final backAngle  = math.sin(cycle + math.pi) * 0.7;
    // Front leg
    final frontAngle = math.sin(cycle) * 0.7;

    _drawOneLeg(canvas, -6,  backAngle,  false);
    _drawOneLeg(canvas,  10, frontAngle, true);
  }

  static void _drawOneLeg(Canvas canvas, double xOff, double angle, bool isFront) {
    canvas.save();
    canvas.translate(xOff, 38);
    canvas.rotate(angle);

    // Thigh
    canvas.drawLine(Offset.zero, const Offset(0, 22), _legPaint);
    // Shin — bends at knee
    canvas.save();
    canvas.translate(0, 22);
    canvas.rotate(-angle * 0.8);
    canvas.drawLine(Offset.zero, const Offset(0, 20), _legPaint);

    // Foot / toes
    canvas.save();
    canvas.translate(0, 20);
    // Three toes
    for (final d in [-0.6, 0.0, 0.6]) {
      canvas.drawLine(
        Offset.zero,
        Offset(math.sin(d) * 14, math.cos(d) * 10),
        _toePaint,
      );
    }
    // Back toe
    canvas.drawLine(Offset.zero, const Offset(-10, 4), _toePaint);
    canvas.restore();

    canvas.restore();
    canvas.restore();
  }

  static void _drawLegsJump(Canvas canvas) {
    // Legs tucked up behind body
    for (final xOff in [-8.0, 10.0]) {
      canvas.save();
      canvas.translate(xOff, 34);
      canvas.rotate(0.8);
      canvas.drawLine(Offset.zero, const Offset(0, 18), _legPaint);
      canvas.translate(0, 18);
      canvas.rotate(-1.2);
      canvas.drawLine(Offset.zero, const Offset(0, 14), _legPaint);
      canvas.restore();
    }
  }

  static void _drawLegsSlide(Canvas canvas) {
    // Legs stretched forward (running low)
    for (int i = 0; i < 2; i++) {
      canvas.save();
      canvas.translate(-4 + i * 16.0, 24);
      canvas.rotate(i == 0 ? 0.5 : 0.2);
      canvas.drawLine(Offset.zero, const Offset(0, 20), _legPaint);
      canvas.translate(0, 20);
      canvas.rotate(-0.3);
      canvas.drawLine(Offset.zero, const Offset(0, 16), _legPaint);
      canvas.restore();
    }
  }
}
