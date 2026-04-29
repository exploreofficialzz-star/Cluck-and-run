// lib/game/game_widget.dart
// Vertical lane runner — proper transparent sprites, realistic physics animations
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

class GameWidgetState extends State<GameWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  late GameState  _state;
  late GameEngine _engine;
  double _lastTime = 0;
  Offset? _dragStart;

  ui.Image? _chickenImg, _farmerImg, _coinImg, _roadBgImg;
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

  Future<ui.Image> _load(String asset) async {
    final d = await rootBundle.load(asset);
    final c = await ui.instantiateImageCodec(d.buffer.asUint8List());
    return (await c.getNextFrame()).image;
  }

  Future<void> _loadAssets() async {
    _chickenImg = await _load('assets/images/chicken_sprite.png');
    _farmerImg  = await _load('assets/images/farmer_nobg.png');
    _coinImg    = await _load('assets/images/coin.png');
    _roadBgImg  = await _load('assets/images/road_bg.jpg');
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
      if (v.dx < -180) _engine.swipeLeft();
      else if (v.dx > 180) _engine.swipeRight();
    } else {
      if (v.dy > 260) _engine.slide();
      else if (v.dy < -260) _engine.jump();
    }
    _dragStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTap, onPanStart: _onPanStart, onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: _GamePainter(state: _state, engine: _engine,
            chicken: _chickenImg, farmer: _farmerImg,
            coin: _coinImg, roadBg: _roadBgImg),
        child: const SizedBox.expand(),
      ),
    );
  }
  @override void dispose() { _ticker.dispose(); super.dispose(); }
}

// ─────────────────────────────────────────────────────────────────────────────
class _GamePainter extends CustomPainter {
  final GameState  state;
  final GameEngine engine;
  final ui.Image?  chicken, farmer, coin, roadBg;
  const _GamePainter({required this.state, required this.engine,
    this.chicken, this.farmer, this.coin, this.roadBg});

  @override
  void paint(Canvas canvas, Size size) {
    _drawRoad(canvas, size);
    _drawSideDecor(canvas, size);
    _drawPowerUps(canvas, size);
    _drawCoins(canvas, size);
    _drawObstacles(canvas, size);
    _drawBonusBirds(canvas, size);
    _drawChicken(canvas, size);
    _drawFarmer(canvas, size);
    _drawHUD(canvas, size);
    if (state.phase == GamePhase.menu) _drawMenu(canvas, size);
  }

  // ── ROAD ───────────────────────────────────────────────────────────────────
  void _drawRoad(Canvas canvas, Size size) {
    final W = size.width, H = size.height;
    final hY = H * 0.26;   // horizon Y
    final cx = W / 2;

    // Draw road background image if loaded
    if (roadBg != null) {
      final srcW = roadBg!.width.toDouble();
      final srcH = roadBg!.height.toDouble();
      // Scroll vertically
      final scrollFrac = (state.bgScrollY / H) % 1.0;
      final srcY = scrollFrac * srcH * 0.5;
      final src  = Rect.fromLTWH(0, srcY, srcW, srcH - srcY);
      final dst  = Rect.fromLTWH(0, 0, W, H);
      canvas.drawImageRect(roadBg!, src, dst, Paint()..filterQuality = FilterQuality.medium);
      // Overlay second copy seamlessly below
      final src2 = Rect.fromLTWH(0, 0, srcW, srcY + 1);
      final dst2 = Rect.fromLTWH(0, H * (1-scrollFrac*0.5), W, H * scrollFrac * 0.5);
      if (srcY > 0) canvas.drawImageRect(roadBg!, src2, dst2, Paint()..filterQuality = FilterQuality.medium);
      return;
    }

    // Fallback drawn road
    // Sky
    canvas.drawRect(Rect.fromLTWH(0,0,W,hY),
        Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [const Color(0xFF87CEEB), const Color(0xFF5BA4CF)]).createShader(Rect.fromLTWH(0,0,W,hY)));

