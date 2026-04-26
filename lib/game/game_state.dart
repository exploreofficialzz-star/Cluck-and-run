// lib/game/game_state.dart
// Pure data model for the game. No Flutter dependencies.

import 'dart:math' as math;
import '../utils/constants.dart';

enum GamePhase { menu, playing, dead, paused }

// ── Obstacle types ────────────────────────────────────────────────────────────
enum ObstacleKind { hayBale, fence, pumpkin, doubleBale }

class Obstacle {
  double x;
  final ObstacleKind kind;
  final double width;
  final double height;
  final double? gapHeight; // only for fence (slide under)

  Obstacle({
    required this.x,
    required this.kind,
    required this.width,
    required this.height,
    this.gapHeight,
  });
}

class CoinItem {
  double x;
  final double y; // y relative to groundY
  bool collected;
  CoinItem({required this.x, required this.y, this.collected = false});
}

class BgElement {
  double x;
  final double y;
  final int layer;      // 0=far, 1=mid, 2=near
  final String type;    // 'tree', 'barn', 'bush'
  BgElement({required this.x, required this.y, required this.layer, required this.type});
}

// ─────────────────────────────────────────────────────────────────────────────
class GameState {
  // Phase
  GamePhase phase = GamePhase.menu;

  // Scoring
  double score = 0;
  int    coins = 0;
  int    highScore = 0;

  // Player physics
  double playerY     = 0; // offset from groundY (0 = on ground)
  double velocityY   = 0;
  bool   isJumping   = false;
  bool   isSliding   = false;
  int    slideFrames = 0;
  int    invincibleFrames = 0;

  // World
  double scrollOffset = 0;
  double speed        = kInitialSpeed; // px/s

  // Farmer gap (in px, measured from player)
  double farmerGap = kFarmerInitGap;

  // Timers (in seconds)
  double nextObstacleIn = 1.2;
  double nextCoinIn     = 0.8;
  double bgElementIn    = 1.4;

  // Lists
  final obstacles  = <Obstacle>[];
  final coinItems  = <CoinItem>[];
  final bgElements = <BgElement>[];

  // Animations
  int animFrame = 0;
  double bgAnimT = 0; // for sun pulsing, etc.

  // One-use flags per run
  bool reviveUsed = false;

  // ─────────────────────────────────────────────────────────────────────────────
  void reset({int savedHighScore = 0}) {
    phase            = GamePhase.playing;
    score            = 0;
    coins            = 0;
    highScore        = savedHighScore;
    playerY          = 0;
    velocityY        = 0;
    isJumping        = false;
    isSliding        = false;
    slideFrames      = 0;
    invincibleFrames = 0;
    scrollOffset     = 0;
    speed            = kInitialSpeed;
    farmerGap        = kFarmerInitGap;
    nextObstacleIn   = 1.2;
    nextCoinIn       = 0.8;
    bgElementIn      = 1.4;
    animFrame        = 0;
    bgAnimT          = 0;
    reviveUsed       = false;
    obstacles.clear();
    coinItems.clear();
    bgElements.clear();
    _initBgElements();
  }

  void _initBgElements() {
    final rng = math.Random();
    const types = ['tree', 'tree', 'barn', 'bush'];
    for (int i = 0; i < 14; i++) {
      final layer = rng.nextInt(3);
      bgElements.add(BgElement(
        x:     i * 88.0 + rng.nextDouble() * 30,
        y:     0,
        layer: layer,
        type:  types[rng.nextInt(types.length)],
      ));
    }
  }

  // ── Derived helpers ────────────────────────────────────────────────────────
  double get angerLevel => math.max(0, 1 - (farmerGap - kFarmerMinGap) / (kFarmerInitGap - kFarmerMinGap)).clamp(0, 1);
  bool   get isInvincible => invincibleFrames > 0;
  bool   get isNewHighScore => score.toInt() > highScore;
}
