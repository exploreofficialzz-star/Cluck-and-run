// lib/game/game_widget.dart — vertical lane runner with real image assets
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

  // Decoded images
  ui.Image? _chickenImg, _farmerImg, _coinImg, _birdImg;
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _state  = GameState()..highScore = widget.savedHighScore;
    _engine = GameEngine(state: _state, onDied: widget.onDied,
        onCoinCollected: widget.onCoinCollected, onBonusBird: widget.onBonusBird,
        onJump: widget.onJump, onCluck: widget.onCluck);
    _loadImages();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)..forward();
  }

  Future<void> _loadImages() async {
    _chickenImg = await _loadImg(kImgChicken);
    _farmerImg  = await _loadImg(kImgFarmer);
    _coinImg    = await _loadImg(kImgCoin);
    _birdImg    = await _loadImg(kImgBonusBird);
    if (mounted) setState(() => _imagesLoaded = true);
  }

  Future<ui.Image> _loadImg(String asset) async {
    final data  = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
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
    if (_state.phase == GamePhase.menu) { startNewGame(); return; }
    if (_state.phase == GamePhase.playing) _engine.jump();
  }
  void _onPanStart(DragStartDetails d) => _dragStart = d.globalPosition;
  void _onPanEnd(DragEndDetails d) {
    if (_dragStart == null) return;
    final v = d.velocity.pixelsPerSecond;
    if (v.dx.abs() > v.dy.abs()) {
      if (v.dx < -180) _engine.swipeLeft(); else if (v.dx > 180) _engine.swipeRight();
    } else {
      if (v.dy > 260) _engine.slide(); else if (v.dy < -260) _engine.jump();
    }
    _dragStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTap, onPanStart: _onPanStart, onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: _GP(state: _state, engine: _engine,
            chicken: _chickenImg, farmer: _farmerImg,
            coin: _coinImg, bird: _birdImg),
        child: const SizedBox.expand(),
      ),
    );
  }

  @override
  void dispose() { _ticker.dispose(); super.dispose(); }
}

// ─────────────────────────────────────────────────────────────────────────────
class _GP extends CustomPainter {
  final GameState  state;
  final GameEngine engine;
  final ui.Image?  chicken, farmer, coin, bird;
  const _GP({required this.state, required this.engine,
    this.chicken, this.farmer, this.coin, this.bird});

  @override
  void paint(Canvas canvas, Size size) {
    _bg(canvas, size);
    _powerUps(canvas, size);
    _coins(canvas, size);
    _obstacles(canvas, size);
    _birds(canvas, size);
    _chickenDraw(canvas, size);
    _farmerDraw(canvas, size);
    _hud(canvas, size);
    if (state.phase == GamePhase.menu) _menuPrompt(canvas, size);
  }

