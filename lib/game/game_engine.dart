// lib/game/game_engine.dart
// Perspective-correct lane runner. laneX is Y-dependent.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_state.dart';
import '../utils/constants.dart';

// ── Road geometry (must match painter) ───────────────────────────────────────
const double kHorizonFrac   = 0.28;  // horizon at 28% from top
const double kRoadHalfTop   = 0.08;  // road half-width at horizon (frac of screen W)
const double kRoadHalfBot   = 0.44;  // road half-width at screen bottom
const double kPlayerYFrac   = 0.70;  // player Y position (frac of screen H)

// Lane fractions WITHIN the road (left=0, centre=1, right=2)
const List<double> kLaneRoadFracs = [0.17, 0.50, 0.83];

class GameEngine {
  final GameState state;
  final VoidCallback onDied, onCoinCollected, onBonusBird, onJump, onCluck;
  final math.Random _rng = math.Random();

  GameEngine({required this.state, required this.onDied,
    required this.onCoinCollected, required this.onBonusBird,
    required this.onJump, required this.onCluck});

  // ── Perspective-correct laneX ─────────────────────────────────────────────
  // Returns screen X for a given lane at a given screen Y.
  double laneXatY(int lane, double screenY, Size size) {
    final hY    = size.height * kHorizonFrac;
    final botY  = size.height;
    final t     = ((screenY - hY) / (botY - hY)).clamp(0.0, 1.0);
    final half  = (kRoadHalfTop + (kRoadHalfBot - kRoadHalfTop) * t) * size.width;
    final cx    = size.width / 2;
    final frac  = kLaneRoadFracs[lane.clamp(0, 2)];
    return cx - half + half * 2 * frac;
  }

  // laneX at player position (for HUD, collision reference)
  double laneX(int lane, Size size) =>
      laneXatY(lane, size.height * kPlayerYFrac, size);

  // Smooth interpolated player X
  double currentPlayerX(Size size) {
    final from = laneXatY(state.currentLane, size.height * kPlayerYFrac, size);
    final to   = laneXatY(state.targetLane,  size.height * kPlayerYFrac, size);
    return from + (to - from) * _ease(state.laneSwitchT);
  }

  // ── Input ──────────────────────────────────────────────────────────────────
  void swipeLeft()  { if (state.phase != GamePhase.playing || state.targetLane <= 0) return; state.targetLane--; state.laneSwitchT = 0; }
  void swipeRight() { if (state.phase != GamePhase.playing || state.targetLane >= kLaneCount-1) return; state.targetLane++; state.laneSwitchT = 0; }
  void jump()  { if (state.phase != GamePhase.playing || state.isJumping || state.isSliding) return; state.velocityY = kJumpVelocity; state.isJumping = true; onJump(); }
  void slide() { if (state.phase != GamePhase.playing || state.isJumping) return; state.isSliding = true; state.slideFrames = 42; }
  void revive() {
    state.phase = GamePhase.playing;
    state.invincibleFrames = (kInvincibleMs / 16.67).round();
    state.reviveUsed  = true;
    state.farmerScale = math.max(kFarmerInitScale, state.farmerScale * 0.60);
  }

