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
// lib/game/game_widget.dart — skeletal part-based character animation
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_engine.dart';
import 'game_state.dart';
import '../utils/constants.dart';

class GameWidget extends StatefulWidget {
  final int savedHighScore;
  final VoidCallback onDied, onCoinCollected, onBonusBird, onJump, onCluck;
  const GameWidget({super.key, required this.savedHighScore,
    required this.onDied, required this.onCoinCollected,
    required this.onBonusBird, required this.onJump, required this.onCluck});
  @override State<GameWidget> createState() => GameWidgetState();
}

class GameWidgetState extends State<GameWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  late GameState  _state;
  late GameEngine _engine;
  double _lastTime = 0;
  Offset? _dragStart;

  // Part images
  final PartImages _parts = PartImages();
  ui.Image? _coinImg;

  @override
  void initState() {
    super.initState();
    _state  = GameState()..highScore = widget.savedHighScore;
    _engine = GameEngine(state: _state, onDied: widget.onDied,
      onCoinCollected: widget.onCoinCollected, onBonusBird: widget.onBonusBird,
      onJump: widget.onJump, onCluck: widget.onCluck);
    _loadAssets();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)..forward();
  }

  Future<void> _loadAssets() async {
    await _parts.loadAll();
    final d = await rootBundle.load('assets/images/coin.png');
    final c = await ui.instantiateImageCodec(d.buffer.asUint8List());
    _coinImg = (await c.getNextFrame()).image;
    if (mounted) setState(() {});
  }

  void _tick() {
    final now = _ticker.lastElapsedDuration?.inMicroseconds.toDouble() ?? 0;
    final dt  = math.min((now - _lastTime) / 1000000.0, 0.05);
    _lastTime = now;
    if (_state.phase == GamePhase.playing) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) _engine.update(dt, box.size);
    }
    setState(() {});
  }

  void startNewGame() => _state.reset(savedHi: widget.savedHighScore);
  void revive()       => _engine.revive();
  GameState get gameState => _state;

  void _onTap(TapDownDetails d) {
    if (_state.phase == GamePhase.menu)    { startNewGame(); return; }
    if (_state.phase == GamePhase.playing) _engine.jump();
  }
  void _onPanStart(DragStartDetails d) => _dragStart = d.globalPosition;
  void _onPanEnd(DragEndDetails d) {
    if (_dragStart == null) return;
    final v = d.velocity.pixelsPerSecond;
    if (v.dx.abs() > v.dy.abs()) {
      if (v.dx < -150) _engine.swipeLeft();
      else if (v.dx > 150) _engine.swipeRight();
    } else {
      if (v.dy > 220) _engine.slide();
      else if (v.dy < -220) _engine.jump();
    }
    _dragStart = null;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: _onTap, onPanStart: _onPanStart, onPanEnd: _onPanEnd,
    child: CustomPaint(
      painter: _GP(state: _state, engine: _engine, parts: _parts, coin: _coinImg),
      child: const SizedBox.expand(),
    ),
  );

  @override void dispose() { _ticker.dispose(); super.dispose(); }
}

// ─────────────────────────────────────────────────────────────────────────────
class _GP extends CustomPainter {
  final GameState  state;
  final GameEngine engine;
  final PartImages parts;
  final ui.Image?  coin;
  const _GP({required this.state, required this.engine,
    required this.parts, this.coin});

  // Road geometry
  double _roadL(double y, Size s) {
    final t = ((y-s.height*kHorizonFrac)/(s.height*(1-kHorizonFrac))).clamp(0.0,1.0);
    return s.width/2 - (kRoadHalfTop+(kRoadHalfBot-kRoadHalfTop)*t)*s.width;
  }
  double _roadR(double y, Size s) {
    final t = ((y-s.height*kHorizonFrac)/(s.height*(1-kHorizonFrac))).clamp(0.0,1.0);
    return s.width/2 + (kRoadHalfTop+(kRoadHalfBot-kRoadHalfTop)*t)*s.width;
  }
  double _roadW(double y, Size s) => _roadR(y,s)-_roadL(y,s);
  double _scaleAt(double y, Size s) {
    final t = ((y-s.height*kHorizonFrac)/(s.height*(1-kHorizonFrac))).clamp(0.0,1.0);
    return 0.14+0.86*t;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawScene(canvas, size);
    _drawPowerUps(canvas, size);
    _drawCoins(canvas, size);
    _drawObstacles(canvas, size);
    _drawBonusBirds(canvas, size);
    _drawChicken(canvas, size);
    _drawFarmer(canvas, size);
    _drawHUD(canvas, size);
    if (state.phase == GamePhase.menu) _drawMenu(canvas, size);
  }

