// lib/game/game_engine.dart
// Pure game logic — no Flutter widgets. Called from GameWidget each frame.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_state.dart';
import '../utils/constants.dart';

class GameEngine {
  final GameState state;
  final math.Random _rng = math.Random();

  // Callbacks fired when relevant game events occur
  final VoidCallback onDied;
  final VoidCallback onCoinCollected;
  final VoidCallback onJump;

  GameEngine({
    required this.state,
    required this.onDied,
    required this.onCoinCollected,
    required this.onJump,
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // MAIN UPDATE  (called every frame; dt in seconds)
  // ─────────────────────────────────────────────────────────────────────────────
  void update(double dt, double groundY, double screenW) {
    if (state.phase != GamePhase.playing) return;

    state.bgAnimT  += dt;
    state.animFrame = (state.animFrame + 1) % 120;

    // Speed ramp
    state.score += state.speed * dt * 0.5;
    state.speed  = math.min(
      kMaxSpeed,
      kInitialSpeed + state.score * kSpeedIncrement,
    );
    state.scrollOffset += state.speed * dt;

    // Farmer closing in
    state.farmerGap = math.max(
      kFarmerMinGap,
      state.farmerGap - state.score * kFarmerCatchUp * dt,
    );

    // Player physics
    _updatePlayer(dt, groundY);

    // Slide timer
    if (state.isSliding) {
      state.slideFrames--;
      if (state.slideFrames <= 0) state.isSliding = false;
    }

    // Invincibility countdown
    if (state.invincibleFrames > 0) state.invincibleFrames--;

    // Scroll entities
    _scrollEntities(dt, screenW);

    // Spawn new entities
    _spawnObstacles(dt, screenW, groundY);
    _spawnCoins(dt, screenW, groundY);
    _spawnBgElements(dt, screenW, groundY);

    // Collision
    if (!state.isInvincible && _checkCollision(groundY)) {
      _handleDeath();
    }

    // Coin collection
    _checkCoinCollection(groundY);
  }

  // ── Input ────────────────────────────────────────────────────────────────────
  void jump() {
    if (state.phase != GamePhase.playing) return;
    if (!state.isJumping) {
      state.velocityY  = kJumpVelocity;
      state.isJumping  = true;
      state.isSliding  = false;
      onJump();
    }
  }

  void slide() {
    if (state.phase != GamePhase.playing) return;
    if (!state.isJumping) {
      state.isSliding   = true;
      state.slideFrames = kSlideFrames;
    }
  }

  void revive() {
    state.phase            = GamePhase.playing;
    state.invincibleFrames = (kInvincibleMs / 16.67).round();
    state.reviveUsed       = true;
    state.farmerGap        = kFarmerInitGap * 0.75;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PRIVATE
  // ─────────────────────────────────────────────────────────────────────────────
  void _updatePlayer(double dt, double groundY) {
    if (state.isJumping) {
      state.velocityY += kGravity * dt;
      state.playerY   += state.velocityY * dt;
      if (state.playerY >= 0) {
        state.playerY  = 0;
        state.velocityY = 0;
        state.isJumping = false;
      }
    }
  }

  void _scrollEntities(double dt, double screenW) {
    final spd = state.speed;
    for (final o in state.obstacles)  o.x -= spd * dt;
    for (final c in state.coinItems)  c.x -= spd * dt;
    for (final b in state.bgElements) {
      b.x -= [0.35, 0.95, 2.0][b.layer] * spd * dt * 0.4;
    }

    state.obstacles.removeWhere( (o) => o.x < -150);
    state.coinItems.removeWhere( (c) => c.x < -40 || c.collected);
    state.bgElements.removeWhere((b) => b.x < -200);
  }

  // ── Spawning ─────────────────────────────────────────────────────────────────
  void _spawnObstacles(double dt, double screenW, double groundY) {
    state.nextObstacleIn -= dt;
    if (state.nextObstacleIn > 0) return;

    final minGap = math.max(kObsMinIntervalSec, 1.4 - state.score * 0.00008);
    final maxGap = math.max(minGap + 0.3, kObsMaxIntervalSec - state.score * 0.00006);
    state.nextObstacleIn = minGap + _rng.nextDouble() * (maxGap - minGap);

    final roll = _rng.nextDouble();

    if (roll < 0.35) {
      _spawnHayBale(screenW);
    } else if (roll < 0.58) {
      _spawnFence(screenW);
    } else if (roll < 0.78) {
      _spawnPumpkin(screenW);
    } else {
      // Double obstacle (unlocks after score 200)
      if (state.score > 200) {
        _spawnHayBale(screenW);
        state.obstacles.add(Obstacle(
          x: screenW + 140,
          kind: ObstacleKind.pumpkin,
          width: 40, height: 36,
        ));
      } else {
        _spawnHayBale(screenW);
      }
    }
  }

  void _spawnHayBale(double sw) => state.obstacles.add(Obstacle(x: sw + 80, kind: ObstacleKind.hayBale, width: 56, height: 52));
  void _spawnFence  (double sw) => state.obstacles.add(Obstacle(x: sw + 80, kind: ObstacleKind.fence,   width: 44, height: 110, gapHeight: 48));
  void _spawnPumpkin(double sw) => state.obstacles.add(Obstacle(x: sw + 80, kind: ObstacleKind.pumpkin, width: 40, height: 36));

  void _spawnCoins(double dt, double screenW, double groundY) {
    state.nextCoinIn -= dt;
    if (state.nextCoinIn > 0) return;
    state.nextCoinIn = kCoinIntervalSec + _rng.nextDouble() * 0.8;

    // Coins appear either at ground level or floating mid-air
    final yOff = _rng.nextDouble() > 0.45 ? -90.0 : -20.0;
    state.coinItems.add(CoinItem(x: screenW + 40, y: yOff));
  }

  void _spawnBgElements(double dt, double screenW, double groundY) {
    state.bgElementIn -= dt;
    if (state.bgElementIn > 0) return;
    state.bgElementIn = 1.2 + _rng.nextDouble() * 1.2;

    const types = ['tree', 'tree', 'barn', 'bush'];
    state.bgElements.add(BgElement(
      x:     screenW + 80,
      y:     0,
      layer: _rng.nextInt(3),
      type:  types[_rng.nextInt(types.length)],
    ));
  }

  // ── Collision ─────────────────────────────────────────────────────────────────
  bool _checkCollision(double groundY) {
    // Player bounds (simplified AABB)
    const playerW = 44.0;
    const playerH = 72.0;
    final pX   = 0.0;           // relative; obstacle x is absolute screen x
    final pBot = groundY + state.playerY;
    final pTop = pBot - (state.isSliding ? 32 : playerH);

    const playerScreenX = kPlayerXFrac; // We pass absolute coords in render

    return false; // Collision handled by GameWidget which has screen dims
  }

  /// Called by the widget with real screen coordinates.
  bool checkCollisionAbsolute(
    double playerScreenX,
    double groundY,
  ) {
    final pBot  = groundY + state.playerY;
    final pTop  = pBot - (state.isSliding ? 34 : 72);
    final pLeft = playerScreenX - (state.isSliding ? 30 : 22);
    final pRight = playerScreenX + (state.isSliding ? 42 : 44);

    for (final o in state.obstacles) {
      final oLeft  = o.x - o.width  / 2 + 8;
      final oRight = o.x + o.width  / 2 - 8;
      final oTop   = groundY - o.height;
      final oBot   = groundY;

      if (pRight < oLeft || pLeft > oRight) continue;

      if (o.kind == ObstacleKind.fence) {
        // Fence: must slide under the gap
        final gapBottom = groundY;
        final gapTop    = groundY - (o.gapHeight ?? 48);
        // Collision if player body is above the gap top (meaning head hits rail)
        if (pTop < gapTop) return true;
      } else {
        // Jump over obstacle
        if (pBot > oTop && pTop < oBot) return true;
      }
    }
    return false;
  }

  void _handleDeath() {
    state.phase = GamePhase.dead;
    onDied();
  }

  void _checkCoinCollection(double groundY) {
    // placeholder — resolved by widget with real coords
  }

  bool checkCoinAbsolute(double playerScreenX, double groundY) {
    bool any = false;
    for (final c in state.coinItems) {
      if (c.collected) continue;
      final cy = groundY + c.y;
      final dist = math.sqrt(
        math.pow(c.x - playerScreenX, 2) + math.pow(cy - (groundY + state.playerY - 22), 2),
      );
      if (dist < 36) {
        c.collected = true;
        state.coins++;
        any = true;
        onCoinCollected();
      }
    }
    return any;
  }
}
