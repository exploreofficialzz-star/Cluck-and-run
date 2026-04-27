// lib/game/game_widget.dart
// The playable game canvas — renders each frame via CustomPaint.
// Handles all input (tap, swipe, keyboard) and drives the GameEngine.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_engine.dart';
import 'game_state.dart';
import 'painters/chicken_painter.dart';
import 'painters/farmer_painter.dart';
import 'painters/world_painter.dart';
import '../utils/constants.dart';

class GameWidget extends StatefulWidget {
  final int savedHighScore;
  final VoidCallback onDied;
  final VoidCallback onReviveRequested;
  final VoidCallback onCoinsEarned;

  const GameWidget({
    super.key,
    required this.savedHighScore,
    required this.onDied,
    required this.onReviveRequested,
    required this.onCoinsEarned,
  });

  @override
  State<GameWidget> createState() => GameWidgetState();
}

class GameWidgetState extends State<GameWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  late GameState  _state;
  late GameEngine _engine;
  double _lastTime = 0;

  Offset? _touchStart;

  @override
  void initState() {
    super.initState();
    _state  = GameState()..highScore = widget.savedHighScore;
    _engine = GameEngine(
      state:           _state,
      onDied:          widget.onDied,
      onCoinCollected: widget.onCoinsEarned,
      onJump:          () {}, // audio handled in screen
    );
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
  }

  void _onTick() {
    final now = _ticker.lastElapsedDuration?.inMicroseconds.toDouble() ?? 0;
    final dt = math.min((now - _lastTime) / 1000000.0, 0.05);// cap at 50ms
    _lastTime = now;

    if (_state.phase == GamePhase.playing) {
      // Get size from render box
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        final size    = box.size;
        final groundY = size.height * kGroundY;
        final playerX = size.width  * kPlayerXFrac;
        _engine.update(dt, groundY, size.width);
        _engine.checkCollisionAbsolute(playerX, groundY);
        _engine.checkCoinAbsolute(playerX, groundY);
      }
    }
    setState(() {});
  }

  // ── Public API called from parent screen ─────────────────────────────────────
  void startNewGame() => _state.reset(savedHighScore: widget.savedHighScore);
  void revive()       => _engine.revive();
  GameState get gameState => _state;

  // ── Input ─────────────────────────────────────────────────────────────────────
  void _handleTap() {
    if (_state.phase == GamePhase.playing) {
      _engine.jump();
    } else if (_state.phase == GamePhase.menu) {
      startNewGame();
    }
  }

  void _handleSwipeDown() {
    if (_state.phase == GamePhase.playing) _engine.slide();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _handleTap(); return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _handleSwipeDown(); return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTapDown: (_) => _handleTap(),
        onVerticalDragStart: (d) => _touchStart = d.globalPosition,
        onVerticalDragEnd: (d) {
          if (_touchStart != null && d.velocity.pixelsPerSecond.dy > 200) {
            _handleSwipeDown();
          }
          _touchStart = null;
        },
        child: CustomPaint(
          painter: _GamePainter(state: _state),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _GamePainter extends CustomPainter {
  final GameState state;
  const _GamePainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final groundY  = size.height * kGroundY;
    final playerX  = size.width  * kPlayerXFrac;
    final farmerX  = playerX - state.farmerGap;

    // ── Background ──────────────────────────────────────────────────────────────
    WorldPainter.drawSky(canvas, size);
    WorldPainter.drawSun(canvas, state.bgAnimT);
    WorldPainter.drawClouds(canvas, state.scrollOffset);
    WorldPainter.drawHills(canvas, size, state.scrollOffset);

    // Background decorations (trees, barns, bushes) with parallax
    _drawBgElements(canvas, size, groundY);

    WorldPainter.drawGround(canvas, size, groundY, state.scrollOffset);

    // ── Coins ───────────────────────────────────────────────────────────────────
    for (final c in state.coinItems) {
      if (!c.collected) {
        WorldPainter.drawCoin(canvas, Offset(c.x, groundY + c.y), state.animFrame);
      }
    }

    // ── Obstacles ───────────────────────────────────────────────────────────────
    for (final o in state.obstacles) {
      switch (o.kind) {
        case ObstacleKind.hayBale:
          WorldPainter.drawHayBale(canvas, Offset(o.x, groundY - o.height / 2));
          break;
        case ObstacleKind.fence:
          WorldPainter.drawFence(canvas, Offset(o.x, groundY), o.height, o.gapHeight ?? 48);
          break;
        case ObstacleKind.pumpkin:
          WorldPainter.drawPumpkin(canvas, Offset(o.x, groundY - o.height / 2));
          break;
        default:
          WorldPainter.drawHayBale(canvas, Offset(o.x, groundY - o.height / 2));
      }
    }

    // ── Farmer ──────────────────────────────────────────────────────────────────
    FarmerPainter.draw(
      canvas,
      Offset(farmerX, groundY),
      1.0,
      frame:       state.animFrame,
      angerLevel:  state.angerLevel,
    );

    // ── Chicken ─────────────────────────────────────────────────────────────────
    ChickenPainter.draw(
      canvas,
      Offset(playerX, groundY + state.playerY),
      1.0,
      frame:       state.animFrame,
      isJumping:   state.isJumping,
      isSliding:   state.isSliding,
      invincible:  state.isInvincible,
    );

    // ── HUD ─────────────────────────────────────────────────────────────────────
    if (state.phase == GamePhase.playing || state.phase == GamePhase.dead) {
      _drawHud(canvas, size, groundY);
    }

    // ── Menu overlay ─────────────────────────────────────────────────────────────
    if (state.phase == GamePhase.menu) {
      _drawMenuPrompt(canvas, size);
    }
  }

  void _drawBgElements(Canvas canvas, Size size, double groundY) {
    final layerY = [groundY * 0.72, groundY * 0.80, groundY * 0.88];
    for (final el in state.bgElements) {
      WorldPainter.drawBgDecoration(canvas, [
        {
          'layer': el.layer,
          'x':     el.x,
          'y':     layerY[el.layer],
          'type':  el.type,
        }
      ]);
    }
  }

  void _drawHud(Canvas canvas, Size size, double groundY) {
    // Score panel
    _drawPanel(canvas, const Offset(12, 12), 160, 52);
    _drawText(canvas, 'SCORE', const Offset(24, 28), 11, const Color(0xFFAAAAAA));
    _drawText(canvas, _fmt(state.score.toInt()), const Offset(24, 50), 22, kColYolk, bold: true);

    // Coins panel
    _drawPanel(canvas, const Offset(184, 12), 130, 52);
    _drawText(canvas, '💰 COINS', const Offset(196, 28), 11, const Color(0xFFAAAAAA));
    _drawText(canvas, '${state.coins}', const Offset(196, 50), 22, kColYolk, bold: true);

    // Danger meter (shows when farmer is close)
    final danger = state.angerLevel;
    if (danger > 0.15) {
      final w = size.width - 200;
      _drawPanel(canvas, Offset(size.width - w - 12, 12), w, 52);
      final colour = Color.lerp(const Color(0xFFFF8F00), const Color(0xFFFF1744), danger)!;
      _drawText(canvas, '⚠ FARMER CLOSE!', Offset(size.width - w, 28), 10, colour, bold: true);
      // Bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(size.width - w, 34, w - 14, 12), const Radius.circular(4)),
        Paint()..color = Colors.white.withOpacity(0.12),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(size.width - w, 34, (w - 14) * danger, 12), const Radius.circular(4)),
        Paint()..color = colour,
      );
    }
  }

  void _drawMenuPrompt(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.44;
    // Glass panel
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 340, height: 160), const Radius.circular(22)),
      Paint()..color = Colors.black.withOpacity(0.72),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 340, height: 160), const Radius.circular(22)),
      Paint()
        ..color = kColYolk.withOpacity(0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    _drawText(canvas, '🐔 CLUCK & RUN!', Offset(cx, cy - 42), 28, kColYolk, bold: true, center: true);
    _drawText(canvas, 'TAP or SPACE to Start', Offset(cx, cy - 8), 16, Colors.white, center: true);
    _drawText(canvas, '↑ Jump   ·   ↓ Slide   ·   Escape the hungry farmer!', Offset(cx, cy + 22), 12, Colors.white60, center: true);
    if (_state_highScore > 0) {
      _drawText(canvas, '🏆 Best: ${_fmt(_state_highScore)}', Offset(cx, cy + 52), 14, kColGold, center: true);
    }
  }

  // Hack to pass high score through — painter is const so we read from state
  int get _state_highScore => state.highScore;

  static void _drawPanel(Canvas canvas, Offset origin, double w, double h) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(origin.dx, origin.dy, w, h), const Radius.circular(10)),
      Paint()..color = Colors.black.withOpacity(0.50),
    );
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    double size,
    Color color, {
    bool bold   = false,
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color:      color,
          fontSize:   size,
          fontWeight: bold ? FontWeight.w900 : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center ? Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2) : pos);
  }

  static String _fmt(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}