  // ── SCENE ──────────────────────────────────────────────────────────────────
  void _drawScene(Canvas canvas, Size s) {
    final hY = s.height * kHorizonFrac;
    // Sky
    canvas.drawRect(Rect.fromLTWH(0,0,s.width,hY), Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF5BA4CF), Color(0xFF9ECDE8)],
      ).createShader(Rect.fromLTWH(0,0,100,hY)));
    // Hills
    final hillPaint = Paint()..color = const Color(0xFF5B9E3A);
    final hillPath  = Path();
    hillPath.moveTo(0, hY);
    for (double x = 0; x <= s.width; x += 8) {
      hillPath.lineTo(x, hY-8+math.sin(x*0.016)*32+math.sin(x*0.038)*16);
    }
    hillPath.lineTo(s.width, hY);
    hillPath.close();
    canvas.drawPath(hillPath, hillPaint);
    // Grass
    canvas.drawRect(Rect.fromLTWH(0,hY,s.width,s.height-hY),
        Paint()..color=const Color(0xFF4A9028));
    // Road
    final roadPath = Path()
      ..moveTo(_roadL(hY+1,s),hY+1)..lineTo(_roadR(hY+1,s),hY+1)
      ..lineTo(_roadR(s.height,s),s.height)..lineTo(_roadL(s.height,s),s.height)..close();
    canvas.drawPath(roadPath, Paint()
      ..shader = LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,
          colors:[const Color(0xFF5A5A5A),const Color(0xFF404040)],
      ).createShader(Rect.fromLTWH(0,hY,s.width,s.height-hY)));
    // Texture
    final texP=Paint()..color=Colors.black.withOpacity(0.07)..strokeWidth=1;
    for (double y=hY+10; y<s.height; y+=14)
      canvas.drawLine(Offset(_roadL(y,s),y),Offset(_roadR(y,s),y),texP);
    _edges(canvas,s); _markings(canvas,s); _grassDecor(canvas,s,hY);
  }

  void _edges(Canvas canvas, Size s) {
    final p=Paint()..color=Colors.white.withOpacity(0.85)..strokeWidth=2.5..strokeCap=StrokeCap.round;
    final hY=s.height*kHorizonFrac;
    for (double y=hY; y<s.height; y+=2) {
      canvas.drawLine(Offset(_roadL(y,s),y),Offset(_roadL(y,s)+1,y+2),p);
      canvas.drawLine(Offset(_roadR(y,s)-1,y),Offset(_roadR(y,s),y+2),p);
    }
  }

  void _markings(Canvas canvas, Size s) {
    final scroll=state.bgScrollY%90;
    for (final e in [(0.335,const Color(0xFFFFFFFF),0.45),(0.500,const Color(0xFFFFDD00),0.90),(0.665,const Color(0xFFFFFFFF),0.45)]) {
      final frac=e.$1 as double; final col=e.$2 as Color; final op=e.$3 as double;
      final p=Paint()..color=col.withOpacity(op)..strokeCap=StrokeCap.round;
      final hY=s.height*kHorizonFrac;
      double y=hY+scroll; bool dash=true;
      while(y<s.height) {
        final sc=_scaleAt(y,s); final dLen=(14+sc*48).clamp(8.0,62.0); final gap=(8+sc*28).clamp(6.0,36.0);
        final lx=_roadL(y,s); final rx=_roadR(y,s); final x=lx+(rx-lx)*frac;
        p.strokeWidth=(1.2+sc*3.5).clamp(1.0,4.5);
        if(dash) canvas.drawLine(Offset(x,y),Offset(x,math.min(y+dLen,s.height)),p);
        y+=dLen+gap; dash=!dash;
      }
    }
  }

  void _grassDecor(Canvas canvas, Size s, double hY) {
    final rng=math.Random(42); final sf=(state.bgScrollY/s.height)%1.0;
    final cols=[const Color(0xFFFFD700),const Color(0xFFFF6B6B),const Color(0xFFFF8C00),const Color(0xFF9B59B6)];
    for (int i=0; i<32; i++) {
      final bf=rng.nextDouble(); final y=((bf-sf+2.0)%1.0)*(s.height-hY)+hY;
      if(y<hY+4||y>s.height-4) continue;
      final rl=_roadL(y,s); final rr=_roadR(y,s); final side=rng.nextBool();
      final mo=side?(rl-20).clamp(10.0,rl-10):(s.width-rr-20).clamp(10.0,s.width-rr-10);
      final x=side?rl-rng.nextDouble()*mo:rr+rng.nextDouble()*mo;
      canvas.drawCircle(Offset(x,y),(3.5*_scaleAt(y,s)).clamp(1.5,5.0),
          Paint()..color=cols[i%4].withOpacity(0.80));
    }
  }

  // ── OBSTACLES ──────────────────────────────────────────────────────────────
  void _drawObstacles(Canvas canvas, Size s) {
    final sorted=List<Obstacle>.from(state.obstacles)..sort((a,b)=>a.y.compareTo(b.y));
    for (final o in sorted) {
      if(o.y<s.height*kHorizonFrac) continue;
      final ox=engine.laneXatY(o.lane,o.y,s); final sc=_scaleAt(o.y,s);
      switch(o.type) {
        case ObstacleType.hayBale:     _hayBale(canvas,ox,o.y,sc,s);           break;
        case ObstacleType.fence:       _fence(canvas,ox,o.y,o.height,sc,s);    break;
        case ObstacleType.pumpkinPair: _pumpkin(canvas,ox,o.y,sc,s);           break;
        case ObstacleType.barrier:     _barrier(canvas,ox,o.y,o.height,sc,s);  break;
      }
    }
  }

  void _hayBale(Canvas canvas,double x,double y,double sc,Size s){
    final r=_roadW(y,s)*0.13;
    canvas.drawOval(Rect.fromCenter(center:Offset(x,y+r*0.18),width:r*2.2,height:r*0.32),
        Paint()..color=Colors.black.withOpacity(0.22));
    canvas.drawOval(Rect.fromCenter(center:Offset(x,y-r*0.5),width:r*2.1,height:r*1.7),
        Paint()..color=const Color(0xFFD4A017));
    final rp=Paint()..color=const Color(0xFFB8860B)..strokeWidth=1.8*sc..style=PaintingStyle.stroke;
    for(final f in [0.40,0.65,0.87]) canvas.drawCircle(Offset(x,y-r*0.5),r*f,rp);
    final sp=Paint()..color=const Color(0xFFC89A0A)..strokeWidth=0.8*sc..style=PaintingStyle.stroke;
    for(double i=-r*0.82;i<=r*0.82;i+=r*0.15){
      final hw=math.sqrt(math.max(0,r*r-i*i));
      canvas.drawLine(Offset(x-hw,y-r*0.5+i),Offset(x+hw,y-r*0.5+i),sp);
    }
    _hint(canvas,x,y-r*1.6,'↑ JUMP',sc);
  }

  void _fence(Canvas canvas,double x,double y,double h,double sc,Size s){
    final w=_roadW(y,s)*0.20; final sh=h*sc; final top=y-sh;
    final pp=Paint()..color=const Color(0xFF8B5E1A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x-w*0.5,top,w*0.15,sh),const Radius.circular(2)),pp);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.35,top,w*0.15,sh),const Radius.circular(2)),pp);
    final rp=Paint()..color=const Color(0xFFA07030);
    for(final f in [0.08,0.38,0.65])
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x-w*0.52,top+sh*f,w*1.04,(9*sc).clamp(4,12)),const Radius.circular(2)),rp);
    _hint(canvas,x,top-8,'↓ SLIDE',sc);
  }

  void _pumpkin(Canvas canvas,double x,double y,double sc,Size s){
    final r=_roadW(y,s)*0.11;
    for(final dx in [-r*0.52,0.0,r*0.52])
      canvas.drawOval(Rect.fromCenter(center:Offset(x+dx,y-r),width:r*1.2,height:r*1.9),
          Paint()..color=dx==0?const Color(0xFFE64A19):const Color(0xFFBF360C));
    canvas.drawRect(Rect.fromLTWH(x-r*0.1,y-r*2.0,r*0.2,r*0.45),Paint()..color=const Color(0xFF2E7D32));
    final ep=Paint()..color=const Color(0xFF111111);
    for(final ex in [-r*0.25,r*0.25])
      canvas.drawPath(Path()..moveTo(x+ex,y-r*1.25)..lineTo(x+ex-r*0.16,y-r*0.88)..lineTo(x+ex+r*0.16,y-r*0.88)..close(),ep);
    _hint(canvas,x,y-r*2.2,'↑ JUMP',sc);
  }

  void _barrier(Canvas canvas,double x,double y,double h,double sc,Size s){
    final w=_roadW(y,s)*0.18; final sh=h*sc; final top=y-sh;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x-w/2,top,w,sh),const Radius.circular(4)),
        Paint()..color=const Color(0xFFE53935));
    final sp=Paint()..color=Colors.white.withOpacity(0.50);
    for(double sy=top;sy<y;sy+=(16*sc).clamp(8,20))
      canvas.drawRect(Rect.fromLTWH(x-w/2,sy,w,(8*sc).clamp(4,10)),sp);
    _hint(canvas,x,top-8,'↑ JUMP',sc);
  }

  void _hint(Canvas canvas,double x,double y,String txt,double sc){
    final sz=(10*sc).clamp(9.0,13.0);
    final tp=TextPainter(text:TextSpan(text:txt,style:TextStyle(
        color:Colors.yellow.withOpacity(0.92),fontSize:sz,fontWeight:FontWeight.bold,
        shadows:const[Shadow(blurRadius:2,color:Colors.black)])),
        textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas,Offset(x-tp.width/2,y-tp.height));
  }

  // ── COINS ─────────────────────────────────────────────────────────────────
  void _drawCoins(Canvas canvas, Size s) {
    for(final c in state.coinItems){
      if(c.collected||c.y<s.height*kHorizonFrac) continue;
      final cx=engine.laneXatY(c.lane,c.y,s); final sc=_scaleAt(c.y,s);
      final r=(_roadW(c.y,s)*0.09*sc).clamp(6.0,22.0);
      final bob=math.sin(state.animT*5+c.lane*1.2)*2*sc;
      _coinAt(canvas,cx,c.y+bob,r);
    }
  }

  void _coinAt(Canvas canvas,double x,double y,double r){
    canvas.drawCircle(Offset(x,y),r+4,
        Paint()..color=kColGold.withOpacity(0.28)..maskFilter=const MaskFilter.blur(BlurStyle.normal,5));
    if(coin!=null){
      canvas.drawImageRect(coin!,Rect.fromLTWH(0,0,coin!.width.toDouble(),coin!.height.toDouble()),
          Rect.fromCenter(center:Offset(x,y),width:r*2,height:r*2),
          Paint()..filterQuality=FilterQuality.medium);
    } else {
      canvas.drawCircle(Offset(x,y),r,Paint()..color=kColYolk);
      canvas.drawCircle(Offset(x,y),r*0.65,Paint()..color=kColGold);
    }
  }

  // ── POWER-UPS ─────────────────────────────────────────────────────────────
  void _drawPowerUps(Canvas canvas, Size s) {
    for(final p in state.powerUps){
      if(p.collected||p.y<s.height*kHorizonFrac) continue;
      final px=engine.laneXatY(p.lane,p.y,s); final sc=_scaleAt(p.y,s);
      final r=(22*sc).clamp(10.0,26.0);
      final col=p.type==PowerUpType.magnet?const Color(0xFF2196F3)
               :p.type==PowerUpType.shield ?const Color(0xFF4CAF50):const Color(0xFF9C27B0);
      canvas.drawCircle(Offset(px,p.y),r+6,
          Paint()..color=col.withOpacity(0.25)..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
      canvas.drawCircle(Offset(px,p.y),r,Paint()..color=col.withOpacity(0.92));
      _t(canvas,p.type==PowerUpType.magnet?'🧲':p.type==PowerUpType.shield?'🛡':'✕2',
          px,p.y+(r*0.55),r*0.9,Colors.white,center:true);
    }
  }

  // ── BONUS BIRDS ───────────────────────────────────────────────────────────
  void _drawBonusBirds(Canvas canvas, Size s) {
    for(final b in state.bonusBirds){
      if(b.collected) continue;
      final flap=math.sin(state.animT*9)*6;
      canvas.drawCircle(Offset(b.x,b.y),32,
          Paint()..color=kColYolk.withOpacity(0.22)..maskFilter=const MaskFilter.blur(BlurStyle.normal,10));
      canvas.drawOval(Rect.fromCenter(center:Offset(b.x,b.y),width:46,height:32),
          Paint()..color=const Color(0xFFFFE082));
      canvas.drawOval(Rect.fromCenter(center:Offset(b.x,b.y-9+flap),width:36,height:13),
          Paint()..color=const Color(0xFFFFC107).withOpacity(0.88));
      final hx=b.x+(b.speed<0?-22:22);
      canvas.drawCircle(Offset(hx,b.y-5),13,Paint()..color=const Color(0xFFFFD54F));
      canvas.drawCircle(Offset(hx,b.y-16),4,Paint()..color=kColRed);
      canvas.drawCircle(Offset(hx+(b.speed<0?-5:5),b.y-8),3,Paint()..color=Colors.black87);
      final bk=b.speed<0?-14.0:14.0;
      canvas.drawPath(Path()..moveTo(hx,b.y-6)..lineTo(hx+bk,b.y-3)..lineTo(hx,b.y),
          Paint()..color=const Color(0xFFFF8F00));
      _coinAt(canvas,b.x,b.y-38,10);
      _t(canvas,'+${b.coins}',b.x,b.y-52,11,kColYolk,bold:true,center:true);
    }
  }

  // ── CHICKEN (part-based skeletal) ─────────────────────────────────────────
  void _drawChicken(Canvas canvas, Size s) {
    final playerY = s.height * kPlayerYFrac;
    final cx      = engine.currentPlayerX(s);
    final cy      = playerY - state.playerYOffset;
    final scale   = _roadW(playerY, s) * 0.0038;  // scale relative to road width

    // Shadow
    final ss = math.max(0.15, 1.0-state.playerYOffset/180);
    canvas.drawOval(
      Rect.fromCenter(center:Offset(cx, playerY+scale*22),
          width:scale*68*ss, height:scale*14*ss),
      Paint()..color=Colors.black.withOpacity(0.24*ss));

    ChickenPainter.draw(
      canvas, parts,
      Offset(cx, cy),
      scale,
      state.animT,
      state.isJumping,
      state.isSliding,
      state.isInvincible,
      state.animFrame,
    );
  }

  // ── FARMER (part-based skeletal) ──────────────────────────────────────────
  void _drawFarmer(Canvas canvas, Size s) {
    final fs      = state.farmerScale;
    final baseY   = s.height * (0.975 + fs*0.015);
    final rw      = _roadW(baseY, s);
    final scale   = rw * fs * 0.0052;

    // Danger aura
    if (state.farmerDanger > 0.40) {
      final pulse = math.sin(state.animT*7)*0.5+0.5;
      final fw = rw*fs*0.55;
      canvas.drawOval(
        Rect.fromCenter(center:Offset(s.width/2,baseY-fw*1.2),width:fw*1.5,height:fw*2.0),
        Paint()..color=Colors.red.withOpacity(0.10*(state.farmerDanger-0.40)*2.5*pulse)
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal,22));
    }

    FarmerPainter.draw(
      canvas, parts,
      Offset(s.width/2, baseY),
      scale,
      state.animT,
      state.farmerDanger,
    );
  }

  // ── HUD ───────────────────────────────────────────────────────────────────
  void _drawHUD(Canvas canvas, Size s) {
    if(state.phase==GamePhase.menu) return;
    _panel(canvas,10,10,162,58); _t(canvas,'SCORE',22,30,11,Colors.white54);
    _t(canvas,_fmt(state.score.toInt()),22,52,24,kColYolk,bold:true);
    _panel(canvas,184,10,122,58); _t(canvas,'💰 COINS',196,30,11,Colors.white54);
    _t(canvas,'${state.coins}',196,52,24,kColYolk,bold:true);
    _panel(canvas,s.width-172,10,160,58);
    _t(canvas,'🏆 BEST',s.width-160,30,11,Colors.white54);
    _t(canvas,_fmt(state.highScore),s.width-160,52,19,const Color(0xFF69F0AE),bold:true);
    double px=10;
    if(state.magnetActive){_badge(canvas,px,78,'🧲',const Color(0xFF2196F3),state.magnetFrames,480);px+=58;}
    if(state.shieldActive){_badge(canvas,px,78,'🛡', const Color(0xFF4CAF50),state.shieldFrames,360);px+=58;}
    if(state.x2Active)    {_badge(canvas,px,78,'✕2', const Color(0xFF9C27B0),state.x2Frames,600);px+=58;}
    if(state.multiplier>1)
      _t(canvas,'✕${state.multiplier}',s.width/2,90,28,const Color(0xFF9C27B0),bold:true,center:true);
    final d=state.farmerDanger;
    if(d>0.12){
      final mw=s.width*0.56; final mx=(s.width-mw)/2; final my=s.height-62.0;
      final col=Color.lerp(kColBlaze,kColRed,d)!;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(mx,my,mw,14),const Radius.circular(7)),
          Paint()..color=Colors.black.withOpacity(0.40));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(mx,my,mw*d,14),const Radius.circular(7)),
          Paint()..color=col);
      _t(canvas,'⚠  FARMER CLOSING IN!',mx+4,my-4,11,col,bold:true);
    }
  }

  void _badge(Canvas canvas,double x,double y,String icon,Color col,int f,int total){
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,50,50),const Radius.circular(10)),
        Paint()..color=col.withOpacity(0.20));
    canvas.drawArc(Rect.fromLTWH(x+2,y+2,46,46),-math.pi/2,math.pi*2*(f/total),
        false,Paint()..color=col..style=PaintingStyle.stroke..strokeWidth=3);
    _t(canvas,icon,x+25,y+31,18,Colors.white,center:true);
  }

  void _drawMenu(Canvas canvas, Size s) {
    final cx=s.width/2; final cy=s.height*0.38;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(cx,cy),width:330,height:155),const Radius.circular(22)),
        Paint()..color=Colors.black.withOpacity(0.78));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(cx,cy),width:330,height:155),const Radius.circular(22)),
        Paint()..color=kColYolk.withOpacity(0.42)..style=PaintingStyle.stroke..strokeWidth=2.2);
    _t(canvas,'🐔  CLUCK & RUN!',cx,cy-40,26,kColYolk,bold:true,center:true);
    _t(canvas,'TAP  to  Start',cx,cy-4,18,Colors.white,center:true);
    _t(canvas,'← → Lanes   ↑ Jump   ↓ Slide',cx,cy+24,11,Colors.white60,center:true);
    if(state.highScore>0) _t(canvas,'🏆 Best: ${_fmt(state.highScore)}',cx,cy+50,14,kColGold,center:true);
  }

  void _panel(Canvas c,double x,double y,double w,double h){
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,h),const Radius.circular(10)),
        Paint()..color=Colors.black.withOpacity(0.58));
  }
  void _t(Canvas c,String text,double x,double y,double fs,Color col,{bool bold=false,bool center=false}){
    final tp=TextPainter(text:TextSpan(text:text,style:TextStyle(color:col,fontSize:fs,
        fontWeight:bold?FontWeight.w900:FontWeight.normal,
        shadows:const[Shadow(blurRadius:2,color:Color(0x66000000))])),
        textDirection:TextDirection.ltr)..layout();
    tp.paint(c,center?Offset(x-tp.width/2,y-tp.height/2):Offset(x,y-tp.height));
  }
  String _fmt(int n)=>n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),(m)=>'${m[1]},');

  @override bool shouldRepaint(covariant _GP o)=>true;
}
