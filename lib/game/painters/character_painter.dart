// lib/game/character_painter.dart
// Skeletal animation system for Chicken and Farmer.
// Each character is assembled from individual body-part images,
// each part transformed independently to produce natural running physics.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE CACHE
// ─────────────────────────────────────────────────────────────────────────────
class PartImages {
  // Chicken
  ui.Image? chBody, chHead, chWingL, chWingR, chLegL, chLegR;
  // Farmer
  ui.Image? fmBody, fmHead, fmArmL, fmArmR, fmLegL, fmLegR;

  bool get chickenReady =>
      chBody != null && chHead != null && chWingL != null &&
      chWingR != null && chLegL != null && chLegR != null;

  bool get farmerReady =>
      fmBody != null && fmHead != null && fmArmL != null &&
      fmArmR != null && fmLegL != null && fmLegR != null;

  static Future<ui.Image> _load(String path) async {
    final data  = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  Future<void> loadAll() async {
    final futures = await Future.wait([
      _load('assets/images/parts/ch_body.png'),
      _load('assets/images/parts/ch_head.png'),
      _load('assets/images/parts/ch_wing_l.png'),
      _load('assets/images/parts/ch_wing_r.png'),
      _load('assets/images/parts/ch_leg_l.png'),
      _load('assets/images/parts/ch_leg_r.png'),
      _load('assets/images/parts/fm_body.png'),
      _load('assets/images/parts/fm_head.png'),
      _load('assets/images/parts/fm_arm_l.png'),
      _load('assets/images/parts/fm_arm_r.png'),
      _load('assets/images/parts/fm_leg_l.png'),
      _load('assets/images/parts/fm_leg_r.png'),
    ]);
    chBody  = futures[0];  chHead  = futures[1];
    chWingL = futures[2];  chWingR = futures[3];
    chLegL  = futures[4];  chLegR  = futures[5];
    fmBody  = futures[6];  fmHead  = futures[7];
    fmArmL  = futures[8];  fmArmR  = futures[9];
    fmLegL  = futures[10]; fmLegR  = futures[11];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOW-LEVEL DRAW HELPER
// ─────────────────────────────────────────────────────────────────────────────
void _drawPart(
  Canvas canvas,
  ui.Image img, {
  required Offset pivot,   // pivot point in local coords (rotation axis)
  required double angle,   // rotation in radians
  required double w,       // display width
  required double h,       // display height
  double opacity = 1.0,
}) {
  if (opacity <= 0) return;
  canvas.save();
  canvas.translate(pivot.dx, pivot.dy);
  canvas.rotate(angle);
  final paint = Paint()
    ..filterQuality = FilterQuality.high
    ..color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0));
  final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
  final dst = Rect.fromCenter(center: Offset.zero, width: w, height: h);
  canvas.drawImageRect(img, src, dst, paint);
  canvas.restore();
}

// ─────────────────────────────────────────────────────────────────────────────
// CHICKEN PAINTER
// Full running cycle: legs stride, wings bob, head nods, body bobs
// ─────────────────────────────────────────────────────────────────────────────
class ChickenPainter {
  static void draw(
    Canvas canvas,
    PartImages parts,
    Offset centre,          // screen centre of character base
    double scale,           // overall scale (road-width based)
    double animT,           // animation time in seconds
    bool   isJumping,
    bool   isSliding,
    bool   isInvincible,
    int    animFrame,
  ) {
    if (isInvincible && (animFrame ~/ 4) % 2 == 1) return;
    if (!parts.chickenReady) {
      _drawFallback(canvas, centre, scale);
      return;
    }

    // ── Animation cycle values ───────────────────────────────────────────────
    final cycle = animT * 11.0;
    final runC  = math.sin(cycle);          // -1..1  (main run cycle)
    final runC2 = math.sin(cycle * 2);      // -1..1  (double-speed bounce)

    // ── Unit sizes based on scale ───────────────────────────────────────────
    final bw = scale * 78;   // body width
    final bh = scale * 72;   // body height
    final hw = scale * 55;   // head width
    final hh = scale * 55;   // head height
    final ww = scale * 44;   // wing width
    final wh = scale * 36;   // wing height
    final lw = scale * 34;   // leg width
    final lh = scale * 52;   // leg height

    canvas.save();
    canvas.translate(centre.dx, centre.dy);

    if (isSliding) {
      // ── SLIDE pose: flatten body forward ────────────────────────────────
      canvas.rotate(0.25);
      canvas.scale(1.4, 0.55);
      _drawPart(canvas, parts.chBody!, pivot: Offset(0, -bh*0.1), angle: 0, w: bw*1.2, h: bh);
      _drawPart(canvas, parts.chHead!, pivot: Offset(bw*0.55, -bh*0.1), angle: 0.3, w: hw*0.9, h: hh*0.9);
      _drawPart(canvas, parts.chLegL!, pivot: Offset(-lw*0.1, bh*0.35), angle: -0.5, w: lw, h: lh*0.7);
      _drawPart(canvas, parts.chLegR!, pivot: Offset( lw*0.2, bh*0.35), angle: -0.3, w: lw, h: lh*0.7);

    } else if (isJumping) {
      // ── JUMP pose: tuck legs, spread wings ──────────────────────────────
      final flapAngle = math.sin(animT * 14) * 0.45 + 0.3;
      final bodyLean  = -0.12;

      // Wings spread and flap
      _drawPart(canvas, parts.chWingL!, pivot: Offset(-bw*0.40, -bh*0.08),
          angle: -flapAngle, w: ww*1.3, h: wh*1.2);
      _drawPart(canvas, parts.chWingR!, pivot: Offset( bw*0.32, -bh*0.08),
          angle:  flapAngle, w: ww*1.3, h: wh*1.2);

      // Body
      _drawPart(canvas, parts.chBody!, pivot: Offset(0, -bh*0.1), angle: bodyLean, w: bw, h: bh*1.1);

      // Head tilts up excitedly
      _drawPart(canvas, parts.chHead!,
          pivot: Offset(bw*0.35, -bh*0.62), angle: bodyLean-0.15, w: hw, h: hh);

      // Legs tucked up
      _drawPart(canvas, parts.chLegL!,
          pivot: Offset(-lw*0.05, bh*0.28), angle: -0.85, w: lw, h: lh*0.8);
      _drawPart(canvas, parts.chLegR!,
          pivot: Offset( lw*0.20, bh*0.28), angle: -0.65, w: lw, h: lh*0.8);

    } else {
      // ── RUNNING cycle ────────────────────────────────────────────────────
      // Body: forward lean + vertical bob
      final bodyLean = -0.09 + runC * 0.05;
      final bodyBob  = runC2.abs() * scale * 2.5;

      canvas.translate(runC * scale * 0.8, bodyBob);

      // Wing (right) — small flap counter to leg
      _drawPart(canvas, parts.chWingR!,
          pivot: Offset(-bw*0.28, -bh*0.02),
          angle: -runC * 0.22,
          w: ww, h: wh, opacity: 0.9);

      // Body
      _drawPart(canvas, parts.chBody!, pivot: Offset(0, -bh*0.10), angle: bodyLean, w: bw, h: bh);

      // Wing (left) — slight press against body during run
      _drawPart(canvas, parts.chWingL!,
          pivot: Offset(bw*0.20, -bh*0.02),
          angle: runC * 0.18,
          w: ww, h: wh, opacity: 0.85);

      // Head nods with each stride
      final headNod = math.sin(cycle * 2) * 0.08;  // quicker nod
      _drawPart(canvas, parts.chHead!,
          pivot: Offset(bw*0.32, -bh*0.60 + bodyBob * 0.3),
          angle: bodyLean + headNod,
          w: hw, h: hh);

      // Legs — alternating stride
      // Leg R: forward on even stride
      final legRAngle = math.sin(cycle) * 0.72;
      final legRBob   = math.max(0.0, math.sin(cycle)) * scale * 3.5;
      _drawPart(canvas, parts.chLegR!,
          pivot: Offset(lw*0.12, bh*0.36 - legRBob),
          angle: legRAngle,
          w: lw, h: lh);

      // Leg L: forward on odd stride (opposite phase)
      final legLAngle = math.sin(cycle + math.pi) * 0.72;
      final legLBob   = math.max(0.0, math.sin(cycle + math.pi)) * scale * 3.5;
      _drawPart(canvas, parts.chLegL!,
          pivot: Offset(-lw*0.08, bh*0.36 - legLBob),
          angle: legLAngle,
          w: lw, h: lh);
    }

    canvas.restore();
  }

