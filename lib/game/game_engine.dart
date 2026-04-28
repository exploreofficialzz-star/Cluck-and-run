// lib/game/game_engine.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_state.dart';
import '../utils/constants.dart';

class GameEngine {
  final GameState state;
  final VoidCallback onDied;
  final VoidCallback onCoinCollected;
  final VoidCallback onBonusBird;
  final VoidCallback onJump;
  final VoidCallback onCluck;
  final math.Random _rng = math.Random();

  GameEngine({required this.state, required this.onDied,
    required this.onCoinCollected, required this.onBonusBird,
    required this.onJump, required this.onCluck});

  void swipeLeft()  { if (state.phase != GamePhase.playing) return; if (state.targetLane > 0) { state.targetLane--; state.laneSwitchT = 0.0; } }
  void swipeRight() { if (state.phase != GamePhase.playing) return; if (state.targetLane < kLaneCount - 1) { state.targetLane++; state.laneSwitchT = 0.0; } }

  void jump() {
    if (state.phase != GamePhase.playing) return;
    if (!state.isJumping && !state.isSliding) { state.velocityY = kJumpVelocity; state.isJumping = true; onJump(); }
  }

  void slide() {
    if (state.phase != GamePhase.playing) return;
    if (!state.isJumping) { state.isSliding = true; state.slideFrames = 42; }
  }

  void revive() {
    state.phase = GamePhase.playing;
    state.invincibleFrames = (kInvincibleMs / 16.67).round();
    state.reviveUsed = true;
    state.farmerScale = math.max(kFarmerInitScale, state.farmerScale * 0.65);
  }

  void update(double dt, Size screenSize) {
    if (state.phase != GamePhase.playing) return;
    state.animT += dt;
    state.animFrame = (state.animFrame + 1) % 240;

    state.score += state.speed * dt * 0.14;
    state.speed  = math.min(kMaxSpeed, kInitialSpeed + state.score * kSpeedGrowth);
    state.bgScrollY = (state.bgScrollY + state.speed * dt) % (screenSize.height * 1.5);

    // Lane switch lerp
    if (state.laneSwitchT < 1.0) {
      state.laneSwitchT = math.min(1.0, state.laneSwitchT + dt / kLaneSwitchSpeed);
    }

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
    if (state.cluckTimer <= 0) { state.cluckTimer = 1.8 + _rng.nextDouble() * 1.2; onCluck(); }

    final scrollDist = state.speed * dt;
    for (final o in state.obstacles)  o.y += scrollDist;
    for (final c in state.coinItems)  c.y += scrollDist;
    for (final p in state.powerUps)   p.y += scrollDist;
    for (final b in state.bonusBirds) b.x += b.speed * dt;

    final sh = screenSize.height;
    state.obstacles.removeWhere( (o) => o.y > sh * 1.2);
    state.coinItems.removeWhere( (c) => c.y > sh * 1.2 || c.collected);
    state.powerUps.removeWhere(  (p) => p.y > sh * 1.2 || p.collected);
    state.bonusBirds.removeWhere((b) => b.x > screenSize.width + 120 || b.x < -120 || b.collected);

    _spawnObstacles(dt, screenSize);
    _spawnCoins(dt, screenSize);
    _spawnBirds(dt, screenSize);
    _spawnPowerUps(dt, screenSize);
    _checkCollisions(screenSize);
    _checkCollectibles(screenSize);
  }

  void _spawnObstacles(double dt, Size size) {
    state.nextObsIn -= dt;
    if (state.nextObsIn > 0) return;
    final gap = math.max(kObsMinInterval, kObsMaxInterval - state.score * 0.00006);
    state.nextObsIn = kObsMinInterval + _rng.nextDouble() * gap;
    final freeLane = _rng.nextInt(kLaneCount);
    final roll = _rng.nextDouble();
    if (roll < 0.35) {
      state.obstacles.add(Obstacle(y: -80, lane: freeLane == 0 ? 1 : 0, type: ObstacleType.hayBale, height: 70));
    } else if (roll < 0.58) {
      state.obstacles.add(Obstacle(y: -80, lane: freeLane == 0 ? 1 : 0, type: ObstacleType.fence, height: 115));
    } else if (roll < 0.78) {
      for (int l = 0; l < kLaneCount; l++) {
        if (l != freeLane) state.obstacles.add(Obstacle(y: -80, lane: l, type: ObstacleType.pumpkinPair, height: 60));
      }
    } else {
      for (int l = 0; l < kLaneCount; l++) {
        if (l != freeLane) state.obstacles.add(Obstacle(y: -80, lane: l, type: ObstacleType.barrier, height: 88));
      }
    }
  }

