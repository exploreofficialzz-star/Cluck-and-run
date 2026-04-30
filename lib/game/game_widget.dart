// lib/game/game_widget.dart — perspective-correct vertical runner
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
  ui.Image? _chickenImg, _farmerImg, _coinImg;
  bool _loaded = false;

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

  Future<ui.Image> _load(String a) async {
    final d = await rootBundle.load(a); final c = await ui.instantiateImageCodec(d.buffer.asUint8List());
    return (await c.getNextFrame()).image;
  }

  Future<void> _loadAssets() async {
    _chickenImg = await _load('assets/images/chicken_sprite.png');
    _farmerImg  = await _load('assets/images/farmer_nobg.png');
    _coinImg    = await _load('assets/images/coin.png');
    if (mounted) setState(() => _loaded = true);
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
      if (v.dx < -150) _engine.swipeLeft(); else if (v.dx > 150) _engine.swipeRight();
    } else {
      if (v.dy > 220) _engine.slide(); else if (v.dy < -220) _engine.jump();
    }
    _dragStart = null;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: _onTap, onPanStart: _onPanStart, onPanEnd: _onPanEnd,
    child: CustomPaint(
      painter: _GP(state: _state, engine: _engine, chicken: _chickenImg,
          farmer: _farmerImg, coin: _coinImg),
      child: const SizedBox.expand(),
    ),
  );

  @override void dispose() { _ticker.dispose(); super.dispose(); }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER — Everything perspective-correct
// ─────────────────────────────────────────────────────────────────────────────
class _GP extends CustomPainter {
  final GameState  state;
  final GameEngine engine;
  final ui.Image?  chicken, farmer, coin;
  const _GP({required this.state, required this.engine,
    this.chicken, this.farmer, this.coin});

  // ── Road geometry helpers ──────────────────────────────────────────────────
  double _roadL(double y, Size s) {
    final t = ((y - s.height*kHorizonFrac)/(s.height*(1-kHorizonFrac))).clamp(0.0,1.0);
    return s.width/2 - (kRoadHalfTop + (kRoadHalfBot-kRoadHalfTop)*t)*s.width;
  }
  double _roadR(double y, Size s) {
    final t = ((y - s.height*kHorizonFrac)/(s.height*(1-kHorizonFrac))).clamp(0.0,1.0);
    return s.width/2 + (kRoadHalfTop + (kRoadHalfBot-kRoadHalfTop)*t)*s.width;
  }
  double _roadW(double y, Size s) => _roadR(y,s) - _roadL(y,s);
  double _scaleAt(double y, Size s) {
    final t = ((y - s.height*kHorizonFrac)/(s.height*(1-kHorizonFrac))).clamp(0.0,1.0);
    return 0.14 + 0.86*t;
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

  // ── SCENE (sky + road + grass) ─────────────────────────────────────────────
  void _drawScene(Canvas canvas, Size s) {
    final hY = s.height * kHorizonFrac;
    final cx = s.width  / 2;

    // Sky gradient
    canvas.drawRect(Rect.fromLTWH(0,0,s.width,hY), Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [const Color(0xFF6DB3D4), const Color(0xFF9ECDE8)],
      ).createShader(Rect.fromLTWH(0,0,s.width,hY)));

    // Distant hills
    final hillP = Paint()..color = const Color(0xFF5B9E3A);
    final hillPath = Path()..moveTo(0, hY);
    for (double x = 0; x <= s.width; x += 8) {
      final nh = math.sin(x * 0.016) * 32 + math.sin(x * 0.038) * 16;
      hillPath.lineTo(x, hY - 8 + nh);
    }
    hillPath.lineTo(s.width, hY)..close();
    canvas.drawPath(hillPath, hillP);

    // Left grass
    final grassP = Paint()..color = const Color(0xFF4A9028);
    canvas.drawRect(Rect.fromLTWH(0, hY, s.width, s.height - hY), grassP);

    // Road trapezoid (asphalt)
    final roadPath = Path()
      ..moveTo(_roadL(hY+1, s), hY+1)
      ..lineTo(_roadR(hY+1, s), hY+1)
      ..lineTo(_roadR(s.height, s), s.height)
      ..lineTo(_roadL(s.height, s), s.height)
      ..close();
    canvas.drawPath(roadPath, Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [const Color(0xFF606060), const Color(0xFF484848)],
      ).createShader(Rect.fromLTWH(0,hY,s.width,s.height-hY)));

