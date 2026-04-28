// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../game/game_widget.dart';
import '../game/game_state.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'widgets/game_over_overlay.dart';
import 'widgets/pause_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final _gameKey = GlobalKey<GameWidgetState>();
  bool _showGameOver = false;
  bool _showPause    = false;
  bool _isNewRecord  = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    AudioService.instance.startBgMusic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused  && !_showGameOver) _pauseGame();
    if (s == AppLifecycleState.resumed) AudioService.instance.resumeBgMusic();
  }

  void _onDied() async {
    AudioService.instance.playDie();
    AdService.instance.onPlayerDied();
    final gs = _gameKey.currentState?.gameState;
    if (gs == null) return;
    _isNewRecord = await StorageService.saveHighScore(gs.score.toInt());
    await StorageService.addCoins(gs.coins);
    await StorageService.incrementRuns();
    await StorageService.updateStreak();
    if (mounted) setState(() => _showGameOver = true);
  }

  void _onRestart() {
    setState(() { _showGameOver = false; _showPause = false; });
    _gameKey.currentState?.startNewGame();
  }

  void _onRevive() {
    if (!AdService.instance.isRewardedReady) { _doRevive(); return; }
    AdService.instance.showRewarded(onEarned: () { AudioService.instance.playRevive(); _doRevive(); }, onFailed: _doRevive);
  }

  void _onDoubleCoins() {
    final gs = _gameKey.currentState?.gameState;
    if (gs == null) { setState(() => _showGameOver = false); return; }
    if (!AdService.instance.isRewardedReady) { setState(() => _showGameOver = false); return; }
    AdService.instance.showRewarded(
      onEarned: () async {
        await StorageService.addCoins(gs.coins);
        if (mounted) setState(() => _showGameOver = false);
      },
      onFailed: () => setState(() => _showGameOver = false),
    );
  }

  void _doRevive() {
    if (!mounted) return;
    setState(() => _showGameOver = false);
    _gameKey.currentState?.revive();
  }

  void _pauseGame() {
    final gs = _gameKey.currentState?.gameState;
    if (gs == null || gs.phase != GamePhase.playing) return;
    gs.phase = GamePhase.paused;
    AudioService.instance.pauseBgMusic();
    setState(() => _showPause = true);
  }

  void _resumeGame() {
    final gs = _gameKey.currentState?.gameState;
    if (gs == null) return;
    gs.phase = GamePhase.playing;
    AudioService.instance.resumeBgMusic();
    setState(() => _showPause = false);
  }

  void _exitToMenu() {
    AudioService.instance.stopBgMusic();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final banner = AdService.instance.bannerAd;
    final gs     = _gameKey.currentState?.gameState;

    return Scaffold(
      backgroundColor: kColDark,
      body: SafeArea(
        child: Stack(
          children: [
            Column(children: [
              Expanded(child: GameWidget(
                key:              _gameKey,
                savedHighScore:   StorageService.highScore,
                onDied:           _onDied,
                onCoinCollected:  () => AudioService.instance.playCoin(),
                onBonusBird:      () => AudioService.instance.playBonus(),
                onJump:           () => AudioService.instance.playJump(),
                onCluck:          () => AudioService.instance.playCluck(),
              )),
              if (banner != null)
                SizedBox(width: banner.size.width.toDouble(), height: banner.size.height.toDouble(),
                    child: AdWidget(ad: banner))
              else
                const SizedBox(height: 50),
            ]),

            // Pause button
            Positioned(top: 10, right: 12,
              child: GestureDetector(
                onTap: _pauseGame,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12)),
                  child: const Icon(Icons.pause_rounded, color: Colors.white70, size: 22),
                ),
              ),
            ),

            if (_showGameOver && gs != null)
              GameOverOverlay(
                score: gs.score.toInt(), coins: gs.coins,
                highScore: StorageService.highScore,
                isNewRecord: _isNewRecord, reviveUsed: gs.reviveUsed,
                rewardedReady: AdService.instance.isRewardedReady,
                onRevive: _onRevive, onDoubleCoins: _onDoubleCoins,
                onRestart: _onRestart, onHome: _exitToMenu,
              ),

            if (_showPause)
              PauseOverlay(onResume: _resumeGame, onRestart: _onRestart, onHome: _exitToMenu),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioService.instance.stopBgMusic();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