  void _spawnCoins(double dt, Size size) {
    state.nextCoinIn -= dt;
    if (state.nextCoinIn > 0) return;
    state.nextCoinIn = kCoinInterval + _rng.nextDouble() * 0.45;
    final lane = _rng.nextInt(kLaneCount);
    final pattern = _rng.nextInt(4);
    switch (pattern) {
      case 0:
        for (int i = 0; i < 6; i++) state.coinItems.add(CoinItem(y: -60 - i * 60.0, lane: lane));
        break;
      case 1:
        for (int l = 0; l < kLaneCount; l++) state.coinItems.add(CoinItem(y: -60 - l * 55.0, lane: l));
        break;
      case 2:
        for (int l = 0; l < kLaneCount; l++)
          for (int i = 0; i < 2; i++) state.coinItems.add(CoinItem(y: -60 - i * 65.0, lane: l));
        break;
      default:
        for (int i = 0; i < 8; i++) state.coinItems.add(CoinItem(y: -60 - i * 52.0, lane: lane));
    }
  }

  void _spawnBirds(double dt, Size size) {
    state.nextBirdIn -= dt;
    if (state.nextBirdIn > 0) return;
    state.nextBirdIn = kBirdInterval + _rng.nextDouble() * 3.0;
    final yFrac = 0.25 + _rng.nextDouble() * 0.30;
    final goLeft = _rng.nextBool();
    final spd = goLeft ? -(280 + state.score * 0.03) : (280 + state.score * 0.03);
    state.bonusBirds.add(BonusBird(
      x: goLeft ? size.width + 60 : -60,
      y: size.height * yFrac,
      speed: spd,
      coins: kBonusBirdCoins,
    ));
  }

  void _spawnPowerUps(double dt, Size size) {
    state.nextPowerUpIn -= dt;
    if (state.nextPowerUpIn > 0) return;
    state.nextPowerUpIn = 9.0 + _rng.nextDouble() * 6.0;
    final lane = _rng.nextInt(kLaneCount);
    final type = PowerUpType.values[_rng.nextInt(PowerUpType.values.length)];
    state.powerUps.add(PowerUp(y: -60, lane: lane, type: type));
  }

  void _checkCollisions(Size size) {
    if (state.isInvincible) return;
    final lx     = laneX(state.targetLane, size);
    final playerY = size.height * 0.68 - state.playerYOffset;
    final ph     = size.height * 0.13;
    final pw     = size.width  * 0.16;
    final pTop   = playerY - (state.isSliding ? ph * 0.5 : ph);
    final pBot   = playerY + ph * 0.15;
    final pLeft  = lx - pw * 0.42;
    final pRight = lx + pw * 0.42;

    for (final o in state.obstacles) {
      if (o.passed) continue;
      final ox  = laneX(o.lane, size);
      final oL  = ox - size.width * 0.11;
      final oR  = ox + size.width * 0.11;
      final oTop = o.y - o.height;
      if (pRight < oL || pLeft > oR || pBot < oTop || pTop > o.y + 8) continue;
      if (o.lane != state.currentLane && o.lane != state.targetLane) continue;
      if (o.type == ObstacleType.fence && state.isSliding) continue;
      state.phase = GamePhase.dead;
      onDied();
      return;
    }
  }

  void _checkCollectibles(Size size) {
    final lx      = laneX(state.targetLane, size);
    final playerY = size.height * 0.68 - state.playerYOffset;
    final pickR   = state.magnetActive ? 130.0 : 52.0;

    for (final c in state.coinItems) {
      if (c.collected) continue;
      final cx = laneX(c.lane, size);
      if (!state.magnetActive && (c.lane - state.targetLane).abs() > 0) continue;
      if (math.sqrt(math.pow(cx - lx, 2) + math.pow(c.y - playerY, 2)) < pickR) {
        c.collected = true;
        state.coins += state.multiplier;
        onCoinCollected();
      }
    }

    for (final b in state.bonusBirds) {
      if (b.collected) continue;
      if (math.sqrt(math.pow(b.x - lx, 2) + math.pow(b.y - playerY, 2)) < 78) {
        b.collected = true;
        state.coins += b.coins * state.multiplier;
        onBonusBird();
      }
    }

    for (final p in state.powerUps) {
      if (p.collected || p.lane != state.targetLane) continue;
      final px = laneX(p.lane, size);
      if (math.sqrt(math.pow(px - lx, 2) + math.pow(p.y - playerY, 2)) < 58) {
        p.collected = true;
        _activatePowerUp(p.type);
      }
    }
  }

  void _activatePowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.magnet:  state.magnetActive = true; state.magnetFrames = 480; break;
      case PowerUpType.shield:  state.shieldActive = true; state.shieldFrames = 360; break;
      case PowerUpType.scoreX2: state.x2Active = true; state.x2Frames = 600; state.multiplier = 2; break;
    }
  }

  double laneX(int lane, Size size) => size.width * kLaneFracs[lane.clamp(0, 2)];

  double currentPlayerX(Size size) {
    final fromX = laneX(state.currentLane, size);
    final toX   = laneX(state.targetLane, size);
    final t     = _ease(state.laneSwitchT);
    return fromX + (toX - fromX) * t;
  }

  double _ease(double t) => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
}
