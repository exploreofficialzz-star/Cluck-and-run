// lib/services/audio_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final _jump   = AudioPlayer();
  final _coin   = AudioPlayer();
  final _die    = AudioPlayer();
  final _revive = AudioPlayer();
  final _cluck  = AudioPlayer();
  final _crow   = AudioPlayer();
  final _bonus  = AudioPlayer();
  final _bg     = AudioPlayer();
  bool _ready   = false;

  Future<void> init() async {
    try {
      await AudioPlayer.global.setAudioContext(AudioContext(
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient,
            options: {AVAudioSessionOptions.mixWithOthers}),
        android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none,
            isSpeakerphoneOn: false, stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game),
      ));
      _ready = true;
    } catch (e) { debugPrint('[Audio] $e'); }
  }

  bool get _on => StorageService.soundEnabled && _ready;

  Future<void> playJump()  async { if (!_on) return; try { await _jump.play(AssetSource('audio/jump.mp3'), volume: 0.7); } catch(_){} }
  Future<void> playCoin()  async { if (!_on) return; try { await _coin.play(AssetSource('audio/coin.mp3'), volume: 0.6); } catch(_){} }
  Future<void> playDie()   async { if (!_on) return; try { await _die.play(AssetSource('audio/die.mp3'),  volume: 0.85); } catch(_){} }
  Future<void> playRevive()async { if (!_on) return; try { await _revive.play(AssetSource('audio/revive.mp3'), volume: 0.85); } catch(_){} }
  Future<void> playBonus() async { if (!_on) return; try { await _bonus.play(AssetSource('audio/bonus.mp3'), volume: 0.75); } catch(_){} }
  Future<void> playCluck() async {
    if (!_on) return;
    try { await _cluck.play(AssetSource('audio/cluck.mp3'), volume: 0.5); } catch(_){}
  }
  Future<void> playCockCrow() async {
    if (!_on) return;
    try { await _crow.play(AssetSource('audio/cock_crow.mp3'), volume: 0.9); } catch(_){}
  }

  Future<void> startBgMusic() async {
    if (!_on) return;
    try {
      await _bg.setReleaseMode(ReleaseMode.loop);
      await _bg.play(AssetSource('audio/bg_music.mp3'), volume: 0.32);
      // Play cock crow on game start
      Future.delayed(const Duration(milliseconds: 800), playCockCrow);
    } catch(_){}
  }
  Future<void> stopBgMusic()   async { try { await _bg.stop();   } catch(_){} }
  Future<void> pauseBgMusic()  async { try { await _bg.pause();  } catch(_){} }
  Future<void> resumeBgMusic() async { if (!_on) return; try { await _bg.resume(); } catch(_){} }

  void dispose() {
    for (final p in [_jump,_coin,_die,_revive,_cluck,_crow,_bonus,_bg]) p.dispose();
  }
}