  static void _drawFallback(Canvas canvas, Offset centre, double scale) {
    canvas.drawOval(
      Rect.fromCenter(center: centre, width: scale*70, height: scale*80),
      Paint()..color = Colors.white,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FARMER PAINTER
// Full running cycle: legs stride (human biomechanics), arms swing opposite,
// body leans forward, head bobs, leans more as anger increases
// ─────────────────────────────────────────────────────────────────────────────
class FarmerPainter {
  static void draw(
    Canvas canvas,
    PartImages parts,
    Offset base,            // screen bottom-centre of farmer
    double scale,           // road-width based scale
    double animT,
    double angerLevel,      // 0..1
  ) {
    if (!parts.farmerReady) {
      _drawFallback(canvas, base, scale);
      return;
    }

    final runSpeed = 9.5 + angerLevel * 5.0;
    final cycle    = animT * runSpeed;
    final runC     = math.sin(cycle);
    final runC2    = math.sin(cycle * 2);

    // ── Unit sizes ─────────────────────────────────────────────────────────
    final bw = scale * 75;   // body width
    final bh = scale * 70;   // body height
    final hw = scale * 58;   // head+hat width
    final hh = scale * 65;   // head+hat height
    final aw = scale * 48;   // arm width
    final ah = scale * 62;   // arm height
    final lw = scale * 40;   // leg width
    final lh = scale * 62;   // leg height

    // ── Body centre (above base) ────────────────────────────────────────────
    final charH   = lh + bh + hh * 0.6;
    final centreY = base.dy - charH * 0.52;
    final bobY    = runC2.abs() * scale * 1.8;    // body bounces with stride
    final swayX   = runC * scale * 1.5;           // hip sway
    final lean    = 0.10 + angerLevel * 0.14;     // forward lean (anger = charges harder)

    canvas.save();
    canvas.translate(base.dx + swayX, centreY - bobY);
    canvas.rotate(lean);

    // ── BACK leg (drawn behind body) ────────────────────────────────────────
    final backLegAngle  = math.sin(cycle + math.pi) * 0.58;
    final backLegLift   = math.max(0.0, math.sin(cycle + math.pi)) * scale * 4.0;
    _drawPart(canvas, parts.fmLegL!,
        pivot: Offset(-lw*0.15, bh*0.40 - backLegLift),
        angle: backLegAngle,
        w: lw, h: lh, opacity: 0.88);

    // ── Body ────────────────────────────────────────────────────────────────
    _drawPart(canvas, parts.fmBody!, pivot: Offset(0, 0), angle: 0, w: bw, h: bh);

    // ── FRONT leg ────────────────────────────────────────────────────────────
    final frontLegAngle = math.sin(cycle) * 0.58;
    final frontLegLift  = math.max(0.0, math.sin(cycle)) * scale * 4.0;
    _drawPart(canvas, parts.fmLegR!,
        pivot: Offset(lw*0.20, bh*0.40 - frontLegLift),
        angle: frontLegAngle,
        w: lw, h: lh);

    // ── BACK arm (opposite phase to front leg — natural gait) ───────────────
    final backArmAngle = math.sin(cycle) * 0.50;           // same phase as front leg
    _drawPart(canvas, parts.fmArmL!,
        pivot: Offset(-bw*0.40, -bh*0.12),
        angle: -backArmAngle,
        w: aw, h: ah, opacity: 0.85);

    // ── FRONT arm + pitchfork (opposite phase = lunges forward) ────────────
    final frontArmAngle = math.sin(cycle + math.pi) * 0.55;  // opposite to front leg
    _drawPart(canvas, parts.fmArmR!,
        pivot: Offset(bw*0.38, -bh*0.12),
        angle: -frontArmAngle,
        w: aw * 1.1, h: ah * 1.1);   // slightly bigger (holds pitchfork)

    // ── Head — nods with stride, tilts with lean ─────────────────────────
    final headNod = math.sin(cycle * 2) * 0.055;
    _drawPart(canvas, parts.fmHead!,
        pivot: Offset(0, -bh*0.56 - bobY*0.3),
        angle: headNod,
        w: hw, h: hh);

    canvas.restore();

    // ── Anger emoji above head ───────────────────────────────────────────────
    if (angerLevel > 0.65) {
      final pulse = math.sin(animT * 5) * 3;
      final emoji = angerLevel > 0.88 ? '😡' : '😤';
      final tp = TextPainter(
        text: TextSpan(text: emoji, style: const TextStyle(fontSize: 20)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(
        base.dx - tp.width / 2,
        base.dy - charH * 1.08 + pulse,
      ));
    }
  }

  static void _drawFallback(Canvas canvas, Offset base, double scale) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(base.dx, base.dy - scale*40),
          width: scale*60, height: scale*80),
      Paint()..color = const Color(0xFF1976D2),
    );
  }
}
