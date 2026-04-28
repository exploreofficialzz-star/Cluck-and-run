// lib/game/game_state.dart
import 'dart:math' as math;
import '../utils/constants.dart';

enum GamePhase { menu, playing, dead, paused }
enum ObstacleType { hayBale, fence, pumpkinPair, barrier }
enum PowerUpType { magnet, shield, scoreX2 }

class Obstacle {
  double y; final int lane; final ObstacleType type; final double height;
  bool passed = false;
  Obstacle({required this.y, required this.lane, required this.type, required this.height});
}

class CoinItem {
  double y; final int lane; bool collected = false;
  CoinItem({required this.y, required this.lane});
}

class BonusBird {
  double x; double y; final double speed; final int coins; bool collected = false;
  BonusBird({required this.x, required this.y, required this.speed, required this.coins});
}

class PowerUp {
  double y; final int lane; final PowerUpType type; bool collected = false;
  PowerUp({required this.y, required this.lane, required this.type});
}

class GameState {
  GamePhase phase   = GamePhase.menu;
  double score      = 0;
  int    coins      = 0;
  int    highScore  = 0;
  int    multiplier = 1;
  double speed      = kInitialSpeed;

  int    currentLane   = 1;
  int    targetLane    = 1;
  double laneSwitchT   = 1.0;
  double laneX         = 0;

  double playerYOffset = 0;
  double velocityY     = 0;
  bool   isJumping     = false;
  bool   isSliding     = false;
  int    slideFrames   = 0;
  int    invincibleFrames = 0;

  double bgScrollY     = 0;
  int    animFrame     = 0;
  double animT         = 0;
  double farmerScale   = kFarmerInitScale;

  double nextObsIn     = 1.5;
  double nextCoinIn    = 0.8;
  double nextBirdIn    = kBirdInterval;
  double nextPowerUpIn = 8.0;
  double cluckTimer    = 0;

  bool   magnetActive  = false; int magnetFrames = 0;
  bool   shieldActive  = false; int shieldFrames = 0;
  bool   x2Active      = false; int x2Frames     = 0;
  bool   reviveUsed    = false;

  final obstacles  = <Obstacle>[];
  final coinItems  = <CoinItem>[];
  final bonusBirds = <BonusBird>[];
  final powerUps   = <PowerUp>[];

  bool   get isInvincible => invincibleFrames > 0 || shieldActive;
  double get farmerDanger  => ((farmerScale - kFarmerInitScale) /
      (kFarmerMaxScale - kFarmerInitScale)).clamp(0.0, 1.0);

  void reset({int savedHi = 0}) {
    phase = GamePhase.playing; score = 0; coins = 0; highScore = savedHi;
    multiplier = 1; speed = kInitialSpeed;
    currentLane = 1; targetLane = 1; laneSwitchT = 1.0; laneX = 0;
    playerYOffset = 0; velocityY = 0; isJumping = false; isSliding = false;
    slideFrames = 0; invincibleFrames = 0; bgScrollY = 0; animFrame = 0; animT = 0;
    farmerScale = kFarmerInitScale; nextObsIn = 1.5; nextCoinIn = 0.8;
    nextBirdIn = kBirdInterval; nextPowerUpIn = 8.0; cluckTimer = 0;
    magnetActive = false; magnetFrames = 0; shieldActive = false; shieldFrames = 0;
    x2Active = false; x2Frames = 0; reviveUsed = false;
    obstacles.clear(); coinItems.clear(); bonusBirds.clear(); powerUps.clear();
  }
}