  // ── Main update ───────────────────────────────────────────────────────────
  void update(double dt, Size size) {
    if (state.phase != GamePhase.playing) return;
    state.animT     += dt;
    state.animFrame  = (state.animFrame + 1) % 240;
    state.score     += state.speed * dt * 0.14;
    state.speed      = math.min(kMaxSpeed, kInitialSpeed + state.score * kSpeedGrowth);
    state.bgScrollY  = (state.bgScrollY + state.speed * dt);

    // Lane lerp
    if (state.laneSwitchT < 1) state.laneSwitchT = math.min(1.0, state.laneSwitchT + dt / kLaneSwitchSpeed);

    // Jump physics
    if (state.isJumping) {
      state.velocityY    += kGravity * dt;
      state.playerYOffset -= state.velocityY * dt;
      if (state.playerYOffset <= 0) { state.playerYOffset = 0; state.velocityY = 0; state.isJumping = false; }
    }
    if (state.isSliding && --state.slideFrames <= 0) state.isSliding = false;
    if (state.invincibleFrames > 0) state.invincibleFrames--;

    state.farmerScale = math.min(kFarmerMaxScale, kFarmerInitScale + state.score * kFarmerGrowthRate);
    if (state.magnetActive && --state.magnetFrames <= 0) state.magnetActive = false;
    if (state.shieldActive && --state.shieldFrames <= 0) state.shieldActive = false;
    if (state.x2Active     && --state.x2Frames     <= 0) { state.x2Active = false; state.multiplier = 1; }

    state.cluckTimer -= dt;
    if (state.cluckTimer <= 0) { state.cluckTimer = 2.0 + _rng.nextDouble()*1.5; onCluck(); }

    // Scroll entities
    final scroll = state.speed * dt;
    for (final o in state.obstacles)  o.y += scroll;
    for (final c in state.coinItems)  c.y += scroll;
    for (final p in state.powerUps)   p.y += scroll;
    for (final b in state.bonusBirds) b.x += b.speed * dt;

    // Cleanup
    final sh = size.height;
    state.obstacles.removeWhere( (o) => o.y > sh * 1.15);
    state.coinItems.removeWhere( (c) => c.y > sh * 1.15 || c.collected);
    state.powerUps.removeWhere(  (p) => p.y > sh * 1.15 || p.collected);
    state.bonusBirds.removeWhere((b) => b.x < -100 || b.x > size.width+100 || b.collected);

    _spawn(dt, size);
    _checkCollisions(size);
    _checkCollectibles(size);
  }

  void _spawn(double dt, Size size) {
    _spawnObs(dt, size);
    _spawnCoins(dt, size);
    _spawnBirds(dt, size);
    _spawnPower(dt, size);
  }

  void _spawnObs(double dt, Size size) {
    state.nextObsIn -= dt;
    if (state.nextObsIn > 0) return;
    final gap = math.max(kObsMinInterval, kObsMaxInterval - state.score * 0.00005);
    state.nextObsIn = kObsMinInterval + _rng.nextDouble() * gap;
    final freeLane = _rng.nextInt(kLaneCount);
    final roll = _rng.nextDouble();
    // Spawn just above horizon so they slide in naturally
    const spawnY = -10.0;
    if (roll < 0.38) {
      final lane = freeLane == 1 ? 0 : 1;
      state.obstacles.add(Obstacle(y: spawnY, lane: lane, type: ObstacleType.hayBale, height: 72));
    } else if (roll < 0.60) {
      final lane = freeLane == 1 ? 2 : 1;
      state.obstacles.add(Obstacle(y: spawnY, lane: lane, type: ObstacleType.fence, height: 110));
    } else if (roll < 0.80) {
      for (int l = 0; l < kLaneCount; l++) {
        if (l != freeLane) state.obstacles.add(Obstacle(y: spawnY, lane: l, type: ObstacleType.pumpkinPair, height: 62));
      }
    } else {
      for (int l = 0; l < kLaneCount; l++) {
        if (l != freeLane) state.obstacles.add(Obstacle(y: spawnY, lane: l, type: ObstacleType.barrier, height: 88));
      }
    }
  }

  void _spawnCoins(double dt, Size size) {
    state.nextCoinIn -= dt;
    if (state.nextCoinIn > 0) return;
    state.nextCoinIn = kCoinInterval + _rng.nextDouble() * 0.45;
    final lane = _rng.nextInt(kLaneCount);
    // Coins start just below horizon, spaced along Y
    const baseY = 20.0;
    switch (_rng.nextInt(4)) {
      case 0: // Line in one lane
        for (int i = 0; i < 6; i++) state.coinItems.add(CoinItem(y: baseY + i*70.0, lane: lane));
        break;
      case 1: // Arc across lanes
        for (int l = 0; l < 3; l++) state.coinItems.add(CoinItem(y: baseY + l*65.0, lane: l));
        break;
      case 2: // Dense cluster
        for (int l = 0; l < 3; l++)
          for (int i = 0; i < 2; i++) state.coinItems.add(CoinItem(y: baseY + i*72.0, lane: l));
        break;
      default: // Long line
        for (int i = 0; i < 8; i++) state.coinItems.add(CoinItem(y: baseY + i*58.0, lane: lane));
    }
  }