    // Asphalt texture (horizontal lines)
    final texP = Paint()..color = Colors.black.withOpacity(0.06)..strokeWidth = 1;
    for (double y = hY + 10; y < s.height; y += 14) {
      canvas.drawLine(Offset(_roadL(y,s), y), Offset(_roadR(y,s), y), texP);
    }

    // Road edge white stripes
    _drawEdgeStripe(canvas, s, isLeft: true);
    _drawEdgeStripe(canvas, s, isLeft: false);

    // Scrolling lane markings
    _drawLaneMarkings(canvas, s);

    // Grass texture dots
    _drawGrassDecor(canvas, s, hY);
  }

  void _drawEdgeStripe(Canvas canvas, Size s, {required bool isLeft}) {
    final p = Paint()..color = Colors.white.withOpacity(0.85)..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    final hY = s.height * kHorizonFrac;
    for (double y = hY; y < s.height; y += 2) {
      final x = isLeft ? _roadL(y, s) : _roadR(y, s);
      canvas.drawLine(Offset(x, y), Offset(x+1, y+2), p);
    }
  }

  void _drawLaneMarkings(Canvas canvas, Size s) {
    final scroll = state.bgScrollY;
    // Three dashed lines: left-divider, centre (yellow), right-divider
    for (final entry in [
      (0.335, const Color(0xFFFFFFFF), 0.45),
      (0.500, const Color(0xFFFFDD00), 0.90),
      (0.665, const Color(0xFFFFFFFF), 0.45),
    ]) {
      final frac = entry.$1; final col = entry.$2; final op = entry.$3;
      final p = Paint()..color = (col as Color).withOpacity(op as double)..strokeCap = StrokeCap.round;
      final hY = s.height * kHorizonFrac;
      // Build dashes bottom→up so scroll makes them appear to come toward player
      double y    = s.height + (scroll % 90) - 90;
      bool   dash = true;
      while (y > hY) {
        final sc   = _scaleAt(y, s);
        final dLen = (14 + sc * 48).clamp(8.0, 62.0);
        final gap  = (8  + sc * 28).clamp(6.0, 36.0);
        final lx   = _roadL(y, s); final rx = _roadR(y, s);
        final x    = lx + (rx - lx) * frac;
        p.strokeWidth = (1.2 + sc * 3.5).clamp(1.0, 4.5);
        if (dash) canvas.drawLine(Offset(x, y), Offset(x, math.max(y - dLen, hY)), p);
        y   -= dLen + gap;
        dash = !dash;
      }
    }
  }

  void _drawGrassDecor(Canvas canvas, Size s, double hY) {
    // Static seed-based flowers and tufts on the grass
    final rng = math.Random(42);
    final scrollFrac = (state.bgScrollY / s.height) % 1.0;
    for (int i = 0; i < 32; i++) {
      final baseFrac = rng.nextDouble();
      final y = ((baseFrac - scrollFrac + 2.0) % 1.0) * (s.height - hY) + hY;
      if (y < hY + 4 || y > s.height - 4) continue;
      final roadL = _roadL(y, s); final roadR = _roadR(y, s);
      final side   = rng.nextBool();
      final x      = side
          ? roadL  - rng.nextDouble() * (roadL - 20).clamp(10, roadL - 10)
          : roadR  + rng.nextDouble() * (s.width - roadR - 20).clamp(10, s.width - roadR - 10);
      final sc     = _scaleAt(y, s);
      final col    = [const Color(0xFFFFD700), const Color(0xFFFF6B6B),
                      const Color(0xFFFF8C00), const Color(0xFF9B59B6)][i % 4];
      canvas.drawCircle(Offset(x, y), (3.5 * sc).clamp(1.5, 5.0),
          Paint()..color = col.withOpacity(0.80));
    }
  }

  // ── OBSTACLES (perspective-scaled) ─────────────────────────────────────────
  void _drawObstacles(Canvas canvas, Size s) {
    // Sort back-to-front (smaller Y = further = draw first)
    final sorted = List<Obstacle>.from(state.obstacles)
      ..sort((a, b) => a.y.compareTo(b.y));
    for (final o in sorted) {
      if (o.y < s.height * kHorizonFrac) continue;
      final ox = engine.laneXatY(o.lane, o.y, s);
      final sc = _scaleAt(o.y, s);
      switch (o.type) {
        case ObstacleType.hayBale:     _hayBale(canvas, ox, o.y, sc, s); break;
        case ObstacleType.fence:       _fence(canvas, ox, o.y, o.height, sc, s); break;
        case ObstacleType.pumpkinPair: _pumpkin(canvas, ox, o.y, sc, s); break;
        case ObstacleType.barrier:     _barrier(canvas, ox, o.y, o.height, sc, s); break;
      }
    }
  }

  void _hayBale(Canvas canvas, double x, double y, double sc, Size s) {
    final r = _roadW(y,s) * 0.13;
    // Shadow
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y+r*0.18), width: r*2.2, height: r*0.32),
        Paint()..color = Colors.black.withOpacity(0.22));
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y-r*0.5), width: r*2.1, height: r*1.7),
        Paint()..color = const Color(0xFFD4A017));
    // Rings
    final rp = Paint()..color=const Color(0xFFB8860B)..strokeWidth=1.8*sc..style=PaintingStyle.stroke;
    for (final f in [0.40, 0.65, 0.87]) canvas.drawCircle(Offset(x, y-r*0.5), r*f, rp);
    // Straw
    final sp = Paint()..color=const Color(0xFFC89A0A)..strokeWidth=0.8*sc..style=PaintingStyle.stroke;
    for (double i = -r*0.82; i <= r*0.82; i += r*0.15) {
      final hw = math.sqrt(math.max(0, r*r - i*i));
      canvas.drawLine(Offset(x-hw, y-r*0.5+i), Offset(x+hw, y-r*0.5+i), sp);
    }
    _obsHint(canvas, x, y - r*1.6, '↑ JUMP', sc);
  }

  void _fence(Canvas canvas, double x, double y, double h, double sc, Size s) {
    final w = _roadW(y,s) * 0.20;  final sh = h * sc;  final top = y - sh;
    final pp = Paint()..color=const Color(0xFF8B5E1A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x-w*0.5, top, w*0.15, sh), const Radius.circular(2)), pp);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.35,top, w*0.15, sh), const Radius.circular(2)), pp);
    // Rails
    final rp = Paint()..color=const Color(0xFFA07030);
    for (final frac in [0.08, 0.38, 0.65]) {
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(x-w*0.52, top + sh*frac, w*1.04, (9*sc).clamp(4,12)),
          const Radius.circular(2)), rp);
    }
    _obsHint(canvas, x, top - 8, '↓ SLIDE', sc);
  }

  void _pumpkin(Canvas canvas, double x, double y, double sc, Size s) {
    final r = _roadW(y,s) * 0.11;
    for (final dx in [-r*0.52, 0.0, r*0.52]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x+dx, y-r),
          width: r*1.2, height: r*1.9),
          Paint()..color = dx==0 ? const Color(0xFFE64A19) : const Color(0xFFBF360C));
    }
    canvas.drawRect(Rect.fromLTWH(x-r*0.1, y-r*2.0, r*0.2, r*0.45),
        Paint()..color=const Color(0xFF2E7D32));
    final ep = Paint()..color=const Color(0xFF111111);
    for (final ex in [-r*0.25, r*0.25]) {
      canvas.drawPath(Path()
        ..moveTo(x+ex, y-r*1.25)..lineTo(x+ex-r*0.16, y-r*0.88)..lineTo(x+ex+r*0.16, y-r*0.88)..close(), ep);
    }
    _obsHint(canvas, x, y - r*2.2, '↑ JUMP', sc);
  }

  void _barrier(Canvas canvas, double x, double y, double h, double sc, Size s) {
    final w = _roadW(y,s)*0.18; final sh = h*sc; final top = y-sh;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x-w/2,top,w,sh), const Radius.circular(4)),
        Paint()..color=const Color(0xFFE53935));
    final sp = Paint()..color=Colors.white.withOpacity(0.50);
    for (double sy = top; sy < y; sy += (16*sc).clamp(8,20)) {
      canvas.drawRect(Rect.fromLTWH(x-w/2, sy, w, (8*sc).clamp(4,10)), sp);
    }
    _obsHint(canvas, x, top - 8, '↑ JUMP', sc);
  }

  void _obsHint(Canvas canvas, double x, double y, String txt, double sc) {
    final sz = (10 * sc).clamp(9.0, 13.0);
    final tp = TextPainter(text: TextSpan(text: txt, style: TextStyle(
        color: Colors.yellow.withOpacity(0.92), fontSize: sz,
        fontWeight: FontWeight.bold,
        shadows: const [Shadow(blurRadius: 2, color: Colors.black)])),
        textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x - tp.width/2, y - tp.height));
  }

  // ── COINS (perspective-scaled, ON road) ────────────────────────────────────
  void _drawCoins(Canvas canvas, Size s) {
    for (final c in state.coinItems) {
      if (c.collected || c.y < s.height * kHorizonFrac) continue;
      final cx  = engine.laneXatY(c.lane, c.y, s);
      final sc  = _scaleAt(c.y, s);
      final r   = (_roadW(c.y, s) * 0.09 * sc).clamp(6.0, 22.0);
      final bob = math.sin(state.animT*5 + c.lane*1.2) * 2 * sc;
      _coinAt(canvas, cx, c.y + bob, r);
    }
  }

  void _coinAt(Canvas canvas, double x, double y, double r) {
    canvas.drawCircle(Offset(x,y), r+4,
        Paint()..color=kColGold.withOpacity(0.28)..maskFilter=const MaskFilter.blur(BlurStyle.normal,5));
    if (coin != null) {
      final src = Rect.fromLTWH(0,0,coin!.width.toDouble(),coin!.height.toDouble());
      canvas.drawImageRect(coin!, src, Rect.fromCenter(center:Offset(x,y), width:r*2, height:r*2),
          Paint()..filterQuality=FilterQuality.medium);
    } else {
      canvas.drawCircle(Offset(x,y), r, Paint()..color=kColYolk);
      canvas.drawCircle(Offset(x,y), r*0.65, Paint()..color=kColGold);
    }
  }

  // ── POWER-UPS ──────────────────────────────────────────────────────────────
  void _drawPowerUps(Canvas canvas, Size s) {
    for (final p in state.powerUps) {
      if (p.collected || p.y < s.height*kHorizonFrac) continue;
      final px = engine.laneXatY(p.lane, p.y, s);
      final sc = _scaleAt(p.y, s);
      final r  = (22*sc).clamp(10.0, 26.0);
      final col = p.type==PowerUpType.magnet ? const Color(0xFF2196F3)
                : p.type==PowerUpType.shield  ? const Color(0xFF4CAF50)
                                               : const Color(0xFF9C27B0);
      canvas.drawCircle(Offset(px,p.y), r+6,
          Paint()..color=col.withOpacity(0.25)..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
      canvas.drawCircle(Offset(px,p.y), r, Paint()..color=col.withOpacity(0.92));
      final icon = p.type==PowerUpType.magnet?'🧲':p.type==PowerUpType.shield?'🛡':'✕2';
      _t(canvas, icon, px, p.y+(r*0.55), r*0.9, Colors.white, center:true);
    }
  }

  // ── BONUS BIRDS ─────────────────────────────────────────────────────────────
  void _drawBonusBirds(Canvas canvas, Size s) {
    for (final b in state.bonusBirds) {
      if (b.collected) continue;
      final flap = math.sin(state.animT*9)*6;
      final sc   = _scaleAt(b.y, s);
      final r    = 22.0;
      // Glow
      canvas.drawCircle(Offset(b.x,b.y), r+10,
          Paint()..color=kColYolk.withOpacity(0.22)..maskFilter=const MaskFilter.blur(BlurStyle.normal,10));
      // Body
      canvas.drawOval(Rect.fromCenter(center:Offset(b.x,b.y), width:46, height:32),
          Paint()..color=const Color(0xFFFFE082));
      // Flapping wings
      canvas.drawOval(Rect.fromCenter(center:Offset(b.x,b.y-9+flap), width:36, height:13),
          Paint()..color=const Color(0xFFFFC107).withOpacity(0.88));
      canvas.drawOval(Rect.fromCenter(center:Offset(b.x,b.y+7-flap), width:28, height:10),
          Paint()..color=const Color(0xFFFFC107).withOpacity(0.70));
      // Head
      final hx = b.x + (b.speed<0?-22:22);
      canvas.drawCircle(Offset(hx, b.y-5), 13, Paint()..color=const Color(0xFFFFD54F));
      // Red comb
      canvas.drawCircle(Offset(hx, b.y-16), 4, Paint()..color=kColRed);
      // Eye
      canvas.drawCircle(Offset(hx+(b.speed<0?-5:5), b.y-8), 3, Paint()..color=Colors.black87);
      canvas.drawCircle(Offset(hx+(b.speed<0?-4:6), b.y-9), 1.2, Paint()..color=Colors.white);
      // Beak
      final bk = b.speed<0?-14:14;
      canvas.drawPath(Path()..moveTo(hx,b.y-6)..lineTo(hx+bk,b.y-3)..lineTo(hx,b.y),
          Paint()..color=const Color(0xFFFF8F00));
      // Coin indicator above
      _coinAt(canvas, b.x, b.y-38, 10);
      _t(canvas, '+${b.coins}', b.x, b.y-52, 11, kColYolk, bold:true, center:true);
    }
  }

  // ── CHICKEN (player) ───────────────────────────────────────────────────────
  void _drawChicken(Canvas canvas, Size s) {
    final playerY = s.height * kPlayerYFrac;
    final cx = engine.currentPlayerX(s);
    final cy = playerY - state.playerYOffset;
    // Size proportional to road width at player position
    final rw  = _roadW(playerY, s);
    final cw  = rw * (state.isSliding ? 0.34 : 0.28);
    final ch  = state.isSliding ? rw * 0.14 : rw * 0.48;
    final t   = state.animT;

    if (state.isInvincible && (state.animFrame~/4)%2==1) return;

    // Shadow (shrinks when jumping high)
    final shadowFrac = math.max(0.2, 1.0 - state.playerYOffset / 200);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, playerY + ch*0.08),
          width: cw*0.85*shadowFrac, height: ch*0.10*shadowFrac),
      Paint()..color=Colors.black.withOpacity(0.28*shadowFrac));

    // Shield aura
    if (state.shieldActive) {
      canvas.drawCircle(Offset(cx, cy-ch*0.15), math.max(cw,ch)*0.62,
          Paint()..color=const Color(0xFF4CAF50).withOpacity(0.22)
                 ..maskFilter=const MaskFilter.blur(BlurStyle.normal,14));
    }

    // Squash/stretch
    final runC = math.sin(t * 11.0);
    final sx   = state.isSliding ? 1.38 : (state.isJumping ? 0.85 : 1.0 + runC*0.04);
    final sy   = state.isSliding ? 0.55 : (state.isJumping ? 1.16 : 1.0 - runC.abs()*0.035);

    canvas.save();
    canvas.translate(cx, cy - ch*0.5);
    canvas.scale(sx, sy);

    if (chicken != null) {
      final src = Rect.fromLTWH(0,0,chicken!.width.toDouble(),chicken!.height.toDouble());
      canvas.drawImageRect(chicken!, src,
          Rect.fromCenter(center: Offset.zero, width: cw, height: ch),
          Paint()..filterQuality=FilterQuality.high);
    }

    // Animated legs (drawn over image bottom)
    if (!state.isSliding) _chickenLegs(canvas, cw, ch, t);
    if (state.isJumping)  _wingsOut(canvas, cw, ch, t);

    canvas.restore();

    // Magnet radius indicator
    if (state.magnetActive) {
      canvas.drawCircle(Offset(cx, cy-ch*0.2), 90,
          Paint()..color=const Color(0xFF2196F3).withOpacity(0.08)
                 ..style=PaintingStyle.stroke..strokeWidth=1.5);
    }
  }

  void _chickenLegs(Canvas canvas, double w, double h, double t) {
    final lp  = Paint()..color=const Color(0xFFE8A020)..strokeWidth=w*0.055..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    final tp2 = Paint()..color=const Color(0xFFD4890E)..strokeWidth=w*0.040..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    final cycle = t * 11.0;
    for (int i = 0; i < 2; i++) {
      final phase = i==0 ? cycle : cycle + math.pi;
      final lx    = i==0 ? -w*0.11 : w*0.09;
      final lift  = math.max(0.0, math.sin(phase));
      final fwd   = math.sin(phase) * w * 0.12;
      final midY  = h * 0.36;
      final botY  = h * 0.46 - lift * h * 0.16;
      final footX = lx + fwd;
      final footY = botY + h * 0.12 * (1 - lift * 0.5);
      // Thigh
      canvas.drawLine(Offset(lx, h*0.28), Offset(lx+fwd*0.45, midY), lp);
      // Shin
      canvas.drawLine(Offset(lx+fwd*0.45, midY), Offset(footX, footY), lp);
      // Toes
      if (lift < 0.65) {
        canvas.drawLine(Offset(footX,footY), Offset(footX-w*0.10,footY+h*0.06), tp2);
        canvas.drawLine(Offset(footX,footY), Offset(footX+w*0.08,footY+h*0.06), tp2);
        canvas.drawLine(Offset(footX,footY), Offset(footX,       footY+h*0.08), tp2);
        canvas.drawLine(Offset(footX,footY), Offset(footX-w*0.06,footY-h*0.02), tp2);
      }
    }
  }

  void _wingsOut(Canvas canvas, double w, double h, double t) {
    final flap = math.sin(t*14)*0.28 + 0.20;
    final wp   = Paint()..color=Colors.white.withOpacity(0.72);
    canvas.drawOval(Rect.fromCenter(center:Offset(-w*0.32,-h*0.08-flap*h*0.10), width:w*0.38,height:h*0.18), wp);
    canvas.drawOval(Rect.fromCenter(center:Offset( w*0.24,-h*0.08-flap*h*0.10), width:w*0.34,height:h*0.16), wp);
  }

  // ── FARMER (perspective-scaled, at bottom) ─────────────────────────────────
  void _drawFarmer(Canvas canvas, Size s) {
    final fs    = state.farmerScale;
    final playerY = s.height * kPlayerYFrac;
    // Farmer appears BELOW player — grows from very bottom of screen
    final farmerBaseY = s.height * (0.975 + fs * 0.015);
    final rw    = _roadW(farmerBaseY, s);
    final fw    = rw * fs * 0.55;
    final fh    = fw * 1.65;
    final t     = state.animT;
    final anger = state.farmerDanger;

    // Danger aura
    if (anger > 0.40) {
      final pulse = math.sin(t*7)*0.5+0.5;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(s.width/2, farmerBaseY - fh*0.3),
            width: fw*1.4, height: fh*0.85),
        Paint()..color=Colors.red.withOpacity(0.10*(anger-0.40)*2.5*pulse)
               ..maskFilter=const MaskFilter.blur(BlurStyle.normal,22));
    }

    final runC  = math.sin(t * (9.5 + anger*5));
    final lean  = 0.05 + anger * 0.10;
    final bobY  = math.sin(t*(9.5+anger*5)*2)*fh*0.012;

    canvas.save();
    canvas.translate(s.width/2, farmerBaseY - fh*0.5 + bobY);
    canvas.rotate(lean);

    // Farmer image
    if (farmer != null) {
      final src = Rect.fromLTWH(0,0,farmer!.width.toDouble(),farmer!.height.toDouble());
      canvas.drawImageRect(farmer!, src,
          Rect.fromCenter(center:Offset.zero, width:fw, height:fh),
          Paint()..filterQuality=FilterQuality.high);
    } else {
      // Fallback: draw a simple farmer shape
      _drawFallbackFarmer(canvas, fw, fh);
    }

    // Animated legs & arms on top
    _farmerLegs(canvas, fw, fh, t, anger);
    _farmerArms(canvas, fw, fh, t, anger);

    canvas.restore();

    // Emoji anger indicator
    if (anger > 0.65) {
      final pulse = math.sin(t*5)*3;
      _t(canvas, anger>0.88?'😡':'😤',
          s.width/2, farmerBaseY - fh*1.12 + pulse, 20, Colors.white, center:true);
    }
  }

  void _drawFallbackFarmer(Canvas canvas, double fw, double fh) {
    // Simple cartoon farmer
    canvas.drawOval(Rect.fromCenter(center:Offset(0,-fh*0.35), width:fw*0.5,height:fh*0.28),
        Paint()..color=const Color(0xFFFFCCAA)); // head
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(-fw*0.22,-fh*0.22,fw*0.44,fh*0.30), const Radius.circular(4)),
        Paint()..color=const Color(0xFF1976D2)); // overalls
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(-fw*0.22,-fh*0.26,fw*0.44,fh*0.09), const Radius.circular(3)),
        Paint()..color=const Color(0xFFEF5350)); // shirt
  }

  void _farmerLegs(Canvas canvas, double fw, double fh, double t, double anger) {
    final lp = Paint()..color=const Color(0xFF0D47A1)..strokeWidth=fw*0.10..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    final sp = Paint()..color=const Color(0xFF3E2723)..strokeWidth=fw*0.09..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    final cycle = t * (9.5 + anger*5);
    for (int i = 0; i < 2; i++) {
      final phase = i==0 ? cycle : cycle+math.pi;
      final hx = i==0 ? -fw*0.12 : fw*0.12;
      final hy = fh*0.24;
      final thigh = math.sin(phase)*0.55;
      final tLen  = fh*0.28;
      final kx = hx + math.sin(thigh)*tLen;
      final ky = hy + math.cos(thigh).abs()*tLen;
      final shin  = thigh - math.max(0, math.sin(phase))*0.72;
      final sLen  = fh*0.26;
      final ax = kx + math.sin(shin)*sLen;
      final ay = ky + math.cos(shin).abs()*sLen;
      canvas.drawLine(Offset(hx,hy), Offset(kx,ky), lp);
      canvas.drawLine(Offset(kx,ky), Offset(ax,ay), lp);
      // Boot
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(ax-fw*0.09, ay-fw*0.02, fw*0.20, fw*0.09),
          const Radius.circular(3)), sp);
    }
  }

  void _farmerArms(Canvas canvas, double fw, double fh, double t, double anger) {
    final ap = Paint()..color=const Color(0xFFEF5350)..strokeWidth=fw*0.09..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    final hp = Paint()..color=const Color(0xFFFFCCAA)..strokeWidth=fw*0.08..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    final cycle = t * (9.5 + anger*5);
    for (int i = 0; i < 2; i++) {
      final phase = i==0 ? cycle+math.pi : cycle; // opposite to legs
      final sx    = i==0 ? -fw*0.20 : fw*0.20;
      final sy    = -fh*0.10;
      final upper = math.sin(phase)*0.42;
      final uLen  = fh*0.22;
      final ex = sx + math.sin(upper)*uLen;
      final ey = sy + math.cos(upper).abs()*uLen;
      canvas.drawLine(Offset(sx,sy), Offset(ex,ey), ap);
      final fore = upper + math.sin(phase)*0.28;
      final fLen = fh*0.18;
      final hx = ex + math.sin(fore)*fLen;
      final hy2 = ey + math.cos(fore).abs()*fLen;
      canvas.drawLine(Offset(ex,ey), Offset(hx,hy2), hp);
      // Pitchfork in right arm (i==1)
      if (i==1) {
        canvas.save(); canvas.translate(hx, hy2); canvas.rotate(upper*0.8-0.35);
        final pp = Paint()..color=const Color(0xFF6D4C41)..strokeWidth=2.8..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
        final mp = Paint()..color=const Color(0xFF90A4AE)..strokeWidth=2.2..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
        canvas.drawLine(const Offset(0,0), Offset(0,-fh*0.38), pp);
        for (final dx in [-fw*0.04, 0.0, fw*0.04])
          canvas.drawLine(Offset(dx,-fh*0.38), Offset(dx,-fh*0.54), mp);
        canvas.restore();
      }
    }
  }

  // ── HUD ────────────────────────────────────────────────────────────────────
  void _drawHUD(Canvas canvas, Size s) {
    if (state.phase == GamePhase.menu) return;
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
    if(state.multiplier>1) _t(canvas,'✕${state.multiplier}',s.width/2,90,28,const Color(0xFF9C27B0),bold:true,center:true);

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

  void _badge(Canvas canvas,double x,double y,String icon,Color col,int frames,int total){
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,50,50),const Radius.circular(10)),
        Paint()..color=col.withOpacity(0.20));
    canvas.drawArc(Rect.fromLTWH(x+2,y+2,46,46),-math.pi/2,math.pi*2*(frames/total),
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

  // ── Helpers ─────────────────────────────────────────────────────────────────
  void _panel(Canvas c,double x,double y,double w,double h){
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,h),const Radius.circular(10)),
        Paint()..color=Colors.black.withOpacity(0.58));
  }
  void _t(Canvas c,String text,double x,double y,double fs,Color col,
      {bool bold=false,bool center=false}){
    final tp=TextPainter(text:TextSpan(text:text,style:TextStyle(color:col,fontSize:fs,
        fontWeight:bold?FontWeight.w900:FontWeight.normal,
        shadows:const[Shadow(blurRadius:2,color:Color(0x66000000))])),
        textDirection:TextDirection.ltr)..layout();
    tp.paint(c,center?Offset(x-tp.width/2,y-tp.height/2):Offset(x,y-tp.height));
  }
  String _fmt(int n)=>n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),(m)=>'${m[1]},');

  @override bool shouldRepaint(covariant _GP o)=>true;
}