    // Grass
    canvas.drawRect(Rect.fromLTWH(0,hY,W,H-hY), Paint()..color = const Color(0xFF3A7D1E));

    // Road trapezoid
    final roadTop = W * 0.16;
    final roadBot = W * 0.90;
    final path = Path()
      ..moveTo(cx - roadTop/2, hY)..lineTo(cx + roadTop/2, hY)
      ..lineTo(cx + roadBot/2, H)..lineTo(cx - roadBot/2, H)..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF6B6B6B));

    // Asphalt noise
    final noisePaint = Paint()..color = Colors.black.withOpacity(0.04);
    for (double y = hY; y < H; y += 8) {
      final lx = _roadLX(y, size); final rx = _roadRX(y, size);
      canvas.drawRect(Rect.fromLTWH(lx, y, rx-lx, 4), noisePaint);
    }

    // Road edges
    _drawEdges(canvas, size);
    _drawLaneMarks(canvas, size);
  }

  double _roadLX(double y, Size size) {
    final t = ((y - size.height*0.26) / (size.height*0.74)).clamp(0.0,1.0);
    return size.width/2 - (size.width*0.08 + size.width*0.37*t);
  }
  double _roadRX(double y, Size size) {
    final t = ((y - size.height*0.26) / (size.height*0.74)).clamp(0.0,1.0);
    return size.width/2 + (size.width*0.08 + size.width*0.37*t);
  }

  void _drawEdges(Canvas canvas, Size size) {
    final ep = Paint()..color = Colors.white.withOpacity(0.75)..strokeWidth = 2;
    for (double y = size.height*0.26; y < size.height; y += 2) {
      canvas.drawLine(Offset(_roadLX(y,size),y), Offset(_roadLX(y,size)+2,y), ep);
      canvas.drawLine(Offset(_roadRX(y,size)-2,y), Offset(_roadRX(y,size),y), ep);
    }
  }

  void _drawLaneMarks(Canvas canvas, Size size) {
    for (final frac in [0.335, 0.50, 0.665]) {
      final dp = Paint()
        ..color = frac==0.50 ? const Color(0xFFFFD700).withOpacity(0.8) : Colors.white.withOpacity(0.5)
        ..strokeWidth = 2.5..strokeCap = StrokeCap.round;
      final off = state.bgScrollY % 80;
      double y  = size.height*0.26 - off;
      bool dash = true;
      while (y < size.height) {
        final t    = ((y-size.height*0.26)/(size.height*0.74)).clamp(0.0,1.0);
        final lx   = _roadLX(y,size); final rx = _roadRX(y,size);
        final x    = lx + (rx-lx)*frac;
        final dlen = 12 + t*52;
        final gap  = 10 + t*36;
        if (dash) canvas.drawLine(Offset(x,y), Offset(x, math.min(y+dlen,size.height)), dp..strokeWidth = (1+t*4));
        y += dlen+gap; dash = !dash;
      }
    }
  }

  void _drawSideDecor(Canvas canvas, Size size) {
    if (roadBg != null) return; // bg image handles this
    final bgH = size.height * 1.6;
    const seeds = [0.06, 0.19, 0.33, 0.48, 0.62, 0.76, 0.90, 0.14, 0.55];
    for (int i = 0; i < seeds.length; i++) {
      final baseY = seeds[i] * bgH;
      final y     = (baseY - state.bgScrollY + bgH * 3) % bgH;
      if (y < size.height*0.26 || y > size.height+20) continue;
      final lx = _roadLX(y, size) * (i.isEven ? 0.42 : 0.72);
      final rx = size.width - lx;
      final cols = [const Color(0xFFFFD700), const Color(0xFFFF6B6B),
                    const Color(0xFF9B59B6), const Color(0xFFFF8C00)];
      final p = Paint()..color = cols[i%cols.length].withOpacity(0.82);
      canvas.drawCircle(Offset(lx, y), 5, p);
      canvas.drawCircle(Offset(rx, y), 5, p);
      canvas.drawLine(Offset(lx,y+2), Offset(lx,y+14),
          Paint()..color = const Color(0xFF2E7D32)..strokeWidth = 2);
      canvas.drawLine(Offset(rx,y+2), Offset(rx,y+14),
          Paint()..color = const Color(0xFF2E7D32)..strokeWidth = 2);
    }
  }

  // ── OBSTACLES ──────────────────────────────────────────────────────────────
  void _drawObstacles(Canvas canvas, Size size) {
    for (final o in state.obstacles) {
      final ox = engine.laneX(o.lane, size);
      switch (o.type) {
        case ObstacleType.hayBale:     _hayBale(canvas, ox, o.y, size);           break;
        case ObstacleType.fence:       _fence(canvas, ox, o.y, o.height, size);   break;
        case ObstacleType.pumpkinPair: _pumpkin(canvas, ox, o.y, size);           break;
        case ObstacleType.barrier:     _barrier(canvas, ox, o.y, o.height, size); break;
      }
    }
  }

  void _hayBale(Canvas canvas, double x, double y, Size size) {
    final r = size.width * 0.072;
    canvas.drawOval(Rect.fromCenter(center: Offset(x,y+4), width:r*1.9,height:r*0.28),
        Paint()..color = Colors.black.withOpacity(0.22));
    // Hay body
    final hayP = Paint()..color = const Color(0xFFD4A017);
    canvas.drawCircle(Offset(x,y-r*0.5), r, hayP);
    canvas.drawOval(Rect.fromCenter(center:Offset(x,y-r*0.5),width:r*2.1,height:r*1.6), hayP);
    // Rope rings
    final rp = Paint()..color=const Color(0xFFB8860B)..strokeWidth=2.2..style=PaintingStyle.stroke;
    for (final sr in [0.42,0.68,0.88]) canvas.drawCircle(Offset(x,y-r*0.5),r*sr,rp);
    // Straw
    final sp = Paint()..color=const Color(0xFFC89A0A)..strokeWidth=1.1..style=PaintingStyle.stroke;
    for (double i=-r*0.85; i<=r*0.85; i+=r*0.16) {
      final h = math.sqrt(math.max(0,r*r-i*i));
      canvas.drawLine(Offset(x-h,y-r*0.5+i),Offset(x+h,y-r*0.5+i),sp);
    }
    // JUMP hint
    _hint(canvas, x, y-r*1.5, '↑ JUMP');
  }

  void _fence(Canvas canvas, double x, double y, double h, Size size) {
    final w = size.width*0.12; final top = y-h;
    final pp = Paint()..color=const Color(0xFF8B6914);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x-w*0.5,top,w*0.15,h),const Radius.circular(2)),pp);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+w*0.35,top,w*0.15,h),const Radius.circular(2)),pp);
    final rp = Paint()..color=const Color(0xFFA0522D);
    for (final ry in [top+5.0, top+h*0.35, top+h*0.64]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x-w*0.52,ry,w*1.04,9),const Radius.circular(2)),rp);
    }
    _hint(canvas, x, y-h-8, '↓ SLIDE');
  }

  void _pumpkin(Canvas canvas, double x, double y, Size size) {
    final r = size.width*0.068;
    for (final dx in [-r*0.52,0.0,r*0.52]) {
      canvas.drawOval(Rect.fromCenter(center:Offset(x+dx,y-r),width:r*1.22,height:r*1.95),
          Paint()..color=dx==0?const Color(0xFFE64A19):const Color(0xFFBF360C));
    }
    canvas.drawRect(Rect.fromLTWH(x-r*0.1,y-r*2.05,r*0.2,r*0.45),Paint()..color=const Color(0xFF2E7D32));
    final ep=Paint()..color=const Color(0xFF111111);
    for (final ex in [-r*0.24,r*0.24]) {
      canvas.drawPath(Path()..moveTo(x+ex,y-r*1.28)..lineTo(x+ex-r*0.17,y-r*0.9)..lineTo(x+ex+r*0.17,y-r*0.9)..close(),ep);
    }
    _hint(canvas, x, y-r*2.3, '↑ JUMP');
  }

  void _barrier(Canvas canvas, double x, double y, double h, Size size) {
    final w = size.width*0.13;
    // Red/white striped barrier
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x-w/2,y-h,w,h),const Radius.circular(5)),
        Paint()..color=const Color(0xFFE53935));
    final sp=Paint()..color=Colors.white.withOpacity(0.55);
    for (double sy=y-h; sy<y; sy+=18) canvas.drawRect(Rect.fromLTWH(x-w/2,sy,w,9),sp);
    _hint(canvas, x, y-h-8, '↑↑ JUMP');
  }

  void _hint(Canvas canvas, double x, double y, String text) {
    final tp=TextPainter(text:TextSpan(text:text,style:TextStyle(
        color:Colors.yellow.withOpacity(0.92),fontSize:11,fontWeight:FontWeight.bold,
        shadows:[const Shadow(blurRadius:3,color:Colors.black)])),
        textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas,Offset(x-tp.width/2,y-tp.height/2));
  }

  // ── COINS ───────────────────────────────────────────────────────────────────
  void _drawCoins(Canvas canvas, Size size) {
    for (final c in state.coinItems) {
      if (c.collected) continue;
      final cx  = engine.laneX(c.lane, size);
      final bob = math.sin(state.animT*5+c.lane*1.2)*3;
      _coinAt(canvas, cx, c.y+bob, size.width*0.036);
    }
  }

  void _coinAt(Canvas canvas, double x, double y, double r) {
    // Glow
    canvas.drawCircle(Offset(x,y),r+5,Paint()..color=kColGold.withOpacity(0.28)..maskFilter=const MaskFilter.blur(BlurStyle.normal,6));
    if (coin!=null) {
      canvas.drawImageRect(coin!,
          Rect.fromLTWH(0,0,coin!.width.toDouble(),coin!.height.toDouble()),
          Rect.fromCenter(center:Offset(x,y),width:r*2,height:r*2),Paint()..filterQuality=FilterQuality.medium);
    } else {
      canvas.drawCircle(Offset(x,y),r,Paint()..color=kColYolk);
      canvas.drawCircle(Offset(x,y),r*0.68,Paint()..color=kColGold);
    }
  }

  // ── BONUS BIRDS ─────────────────────────────────────────────────────────────
  void _drawBonusBirds(Canvas canvas, Size size) {
    for (final b in state.bonusBirds) {
      if (b.collected) continue;
      final flap = math.sin(state.animT*9+b.x*0.01)*7;
      canvas.drawCircle(Offset(b.x,b.y),32,Paint()..color=kColYolk.withOpacity(0.2)..maskFilter=const MaskFilter.blur(BlurStyle.normal,10));
      // Body
      canvas.drawOval(Rect.fromCenter(center:Offset(b.x,b.y),width:50,height:36),Paint()..color=const Color(0xFFFFE082));
      // Wings flapping
      final wc = const Color(0xFFFFC107).withOpacity(0.88);
      canvas.drawOval(Rect.fromCenter(center:Offset(b.x,b.y-10+flap),width:38,height:14),Paint()..color=wc);
      canvas.drawOval(Rect.fromCenter(center:Offset(b.x,b.y+10-flap),width:32,height:10),Paint()..color=wc);
      // Head
      canvas.drawCircle(Offset(b.x+(b.speed<0?-24:24),b.y-5),14,Paint()..color=const Color(0xFFFFD54F));
      // Eye
      canvas.drawCircle(Offset(b.x+(b.speed<0?-28:28),b.y-8),3.5,Paint()..color=Colors.black);
      canvas.drawCircle(Offset(b.x+(b.speed<0?-27:29),b.y-9),1.2,Paint()..color=Colors.white);
      // Beak
      final bx=b.x+(b.speed<0?-36:36); final by=b.y-4;
      canvas.drawPath(Path()..moveTo(bx,by-3)..lineTo(bx+(b.speed<0?-10:10),by)..lineTo(bx,by+3)..close(),
          Paint()..color=const Color(0xFFFF8F00));
      // Red comb
      canvas.drawCircle(Offset(b.x+(b.speed<0?-24:24),b.y-18),4,Paint()..color=kColRed);
      _coinAt(canvas, b.x, b.y-38, size.width*0.030);
      _t(canvas,'+${b.coins}',b.x,b.y-58,10,kColYolk,bold:true,center:true);
    }
  }

  // ── POWER-UPS ───────────────────────────────────────────────────────────────
  void _drawPowerUps(Canvas canvas, Size size) {
    for (final p in state.powerUps) {
      if (p.collected) continue;
      final px=engine.laneX(p.lane,size);
      final col=p.type==PowerUpType.magnet?const Color(0xFF2196F3)
               :p.type==PowerUpType.shield?const Color(0xFF4CAF50)
                                           :const Color(0xFF9C27B0);
      canvas.drawCircle(Offset(px,p.y),30,Paint()..color=col.withOpacity(0.28)..maskFilter=const MaskFilter.blur(BlurStyle.normal,10));
      canvas.drawCircle(Offset(px,p.y),23,Paint()..color=col.withOpacity(0.92));
      final icon=p.type==PowerUpType.magnet?'🧲':p.type==PowerUpType.shield?'🛡':'✕2';
      _t(canvas,icon,px,p.y+9,19,Colors.white,center:true);
    }
  }

  // ── CHICKEN (realistic running fowl) ───────────────────────────────────────
  void _drawChicken(Canvas canvas, Size size) {
    final cx  = engine.currentPlayerX(size);
    final cy  = size.height*0.68 - state.playerYOffset;
    final cw  = size.width*0.21;
    final ch  = state.isSliding ? size.height*0.075 : size.height*0.14;
    final t   = state.animT;

    if (state.isInvincible && (state.animFrame~/4)%2==1) return;

    // Ground shadow
    final shadowScale = state.isJumping ? (0.5 + state.playerYOffset/200).clamp(0.2,0.8) : 0.9;
    canvas.drawOval(
      Rect.fromCenter(center:Offset(cx, size.height*0.68+ch*0.1),
          width:cw*0.85*shadowScale, height:ch*0.12*shadowScale),
      Paint()..color=Colors.black.withOpacity(0.22*shadowScale));

    if (state.shieldActive) {
      canvas.drawCircle(Offset(cx,cy-ch*0.2),math.max(cw,ch)*0.7,
          Paint()..color=const Color(0xFF4CAF50).withOpacity(0.22)..maskFilter=const MaskFilter.blur(BlurStyle.normal,14));
    }

    // Squash/stretch based on running cycle
    final runCycle = math.sin(t*11.0);
    final sx = state.isSliding ? 1.35 : (state.isJumping ? 0.88 : 1.0+runCycle*0.04);
    final sy = state.isSliding ? 0.55 : (state.isJumping ? 1.14 : 1.0-runCycle.abs()*0.03);

    canvas.save();
    canvas.translate(cx, cy-ch*0.5);
    canvas.scale(sx, sy);

    // Draw chicken sprite (transparent background already)
    if (chicken!=null) {
      final p = Paint()..filterQuality=FilterQuality.high;
      final src = Rect.fromLTWH(0,0,chicken!.width.toDouble(),chicken!.height.toDouble());
      final dst = Rect.fromCenter(center:Offset(0,0),width:cw,height:ch);
      canvas.drawImageRect(chicken!, src, dst, p);
    } else {
      // Fallback white circle
      canvas.drawCircle(Offset.zero, cw/2, Paint()..color=Colors.white);
    }

    // Animated legs drawn BELOW sprite for realism
    if (!state.isSliding) _drawChickenLegs(canvas, cw, ch, t);
    if (state.isJumping)  _drawWingsSpread(canvas, cw, ch, t);

    canvas.restore();
  }

  void _drawChickenLegs(Canvas canvas, double w, double h, double t) {
    // Chicken has high-stepping gait: legs lift high, fast peck-style
    final cycle = t*11.0;
    final lp = Paint()..color=const Color(0xFFE8A020)..strokeWidth=3.2..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    final tp2 = Paint()..color=const Color(0xFFD4890E)..strokeWidth=2.2..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;

    for (int i=0; i<2; i++) {
      final phase = i==0 ? cycle : cycle+math.pi;
      final lx    = i==0 ? -w*0.12 : w*0.10;
      final liftH = math.max(0, math.sin(phase));       // 0 to 1 (lift phase)
      final fwdX  = math.sin(phase) * w*0.11;
      final legMidY = h*0.38;
      final legBotY = h*0.48 - liftH*h*0.18;            // foot lifts when running
      final footX   = lx + fwdX;
      final footY   = legBotY + h*0.14*(1-liftH*0.6);

      // Thigh
      canvas.drawLine(Offset(lx, h*0.30), Offset(lx+fwdX*0.4, legMidY), lp);
      // Shin
      canvas.drawLine(Offset(lx+fwdX*0.4, legMidY), Offset(footX, footY), lp);
      // Three toes (spread when grounded, tucked when lifted)
      final spread = 1.0 - liftH*0.6;
      if (spread > 0.3) {
        canvas.drawLine(Offset(footX,footY), Offset(footX-w*0.09*spread, footY+h*0.055), tp2);
        canvas.drawLine(Offset(footX,footY), Offset(footX+w*0.07*spread, footY+h*0.055), tp2);
        canvas.drawLine(Offset(footX,footY), Offset(footX+w*0.01,        footY+h*0.07),  tp2);
        canvas.drawLine(Offset(footX,footY), Offset(footX-w*0.05*spread, footY-h*0.02),  tp2); // back toe
      }
    }
  }

  void _drawWingsSpread(Canvas canvas, double w, double h, double t) {
    // Wings spread during jump — flapping
    final flap = math.sin(t*14)*0.3+0.2;
    final wp   = Paint()..color=Colors.white.withOpacity(0.75);
    canvas.drawOval(Rect.fromCenter(center:Offset(-w*0.28, -h*0.1-flap*h*0.08), width:w*0.36, height:h*0.18), wp);
    canvas.drawOval(Rect.fromCenter(center:Offset( w*0.20, -h*0.1-flap*h*0.08), width:w*0.32, height:h*0.16), wp);
  }

  // ── FARMER (realistic human running) ───────────────────────────────────────
  void _drawFarmer(Canvas canvas, Size size) {
    final fs  = state.farmerScale;
    final fw  = size.width  * fs * 0.38;
    final fh  = size.height * fs * 0.26;
    final fx  = size.width  * 0.50;
    final fy  = size.height * 0.975;
    final t   = state.animT;
    final anger = state.farmerDanger;

    // Danger pulsing red aura
    if (anger > 0.45) {
      final pulse = math.sin(t*8)*.5+.5;
      canvas.drawCircle(Offset(fx,fy-fh*0.5), math.max(fw,fh)*0.65,
          Paint()..color=Colors.red.withOpacity(0.12*(anger-0.45)*2*pulse)
                 ..maskFilter=const MaskFilter.blur(BlurStyle.normal,24));
    }

    // Human running cycle: realistic arm + leg swing
    final runSpeed = 9.5 + anger*4.0;
    final cycle    = t * runSpeed;

    canvas.save();
    canvas.translate(fx, fy-fh*0.5);

    // ── Body bob / forward lean ──
    final bob  = math.sin(cycle*2)*fh*0.015;
    final lean = 0.06 + anger*0.08;   // leans more when angry
    canvas.translate(0, bob);
    canvas.rotate(lean);

    // Draw farmer image (transparent background)
    if (farmer!=null) {
      final p   = Paint()..filterQuality=FilterQuality.high;
      final src = Rect.fromLTWH(0,0,farmer!.width.toDouble(),farmer!.height.toDouble());
      final dst = Rect.fromCenter(center:Offset(0,0),width:fw,height:fh);
      canvas.drawImageRect(farmer!, src, dst, p);
    } else {
      canvas.drawOval(Rect.fromCenter(center:Offset.zero,width:fw,height:fh),
          Paint()..color=const Color(0xFF1976D2));
    }

    // ── Animated legs over image ──
    _drawFarmerLegs(canvas, fw, fh, cycle, anger);
    // ── Animated arms ──
    _drawFarmerArms(canvas, fw, fh, cycle, anger);

    canvas.restore();

    // Angry expression indicator above farmer
    if (anger > 0.6) {
      final pulse = (math.sin(t*6)*0.5+0.5);
      _t(canvas, anger>0.85?'😡':'😤', fx, fy-fh*1.08-pulse*4, 20, Colors.white, center:true);
    }
  }

  void _drawFarmerLegs(Canvas canvas, double w, double h, double cycle, double anger) {
    // Realistic human gait: two legs with hip, knee, ankle
    final legP = Paint()..color=const Color(0xFF0D47A1)..strokeWidth=w*0.095..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    final shoeP= Paint()..color=const Color(0xFF3E2723)..strokeWidth=w*0.08..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;

    for (int i=0; i<2; i++) {
      final phase = i==0 ? cycle : cycle+math.pi;
      final hipX  = (i==0 ? -w*0.10 : w*0.10);
      final hipY  = h*0.24;

      // Thigh angle: swings ±30°
      final thighAngle = math.sin(phase)*0.52;
      final thighLen   = h*0.28;
      final kneeX      = hipX + math.sin(thighAngle)*thighLen;
      final kneeY      = hipY + math.cos(thighAngle)*thighLen;

      // Shin: follows through past knee
      final shinAngle  = thighAngle - math.max(0, math.sin(phase))*0.7;
      final shinLen    = h*0.26;
      final ankleX     = kneeX + math.sin(shinAngle)*shinLen;
      final ankleY     = kneeY + math.cos(shinAngle)*shinLen;

      // Draw
      canvas.drawLine(Offset(hipX,hipY), Offset(kneeX,kneeY), legP);
      canvas.drawLine(Offset(kneeX,kneeY), Offset(ankleX,ankleY), legP);
      // Shoe/boot
      canvas.drawLine(Offset(ankleX,ankleY),
          Offset(ankleX+math.sin(thighAngle)*w*0.14, ankleY+w*0.04), shoeP);
    }
  }

  void _drawFarmerArms(Canvas canvas, double w, double h, double cycle, double anger) {
    // Arms swing opposite to legs (natural human gait)
    final armP = Paint()..color=const Color(0xFFEF5350)..strokeWidth=w*0.08..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    final handP= Paint()..color=const Color(0xFFFFCCAA)..strokeWidth=w*0.07..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;

    for (int i=0; i<2; i++) {
      final phase     = i==0 ? cycle+math.pi : cycle;  // opposite to legs
      final shoulderX = (i==0 ? -w*0.18 : w*0.18);
      final shoulderY = -h*0.12;
      final armAngle  = math.sin(phase)*0.45;
      final armLen    = h*0.24;
      final elbowX    = shoulderX + math.sin(armAngle)*armLen;
      final elbowY    = shoulderY + math.cos(armAngle)*armLen;

      canvas.drawLine(Offset(shoulderX,shoulderY), Offset(elbowX,elbowY), armP);
      // Forearm
      final foreAngle = armAngle + math.sin(phase)*0.3;
      final handX     = elbowX + math.sin(foreAngle)*armLen*0.8;
      final handY     = elbowY + math.cos(foreAngle)*armLen*0.8;
      canvas.drawLine(Offset(elbowX,elbowY), Offset(handX,handY), handP);

      // Pitchfork in right hand (i==1)
      if (i==1) {
        canvas.save();
        canvas.translate(handX, handY);
        canvas.rotate(armAngle*0.8 - 0.3);
        final pitch = Paint()..color=const Color(0xFF6D4C41)..strokeWidth=2.5..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
        final metal = Paint()..color=const Color(0xFF90A4AE)..strokeWidth=2..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
        canvas.drawLine(const Offset(0,0), Offset(0,-h*0.38), pitch);
        for (final dx in [-w*0.04, 0.0, w*0.04]) {
          canvas.drawLine(Offset(dx,-h*0.38), Offset(dx,-h*0.52), metal);
        }
        canvas.restore();
      }
    }
  }

  // ── HUD ────────────────────────────────────────────────────────────────────
  void _drawHUD(Canvas canvas, Size size) {
    if (state.phase == GamePhase.menu) return;

    // Score panel
    _panel(canvas,12,12,164,58); _t(canvas,'SCORE',24,30,11,Colors.white54);
    _t(canvas,_fmt(state.score.toInt()),24,52,23,kColYolk,bold:true);

    // Coins
    _panel(canvas,186,12,125,58); _t(canvas,'💰 COINS',198,30,11,Colors.white54);
    _t(canvas,'${state.coins}',198,52,23,kColYolk,bold:true);

    // Best
    _panel(canvas,size.width-175,12,163,58);
    _t(canvas,'🏆 BEST',size.width-163,30,11,Colors.white54);
    _t(canvas,_fmt(state.highScore),size.width-163,52,19,const Color(0xFF69F0AE),bold:true);

    // Power-up timers
    double px=12;
    if(state.magnetActive){_badge(canvas,px,80,'🧲',const Color(0xFF2196F3),state.magnetFrames,480);px+=58;}
    if(state.shieldActive){_badge(canvas,px,80,'🛡',const Color(0xFF4CAF50),state.shieldFrames,360);px+=58;}
    if(state.x2Active)    {_badge(canvas,px,80,'✕2',const Color(0xFF9C27B0),state.x2Frames,600);px+=58;}
    if(state.multiplier>1) _t(canvas,'✕${state.multiplier}',size.width/2,90,28,const Color(0xFF9C27B0),bold:true,center:true);

    // Farmer danger bar
    final d=state.farmerDanger;
    if(d>0.12){
      final mw=size.width*0.56; final mx=(size.width-mw)/2; final my=size.height-60.0;
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
    _t(canvas,icon,x+25,y+30,19,Colors.white,center:true);
  }

  void _drawMenu(Canvas canvas, Size size) {
    final cx=size.width/2; final cy=size.height*0.38;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(cx,cy),width:330,height:155),const Radius.circular(22)),
        Paint()..color=Colors.black.withOpacity(0.76));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(cx,cy),width:330,height:155),const Radius.circular(22)),
        Paint()..color=kColYolk.withOpacity(0.4)..style=PaintingStyle.stroke..strokeWidth=2.2);
    _t(canvas,'🐔  CLUCK & RUN!',cx,cy-40,26,kColYolk,bold:true,center:true);
    _t(canvas,'TAP  to  Start',cx,cy-4,18,Colors.white,center:true);
    _t(canvas,'← → Lanes   ↑ Jump   ↓ Slide',cx,cy+24,11,Colors.white60,center:true);
    if(state.highScore>0) _t(canvas,'🏆 Best: ${_fmt(state.highScore)}',cx,cy+50,14,kColGold,center:true);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  void _panel(Canvas canvas,double x,double y,double w,double h){
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,h),const Radius.circular(10)),
        Paint()..color=Colors.black.withOpacity(0.56));
  }
  void _t(Canvas canvas,String text,double x,double y,double fs,Color col,
      {bool bold=false,bool center=false}){
    final tp=TextPainter(text:TextSpan(text:text,style:TextStyle(color:col,fontSize:fs,
        fontWeight:bold?FontWeight.w900:FontWeight.normal,
        shadows:[const Shadow(blurRadius:2,color:Colors.black54)])),
        textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas,center?Offset(x-tp.width/2,y-tp.height/2):Offset(x,y-tp.height));
  }
  String _fmt(int n)=>n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),(m)=>'${m[1]},');

  @override bool shouldRepaint(covariant _GamePainter old)=>true;
}