  void _spawnBirds(double dt, Size size) {
    state.nextBirdIn -= dt;
    if (state.nextBirdIn > 0) return;
    state.nextBirdIn = kBirdInterval + _rng.nextDouble() * 4.0;
    final goLeft = _rng.nextBool();
    final yFrac  = 0.32 + _rng.nextDouble() * 0.28;
    state.bonusBirds.add(BonusBird(
      x:     goLeft ? size.width + 50 : -50,
      y:     size.height * yFrac,
      speed: goLeft ? -(260 + state.score * 0.025) : (260 + state.score * 0.025),
      coins: kBonusBirdCoins,
    ));
  }

  void _spawnPower(double dt, Size size) {
    state.nextPowerUpIn -= dt;
    if (state.nextPowerUpIn > 0) return;
    state.nextPowerUpIn = 9.0 + _rng.nextDouble() * 7.0;
    state.powerUps.add(PowerUp(y: 25.0, lane: _rng.nextInt(kLaneCount),
        type: PowerUpType.values[_rng.nextInt(3)]));
  }

  // ── Collision (perspective-aware) ─────────────────────────────────────────
  void _checkCollisions(Size size) {
    if (state.isInvincible) return;
    final px  = currentPlayerX(size);
    final py  = size.height * kPlayerYFrac - state.playerYOffset;
    final pw  = _roadWidthAt(py, size) * 0.28;   // player width = 28% of road at player Y
    final ph  = size.height * 0.10;
    final pTop = py - (state.isSliding ? ph * 0.45 : ph);
    final pBot = py + ph * 0.12;

    for (final o in state.obstacles) {
      if (o.passed) continue;
      final oy = o.y;
      if (oy < size.height * kHorizonFrac) continue; // above horizon - no collision yet
      final ox  = laneXatY(o.lane, oy, size);
      final ow  = _roadWidthAt(oy, size) * 0.22;
      final oh  = _scaleAt(oy, size) * o.height;
      final oTop = oy - oh;
      if ((px - ox).abs() > (pw + ow)) continue;
      if (pBot < oTop || pTop > oy + 8) continue;
      if (state.currentLane != o.lane && state.targetLane != o.lane) continue;
      if (o.type == ObstacleType.fence && state.isSliding) { o.passed = true; continue; }
      state.phase = GamePhase.dead;
      onDied();
      return;
    }
  }

  void _checkCollectibles(Size size) {
    final px  = currentPlayerX(size);
    final py  = size.height * kPlayerYFrac - state.playerYOffset;
    final pickR = state.magnetActive ? 110.0 : 48.0;

    for (final c in state.coinItems) {
      if (c.collected) continue;
      final cx = laneXatY(c.lane, c.y, size);
      final dist = math.sqrt(math.pow(cx - px, 2) + math.pow(c.y - py, 2));
      if (dist < pickR) { c.collected = true; state.coins += state.multiplier; onCoinCollected(); }
    }

    for (final b in state.bonusBirds) {
      if (b.collected) continue;
      final dist = math.sqrt(math.pow(b.x - px, 2) + math.pow(b.y - py, 2));
      if (dist < 72) { b.collected = true; state.coins += b.coins * state.multiplier; onBonusBird(); }
    }

    for (final p in state.powerUps) {
      if (p.collected || p.lane != state.targetLane) continue;
      final px2 = laneXatY(p.lane, p.y, size);
      if ((px2 - px).abs() < 55 && (p.y - py).abs() < 55) {
        p.collected = true; _activatePower(p.type);
      }
    }
  }

  void _activatePower(PowerUpType t) {
    switch (t) {
      case PowerUpType.magnet:  state.magnetActive = true; state.magnetFrames = 480; break;
      case PowerUpType.shield:  state.shieldActive = true; state.shieldFrames = 360; break;
      case PowerUpType.scoreX2: state.x2Active = true; state.x2Frames = 600; state.multiplier = 2; break;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  double _roadWidthAt(double y, Size size) {
    final hY = size.height * kHorizonFrac;
    final t  = ((y - hY) / (size.height - hY)).clamp(0.0, 1.0);
    return (kRoadHalfTop + (kRoadHalfBot - kRoadHalfTop) * t) * size.width * 2;
  }

  // Scale factor for objects based on their Y (perspective size)
  double _scaleAt(double y, Size size) {
    final hY = size.height * kHorizonFrac;
    final t  = ((y - hY) / (size.height - hY)).clamp(0.0, 1.0);
    return 0.18 + 0.82 * t;  // tiny at horizon, full size at bottom
  }

  double _ease(double t) => t < 0.5 ? 2*t*t : -1+(4-2*t)*t;
}