  // ── Background ─────────────────────────────────────────────────────────────
  void _bg(Canvas canvas, Size size) {
    final sh = Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF5BA4CF), Color(0xFF81D4FA), Color(0xFF4CAF50)],
        stops: [0.0, 0.45, 1.0]).createShader(Rect.fromLTWH(0,0,size.width,size.height));
    canvas.drawRect(Rect.fromLTWH(0,0,size.width,size.height), sh);

    // Road
    final rw = size.width * 0.54;
    canvas.drawRect(Rect.fromLTWH((size.width-rw)/2, 0, rw, size.height),
        Paint()..color = const Color(0xFFC8A86B));
    // Grass sides
    canvas.drawRect(Rect.fromLTWH(0,0,(size.width-rw)/2,size.height), Paint()..color = const Color(0xFF4A8C2A));
    canvas.drawRect(Rect.fromLTWH((size.width+rw)/2,0,(size.width-rw)/2,size.height), Paint()..color = const Color(0xFF4A8C2A));

    // Perspective convergence
    final hy = size.height * 0.25;
    final vx = size.width  / 2;
    final persp = Paint()..color = const Color(0xFF9B7D47).withOpacity(0.3)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(vx, hy), Offset((size.width-rw)/2, size.height), persp);
    canvas.drawLine(Offset(vx, hy), Offset((size.width+rw)/2, size.height), persp);

    // Scrolling road dashes
    final total = 64.0; final dashLen = 36.0;
    final off = state.bgScrollY % total;
    final dp  = Paint()..color = Colors.white.withOpacity(0.45)..strokeWidth = 2.8..strokeCap = StrokeCap.round;
    double dy = -off;
    while (dy < size.height) {
      canvas.drawLine(Offset(vx, dy), Offset(vx, dy + dashLen), dp);
      canvas.drawLine(Offset((size.width-rw)/2 + rw*0.33, dy), Offset((size.width-rw)/2 + rw*0.33, dy+dashLen*0.6),
          Paint()..color = Colors.white.withOpacity(0.22)..strokeWidth = 1.5);
      canvas.drawLine(Offset((size.width-rw)/2 + rw*0.67, dy), Offset((size.width-rw)/2 + rw*0.67, dy+dashLen*0.6),
          Paint()..color = Colors.white.withOpacity(0.22)..strokeWidth = 1.5);
      dy += total;
    }

    // Scrolling side flora
    _sideFlora(canvas, size);
  }

  void _sideFlora(Canvas canvas, Size size) {
    const seeds = [0.05, 0.18, 0.31, 0.46, 0.59, 0.72, 0.85, 0.13, 0.67];
    final bgH = size.height * 1.6;
    for (int i = 0; i < seeds.length; i++) {
      final baseY = seeds[i] * bgH;
      final y     = (baseY - state.bgScrollY + bgH * 3) % bgH;
      if (y < 0 || y > size.height + 20) continue;
      final lx = size.width * (i.isEven ? 0.05 : 0.13);
      final rx = size.width - lx;
      final col = [kColYolk, const Color(0xFFFF6B6B), const Color(0xFF9B59B6),
                   const Color(0xFFFF8C00), const Color(0xFF00BCD4)][i % 5];
      final p = Paint()..color = col.withOpacity(0.8);
      canvas.drawCircle(Offset(lx, y), 5, p);
      canvas.drawCircle(Offset(rx, y), 5, p);
      final sp = Paint()..color = const Color(0xFF2E7D32)..strokeWidth = 1.8;
      canvas.drawLine(Offset(lx, y+2), Offset(lx, y+14), sp);
      canvas.drawLine(Offset(rx, y+2), Offset(rx, y+14), sp);
    }
  }

  // ── Coins ──────────────────────────────────────────────────────────────────
  void _coins(Canvas canvas, Size size) {
    for (final c in state.coinItems) {
      if (c.collected) continue;
      final cx  = engine.laneX(c.lane, size);
      final bob = math.sin(state.animT * 5 + c.lane * 1.2) * 4;
      _coinAt(canvas, cx, c.y + bob, size.width * 0.038);
    }
  }

  void _coinAt(Canvas canvas, double x, double y, double r) {
    canvas.drawCircle(Offset(x,y), r+5,
        Paint()..color = kColGold.withOpacity(0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal,6));
    canvas.drawCircle(Offset(x,y), r, Paint()..color = kColYolk);
    canvas.drawCircle(Offset(x,y), r*0.68, Paint()..color = kColGold);
    if (coin != null) {
      final src = Rect.fromLTWH(0,0,coin!.width.toDouble(),coin!.height.toDouble());
      canvas.drawImageRect(coin!, src, Rect.fromCenter(center: Offset(x,y), width:r*2, height:r*2), Paint());
    } else {
      final tp = TextPainter(text: const TextSpan(text:'\$',style:TextStyle(color:Color(0xFFB7410E),fontSize:11,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x-tp.width/2, y-tp.height/2));
    }
  }

  // ── Obstacles ──────────────────────────────────────────────────────────────
  void _obstacles(Canvas canvas, Size size) {
    for (final o in state.obstacles) {
      final ox = engine.laneX(o.lane, size);
      switch (o.type) {
        case ObstacleType.hayBale:     _hayBale(canvas, ox, o.y, size); break;
        case ObstacleType.fence:       _fence(canvas, ox, o.y, o.height, size); break;
        case ObstacleType.pumpkinPair: _pumpkin(canvas, ox, o.y, size); break;
        case ObstacleType.barrier:     _barrier(canvas, ox, o.y, o.height, size); break;
      }
    }
  }

  void _hayBale(Canvas canvas, double x, double y, Size size) {
    final r = size.width * 0.085;
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y+4), width: r*1.8, height: r*0.3),
        Paint()..color = Colors.black.withOpacity(0.18));
    canvas.drawCircle(Offset(x, y-r*0.6), r, Paint()..color = const Color(0xFFD4A017));
    final rp = Paint()..color = const Color(0xFFB8860B)..strokeWidth = 1.8..style = PaintingStyle.stroke;
    for (final sr in [0.38, 0.65, 0.88]) canvas.drawCircle(Offset(x,y-r*0.6), r*sr, rp);
    final sp = Paint()..color = const Color(0xFFC89A0A)..strokeWidth = 0.9..style = PaintingStyle.stroke;
    for (double i = -r*0.88; i <= r*0.88; i += r*0.18) {
      final h = math.sqrt(math.max(0, r*r - i*i));
      canvas.drawLine(Offset(x-h, y-r*0.6+i), Offset(x+h, y-r*0.6+i), sp);
    }
  }

  void _fence(Canvas canvas, double x, double y, double h, Size size) {
    final w = size.width * 0.13;
    final top = y - h;
    canvas.drawRect(Rect.fromLTWH(x-w*0.5, top, w*0.16, h), Paint()..color = const Color(0xFF8B6914));
    canvas.drawRect(Rect.fromLTWH(x+w*0.34, top, w*0.16, h), Paint()..color = const Color(0xFF8B6914));
    final rp = Paint()..color = const Color(0xFFA0522D);
    for (final ry in [top+5.0, top+h*0.36, top+h*0.64]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x-w*0.52,ry,w*1.04,9), const Radius.circular(2)), rp);
    }
    final tp = TextPainter(text: TextSpan(text:'↓ SLIDE',style:TextStyle(color:Colors.yellow.withOpacity(0.9),fontSize:11,fontWeight:FontWeight.bold)),textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x-tp.width/2, y-h*0.5-tp.height/2));
  }

  void _pumpkin(Canvas canvas, double x, double y, Size size) {
    final r = size.width * 0.072;
    for (final dx in [-r*0.52, 0.0, r*0.52]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x+dx, y-r), width: r*1.25, height: r*2.0),
          Paint()..color = dx==0 ? const Color(0xFFE64A19) : const Color(0xFFBF360C));
    }
    canvas.drawRect(Rect.fromLTWH(x-r*0.11, y-r*2.1, r*0.22, r*0.5), Paint()..color = const Color(0xFF2E7D32));
    final ep = Paint()..color = const Color(0xFF111111);
    for (final ex in [-r*0.26, r*0.26]) {
      canvas.drawPath(Path()..moveTo(x+ex,y-r*1.3)..lineTo(x+ex-r*0.18,y-r*0.9)..lineTo(x+ex+r*0.18,y-r*0.9)..close(), ep);
    }
  }

  void _barrier(Canvas canvas, double x, double y, double h, Size size) {
    final w = size.width * 0.14;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x-w/2, y-h, w, h), const Radius.circular(6)),
        Paint()..color = const Color(0xFFE53935));
    final sp = Paint()..color = Colors.white.withOpacity(0.5);
    for (double sy = y-h; sy < y; sy += 18) canvas.drawRect(Rect.fromLTWH(x-w/2, sy, w, 9), sp);
    final tp = TextPainter(text: const TextSpan(text:'⚠',style:TextStyle(fontSize:22)),textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x-tp.width/2, y-h/2-tp.height/2));
  }

  // ── Bonus birds ────────────────────────────────────────────────────────────
  void _birds(Canvas canvas, Size size) {
    for (final b in state.bonusBirds) {
      if (b.collected) continue;
      final flap = math.sin(state.animT * 9 + b.x * 0.01) * 6;
      canvas.drawCircle(Offset(b.x,b.y), 30, Paint()..color = kColYolk.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal,10));
      if (bird != null) {
        final src = Rect.fromLTWH(0,0,bird!.width.toDouble(),bird!.height.toDouble());
        canvas.drawImageRect(bird!, src, Rect.fromCenter(center: Offset(b.x,b.y+flap), width:60, height:44), Paint());
      } else {
        canvas.drawOval(Rect.fromCenter(center: Offset(b.x,b.y+flap), width:48, height:34), Paint()..color = kColYolk);
        canvas.drawCircle(Offset(b.x+(b.speed<0?-22:22),b.y-5), 14, Paint()..color = const Color(0xFFFFE082));
      }
      _coinAt(canvas, b.x, b.y-36, size.width*0.032);
      final tp = TextPainter(text: TextSpan(text:'+${b.coins}',style: const TextStyle(color:kColYolk,fontSize:11,fontWeight:FontWeight.w900)),textDirection:TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(b.x-tp.width/2, b.y-54));
    }
  }

  // ── Power-ups ──────────────────────────────────────────────────────────────
  void _powerUps(Canvas canvas, Size size) {
    for (final p in state.powerUps) {
      if (p.collected) continue;
      final px  = engine.laneX(p.lane, size);
      final col = p.type==PowerUpType.magnet ? const Color(0xFF2196F3)
                : p.type==PowerUpType.shield  ? const Color(0xFF4CAF50)
                                               : const Color(0xFF9C27B0);
      canvas.drawCircle(Offset(px,p.y), 28, Paint()..color = col.withOpacity(0.28)..maskFilter = const MaskFilter.blur(BlurStyle.normal,10));
      canvas.drawCircle(Offset(px,p.y), 22, Paint()..color = col.withOpacity(0.9));
      final icon = p.type==PowerUpType.magnet ? '🧲' : p.type==PowerUpType.shield ? '🛡' : '✕2';
      final tp = TextPainter(text: TextSpan(text:icon,style: const TextStyle(fontSize:17)),textDirection:TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(px-tp.width/2, p.y-tp.height/2));
    }
  }

  // ── Chicken ────────────────────────────────────────────────────────────────
  void _chickenDraw(Canvas canvas, Size size) {
    final cx = engine.currentPlayerX(size);
    final cy = size.height * 0.68 - state.playerYOffset;
    final cw = size.width  * 0.22;
    final ch = state.isSliding ? size.height * 0.08 : size.height * 0.15;

    if (state.isInvincible && (state.animFrame ~/ 4) % 2 == 1) return;

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy+ch*0.55), width: cw*0.85, height: ch*0.16),
        Paint()..color = Colors.black.withOpacity(0.20));

    if (state.shieldActive) {
      canvas.drawCircle(Offset(cx, cy-ch*0.2), math.max(cw,ch)*0.72,
          Paint()..color = const Color(0xFF4CAF50).withOpacity(0.22)
                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal,14));
    }

    final runC = math.sin(state.animT * 10.5);
    final sx = state.isSliding ? 1.38 : (1.0 + runC * 0.04);
    final sy = state.isJumping ? 1.10 : (1.0 - runC.abs() * 0.03);

    canvas.save();
    canvas.translate(cx, cy - ch * 0.5);
    canvas.scale(sx, sy);

    if (chicken != null) {
      final src = Rect.fromLTWH(0,0,chicken!.width.toDouble(),chicken!.height.toDouble());
      canvas.drawImageRect(chicken!, src,
          Rect.fromCenter(center: Offset(0,0), width: cw, height: ch), Paint());
    } else {
      // Fallback drawn chicken
      canvas.drawOval(Rect.fromCenter(center: const Offset(0,0), width: cw, height: ch),
          Paint()..color = const Color(0xFFD4780A));
    }

    if (!state.isSliding) _chickenLegs(canvas, cw, ch);
    canvas.restore();
  }

  void _chickenLegs(Canvas canvas, double w, double h) {
    final lp = Paint()..color = const Color(0xFFFF8F00)..strokeWidth = 3.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final cycle = state.animT * 10.5;
    for (int i = 0; i < 2; i++) {
      final phase = i == 0 ? cycle : cycle + math.pi;
      final lx = i == 0 ? -w * 0.14 : w * 0.14;
      final swing = math.sin(phase);
      final kx  = lx + swing * w * 0.12;
      final ky  = h * 0.36 + h * 0.18;
      final fx  = kx + swing * w * 0.10;
      final fy  = ky + math.sin(phase * 2).abs() * h * 0.16;
      canvas.drawLine(Offset(lx, h*0.3), Offset(kx, ky), lp);
      canvas.drawLine(Offset(kx, ky), Offset(fx, fy), lp);
      canvas.drawLine(Offset(fx,fy), Offset(fx-w*0.08, fy+h*0.06), lp..strokeWidth=2.5);
      canvas.drawLine(Offset(fx,fy), Offset(fx+w*0.06, fy+h*0.06), lp..strokeWidth=2.5);
    }
  }

  // ── Farmer ─────────────────────────────────────────────────────────────────
  void _farmerDraw(Canvas canvas, Size size) {
    final fs = state.farmerScale;
    final fw = size.width  * fs * 0.42;
    final fh = size.height * fs * 0.30;
    final fx = size.width  * 0.50;
    final fy = size.height * 0.97;
    final runC = math.sin(state.animT * 9.5);

    if (state.farmerDanger > 0.5) {
      final gr = (state.farmerDanger - 0.5) * 2;
      canvas.drawCircle(Offset(fx, fy - fh*0.5), math.max(fw,fh)*0.6,
          Paint()..color = Colors.red.withOpacity(0.15 * gr)
                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal,22));
    }

    canvas.save();
    canvas.translate(fx, fy - fh*0.5);
    canvas.scale(1.0 + runC*0.015, 1.0 - runC.abs()*0.012);

    if (farmer != null) {
      final src = Rect.fromLTWH(0,0,farmer!.width.toDouble(),farmer!.height.toDouble());
      canvas.drawImageRect(farmer!, src,
          Rect.fromCenter(center: Offset(0,0), width: fw, height: fh), Paint());
    } else {
      canvas.drawOval(Rect.fromCenter(center: const Offset(0,0), width: fw, height: fh),
          Paint()..color = const Color(0xFF1976D2));
    }

    _farmerLegs(canvas, fw, fh);
    canvas.restore();
  }

  void _farmerLegs(Canvas canvas, double w, double h) {
    final lp = Paint()..color = const Color(0xFF0D47A1)..strokeWidth = 5.0..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final sp = Paint()..color = const Color(0xFF3E2723)..strokeWidth = 4.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final cycle = state.animT * (9.5 + state.farmerDanger * 3.5);
    for (int i = 0; i < 2; i++) {
      final phase = i == 0 ? cycle : cycle + math.pi;
      final lx = i == 0 ? -w * 0.11 : w * 0.11;
      final swing = math.sin(phase);
      final kx = lx + swing * w * 0.10;
      final ky = h * 0.30;
      final fx = kx + swing * w * 0.08;
      final fy = ky + math.sin(phase*2).abs() * h * 0.18;
      canvas.drawLine(Offset(lx, h*0.22), Offset(kx, ky), lp);
      canvas.drawLine(Offset(kx, ky), Offset(fx, fy), lp);
      // Boot
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(fx-w*0.08, fy, w*0.18, h*0.08), const Radius.circular(3)), sp);
    }
  }

  // ── HUD ────────────────────────────────────────────────────────────────────
  void _hud(Canvas canvas, Size size) {
    if (state.phase == GamePhase.menu) return;
    _panel(canvas, 12, 12, 170, 56);
    _t(canvas, 'SCORE', 24, 30, 11, Colors.white54);
    _t(canvas, _fmt(state.score.toInt()), 24, 52, 22, kColYolk, bold: true);
    _panel(canvas, 192, 12, 130, 56);
    _t(canvas, '💰 COINS', 204, 30, 11, Colors.white54);
    _t(canvas, '${state.coins}', 204, 52, 22, kColYolk, bold: true);
    _panel(canvas, size.width-178, 12, 166, 56);
    _t(canvas, '🏆 BEST', size.width-166, 30, 11, Colors.white54);
    _t(canvas, _fmt(state.highScore), size.width-166, 52, 18, const Color(0xFF69F0AE), bold: true);

    double px = 12;
    if (state.magnetActive) { _badge(canvas, px, 78, '🧲', const Color(0xFF2196F3), state.magnetFrames, 480); px += 58; }
    if (state.shieldActive) { _badge(canvas, px, 78, '🛡',  const Color(0xFF4CAF50), state.shieldFrames, 360); px += 58; }
    if (state.x2Active)     { _badge(canvas, px, 78, '✕2',  const Color(0xFF9C27B0), state.x2Frames, 600); px += 58; }
    if (state.multiplier > 1) _t(canvas, '✕${state.multiplier}', size.width/2-20, 90, 28, const Color(0xFF9C27B0), bold: true);

    final d = state.farmerDanger;
    if (d > 0.15) {
      final mw = size.width * 0.58; final mx = (size.width-mw)/2; final my = size.height - 58.0;
      final col = Color.lerp(kColBlaze, kColRed, d)!;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(mx,my,mw,14), const Radius.circular(7)),
          Paint()..color = Colors.black.withOpacity(0.38));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(mx,my,mw*d,14), const Radius.circular(7)),
          Paint()..color = col);
      _t(canvas, '⚠ FARMER CLOSE!', mx+4, my-4, 11, col, bold: true);
    }
  }

  void _badge(Canvas canvas, double x, double y, String icon, Color col, int frames, int total) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,50,50), const Radius.circular(10)),
        Paint()..color = col.withOpacity(0.20));
    canvas.drawArc(Rect.fromLTWH(x+2,y+2,46,46), -math.pi/2, math.pi*2*(frames/total),
        false, Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = 3);
    final tp = TextPainter(text:TextSpan(text:icon,style: const TextStyle(fontSize:20)),textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x+25-tp.width/2, y+25-tp.height/2));
  }

  void _menuPrompt(Canvas canvas, Size size) {
    final cx = size.width/2; final cy = size.height*0.40;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx,cy), width: 330, height: 160), const Radius.circular(22)),
        Paint()..color = Colors.black.withOpacity(0.76));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx,cy), width: 330, height: 160), const Radius.circular(22)),
        Paint()..color = kColYolk.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 2.2);
    _t(canvas, '🐔  CLUCK & RUN!', cx, cy-42, 26, kColYolk, bold: true, center: true);
    _t(canvas, 'TAP  to  Start', cx, cy-6, 18, Colors.white, center: true);
    _t(canvas, '← → Lanes  |  ↑ Jump  |  ↓ Slide', cx, cy+22, 11, Colors.white60, center: true);
    if (state.highScore > 0) _t(canvas, '🏆 Best: ${_fmt(state.highScore)}', cx, cy+50, 14, kColGold, center: true);
  }

  void _panel(Canvas canvas, double x, double y, double w, double h) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,h), const Radius.circular(10)),
        Paint()..color = Colors.black.withOpacity(0.54));
  }

  void _t(Canvas canvas, String text, double x, double y, double fs, Color col,
      {bool bold=false, bool center=false}) {
    final tp = TextPainter(text: TextSpan(text:text,
        style:TextStyle(color:col,fontSize:fs,fontWeight:bold?FontWeight.w900:FontWeight.normal)),
        textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, center ? Offset(x-tp.width/2,y-tp.height/2) : Offset(x,y-tp.height));
  }

  String _fmt(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  bool shouldRepaint(covariant _GP old) => true;
}
