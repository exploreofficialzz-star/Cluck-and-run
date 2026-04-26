// lib/services/audio_service.dart
// Manages all in-game sound effects using audioplayers.
// Falls back gracefully if audio is unavailable.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final _jumpPlayer   = AudioPlayer();
  final _coinPlayer   = AudioPlayer();
  final _diePlayer    = AudioPlayer();
  final _revivePlayer = AudioPlayer();
  final _bgPlayer     = AudioPlayer();

  bool _ready = false;

  Future<void> init() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
          android: AudioContextAndroid(
            audioFocus: AndroidAudioFocus.none,
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('[Audio] Init warning: $e');
    }
  }

  bool get _soundOn => StorageService.soundEnabled && _ready;

  Future<void> playJump() async {
    if (!_soundOn) return;
    try {
      await _jumpPlayer.play(AssetSource('audio/jump.mp3'), volume: 0.7);
    } catch (_) {}
  }

  Future<void> playCoin() async {
    if (!_soundOn) return;
    try {
      await _coinPlayer.play(AssetSource('audio/coin.mp3'), volume: 0.6);
    } catch (_) {}
  }

  Future<void> playDie() async {
    if (!_soundOn) return;
    try {
      await _diePlayer.play(AssetSource('audio/die.mp3'), volume: 0.8);
    } catch (_) {}
  }

  Future<void> playRevive() async {
    if (!_soundOn) return;
    try {
      await _revivePlayer.play(AssetSource('audio/revive.mp3'), volume: 0.8);
    } catch (_) {}
  }

  Future<void> startBgMusic() async {
    if (!_soundOn) return;
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.play(AssetSource('audio/bg_music.mp3'), volume: 0.35);
    } catch (_) {}
  }

  Future<void> stopBgMusic() async {
    try { await _bgPlayer.stop(); } catch (_) {}
  }

  Future<void> pauseBgMusic() async {
    try { await _bgPlayer.pause(); } catch (_) {}
  }

  Future<void> resumeBgMusic() async {
    if (!_soundOn) return;
    try { await _bgPlayer.resume(); } catch (_) {}
  }

  void dispose() {
    _jumpPlayer.dispose();
    _coinPlayer.dispose();
    _diePlayer.dispose();
    _revivePlayer.dispose();
    _bgPlayer.dispose();
  }
}
