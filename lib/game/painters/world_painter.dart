// lib/game/painters/world_painter.dart
// Renders background (sky, clouds, sun, hills, barn, trees, fence),
// ground with animated grass, all obstacle types, and coins.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class WorldPainter {
  // ── Background ───────────────────────────────────────────────────────────────
  static void drawSky(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF1A6FA8), const Color(0xFF4FC3F7), const Color(0xFF81D4FA)],
        stops: const [0, 0.6, 1],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.80));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.80), paint);
  }

  static void drawSun(Canvas canvas, double animT) {
    final pulse = math.sin(animT * 1.8) * 4;
    final center = const Offset(700, 62);
    // Glow rings
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(
        center,
        44 + i * 10 + pulse,
        Paint()..color = const Color(0xFFFFEB3B).withOpacity(0.06 * i),
      );
    }
    canvas.drawCircle(center, 44, Paint()..color = const Color(0xFFFFF9C4));
    canvas.drawCircle(center, 30, Paint()..color = const Color(0xFFFFEB3B));
    canvas.drawCircle(center, 18, Paint()..color = const Color(0xFFFFF59D));
  }

  static void drawClouds(Canvas canvas, double scrollOffset) {
    final cloudData = [
      [80.0,  54.0, 1.0],
      [330.0, 78.0, 0.82],
      [580.0, 42.0, 1.12],
      [820.0, 68.0, 0.90],
    ];
    for (final c in cloudData) {
      final x = (c[0] - scrollOffset * 0.15) % 900 - 80;
      _drawCloud(canvas, x, c[1], c[2]);
    }
  }

  static void _drawCloud(Canvas canvas, double x, double y, double scale) {
    final p = Paint()..color = Colors.white.withOpacity(0.84);
    for (final c in [
      [0.0,   0.0, 24.0],
      [30.0, -10.0, 30.0],
      [62.0,  0.0, 21.0],
      [34.0,  8.0, 26.0],
    ]) {
      canvas.drawCircle(Offset(x + c[0] * scale, y + c[1] * scale), c[2] * scale, p);
    }
  }

  static void drawHills(Canvas canvas, Size size, double scrollOffset) {
    final paint = Paint()..color = const Color(0xFF81C784);
    final path  = Path()..moveTo(0, size.height * 0.52);
    for (double x = 0; x <= size.width; x += 12) {
      path.lineTo(x, size.height * 0.52 + math.sin((x + scrollOffset * 0.22) * 0.009) * 22);
    }
    path..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(path, paint);
  }

  static void drawBgDecoration(Canvas canvas, List<Map<String, dynamic>> bgElements) {
    for (final el in bgElements) {
      final layer = el['layer'] as int;
      final x     = el['x'] as double;
      final y     = el['y'] as double;
      final sc    = [0.36, 0.60, 0.85][layer];
      final op    = [0.42, 0.66, 0.90][layer];

      canvas.save();
      canvas.translate(x, y);
      final p = Paint()..colorFilter = ColorFilter.mode(Colors.white.withOpacity(op), BlendMode.modulate);
      canvas.saveLayer(null, p);

      switch (el['type'] as String) {
        case 'tree': _drawBgTree(canvas, sc); break;
        case 'barn': _drawBgBarn(canvas, sc); break;
        case 'bush': _drawBgBush(canvas, sc); break;
      }

      canvas.restore();
      canvas.restore();
    }
  }

  // ── Ground ───────────────────────────────────────────────────────────────────
  static void drawGround(Canvas canvas, Size size, double groundY, double scrollOffset) {
    // Grass strip
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, 18),
      Paint()..color = const Color(0xFF4A7C2F),
    );
    // Animated grass blades
    final blade = Paint()..color = const Color(0xFF66BB6A);
    for (double x = -(scrollOffset % 18); x < size.width; x += 18) {
      canvas.drawRect(Rect.fromLTWH(x,     groundY + 2, 3, 7),  blade);
      canvas.drawRect(Rect.fromLTWH(x + 7, groundY,     3, 9),  blade);
      canvas.drawRect(Rect.fromLTWH(x + 13,groundY + 3, 2, 6),  blade);
    }
    // Dirt
    final dirtShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFF6D4C41), const Color(0xFF4E342E)],
    ).createShader(Rect.fromLTWH(0, groundY + 18, size.width, size.height - groundY - 18));
    canvas.drawRect(
      Rect.fromLTWH(0, groundY + 18, size.width, size.height - groundY - 18),
      Paint()..shader = dirtShader,
    );
  }

  // ── Obstacles ────────────────────────────────────────────────────────────────
  static void drawHayBale(Canvas canvas, Offset center) {
    final cx = center.dx, cy = center.dy;
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 32), width: 56, height: 12),
      Paint()..color = Colors.black.withOpacity(0.18),
    );
    // Main bale
    canvas.drawCircle(Offset(cx, cy), 28, Paint()..color = const Color(0xFFD4A017));
    // Rope rings
    final rope = Paint()
      ..color = const Color(0xFFB8860B)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (final r in [8.0, 15.0, 22.0]) {
      canvas.drawCircle(Offset(cx, cy), r, rope);
    }
    // Straw lines
    final straw = Paint()
      ..color = const Color(0xFFC8990A)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (double i = -22; i <= 22; i += 5) {
      final half = math.sqrt(math.max(0, 729 - i * i));
      canvas.drawLine(Offset(cx - half, cy + i), Offset(cx + half, cy + i), straw);
    }
  }

  static void drawFence(Canvas canvas, Offset base, double height, double gapHeight) {
    final x = base.dx, groundY = base.dy;
    final top = groundY - height;

    // Posts
    final postPaint = Paint()..color = const Color(0xFF8B6914);
    canvas.drawRect(Rect.fromLTWH(x - 20, top, 12, height), postPaint);
    canvas.drawRect(Rect.fromLTWH(x +  8, top, 12, height), postPaint);

    // Post caps (triangles)
    for (final px in [x - 20, x + 8]) {
      final cap = Path()
        ..moveTo(px, top)
        ..lineTo(px + 6, top - 12)
        ..lineTo(px + 12, top)
        ..close();
      canvas.drawPath(cap, Paint()..color = const Color(0xFFA0522D));
    }

    // Rails (3 horizontal boards — gap at bottom for sliding)
    final railPaint = Paint()..color = const Color(0xFFA0522D);
    for (final ry in [top + 5.0, top + 24.0, top + 44.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 22, ry, 44, 9), const Radius.circular(2)),
        railPaint,
      );
    }

    // Slide hint
    final hintPaint = Paint()
      ..color = const Color(0xFFFFFF88).withOpacity(0.8);
    final tp = TextPainter(
      text: const TextSpan(
        text: '↓ SLIDE',
        style: TextStyle(color: Color(0xFFFFFF88), fontSize: 11, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(x - tp.width / 2, groundY - gapHeight / 2 - tp.height / 2));
  }

  static void drawPumpkin(Canvas canvas, Offset center) {
    final cx = center.dx, cy = center.dy;
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 22), width: 42, height: 10),
      Paint()..color = Colors.black.withOpacity(0.18),
    );
    // Three segments
    for (final dx in [-12.0, 0.0, 12.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + dx, cy), width: 24, height: 36),
        Paint()..color = dx == 0 ? const Color(0xFFE64A19) : const Color(0xFFBF360C),
      );
    }
    // Stem
    canvas.drawRect(
      Rect.fromLTWH(cx - 4, cy - 22, 8, 10),
      Paint()..color = const Color(0xFF2E7D32),
    );
    // Vine
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 6, cy - 20), width: 14, height: 10),
      math.pi, math.pi, false,
      Paint()..color = const Color(0xFF2E7D32)..strokeWidth = 2..style = PaintingStyle.stroke,
    );
    // Eyes + mouth (jack-o-lantern)
    final featurePaint = Paint()..color = const Color(0xFF111111);
    // Eye triangles
    void triangle(double ex, double ey) {
      final tp = Path()
        ..moveTo(cx + ex, cy + ey - 8)
        ..lineTo(cx + ex - 6, cy + ey + 2)
        ..lineTo(cx + ex + 6, cy + ey + 2)
        ..close();
      canvas.drawPath(tp, featurePaint);
    }
    triangle(-10, -2);
    triangle( 10, -2);
    // Zigzag mouth
    final mouth = Path()..moveTo(cx - 11, cy + 12);
    for (int i = 0; i < 4; i++) {
      mouth.lineTo(cx - 5 + i * 6.0, cy + (i % 2 == 0 ? 8 : 14));
    }
    mouth.lineTo(cx + 11, cy + 12);
    canvas.drawPath(mouth, Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
  }

  // ── Coin ─────────────────────────────────────────────────────────────────────
  static void drawCoin(Canvas canvas, Offset center, int frame) {
    final bob    = math.sin(frame * 0.08) * 4;
    final cx = center.dx, cy = center.dy + bob;

    canvas.save();
    canvas.translate(cx, cy);

    // Outer glow
    canvas.drawCircle(Offset.zero, 16,
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.28)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Coin face
    canvas.drawCircle(Offset.zero, 13, Paint()..color = const Color(0xFFFFD700));
    canvas.drawCircle(Offset.zero, 9,  Paint()..color = const Color(0xFFFFB300));

    // Dollar sign
    final tp = TextPainter(
      text: const TextSpan(
        text: '\$',
        style: TextStyle(color: Color(0xFFE65100), fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

    canvas.restore();
  }

  // ── BG helpers ───────────────────────────────────────────────────────────────
  static void _drawBgTree(Canvas canvas, double s) {
    canvas.drawRect(Rect.fromLTWH(-5 * s, -5 * s, 10 * s, 36 * s),
        Paint()..color = const Color(0xFF5D4037));
    final crown = Paint()..color = const Color(0xFF388E3C);
    final p1 = Path()
      ..moveTo(0, -46 * s)
      ..lineTo(28 * s, 0)
      ..lineTo(-28 * s, 0)
      ..close();
    canvas.drawPath(p1, crown);
    final crown2 = Paint()..color = const Color(0xFF43A047);
    final p2 = Path()
      ..moveTo(0, -66 * s)
      ..lineTo(20 * s, -22 * s)
      ..lineTo(-20 * s, -22 * s)
      ..close();
    canvas.drawPath(p2, crown2);
  }

  static void _drawBgBarn(Canvas canvas, double s) {
    canvas.drawRect(Rect.fromLTWH(-36 * s, -32 * s, 72 * s, 44 * s),
        Paint()..color = const Color(0xFFB71C1C));
    final roof = Path()
      ..moveTo(-40 * s, -32 * s)
      ..lineTo(0, -66 * s)
      ..lineTo(40 * s, -32 * s)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF7F0000));
    canvas.drawRect(Rect.fromLTWH(-8 * s, -18 * s, 16 * s, 26 * s),
        Paint()..color = Colors.white.withOpacity(0.9));
  }

  static void _drawBgBush(Canvas canvas, double s) {
    final p = Paint()..color = const Color(0xFF558B2F);
    canvas.drawCircle(Offset(0,      0), 18 * s, p);
    canvas.drawCircle(Offset(-14*s,  4*s), 13 * s, p);
    canvas.drawCircle(Offset( 14*s,  4*s), 13 * s, p);
    canvas.drawCircle(Offset(-4*s,  -4*s), 10 * s, Paint()..color = const Color(0xFF7CB342));
  }
}
