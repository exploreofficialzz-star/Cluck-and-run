// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _sound, _notif;
  @override void initState() { super.initState(); _sound = StorageService.soundEnabled; _notif = StorageService.notifEnabled; }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColDark,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
          leading: const BackButton(color: Colors.white70),
          title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _label('📊 Your Stats'),
        _card([
          _stat('🏆 High Score',    StorageService.highScore.toString()),
          _div(),
          _stat('🎮 Total Runs',    StorageService.totalRuns.toString()),
          _div(),
          _stat('💰 Total Coins',   StorageService.totalCoins.toString()),
          _div(),
          _stat('🔥 Streak',        '${StorageService.streakDays} day${StorageService.streakDays == 1 ? "" : "s"}'),
        ]),
        const SizedBox(height: 24),

        _label('🔊 Audio'),
        _card([_toggle('Sound Effects & Music', 'Clucks, jump, coin, background music', _sound, (v) async {
          setState(() => _sound = v);
          await StorageService.setSoundEnabled(v);
          if (!v) await AudioService.instance.pauseBgMusic();
          else    await AudioService.instance.resumeBgMusic();
        })]),
        const SizedBox(height: 24),

        _label('🔔 Notifications'),
        _card([_toggle('Daily Reminders', 'Get nudged to play every day at 7 PM', _notif, (v) async {
          setState(() => _notif = v);
          await StorageService.setNotifEnabled(v);
          if (v) { final ok = await NotificationService.requestPermission(); if (ok) await NotificationService.scheduleDailyReminder(); else setState(() => _notif = false); }
          else   await NotificationService.cancelAll();
        })]),
        const SizedBox(height: 24),

        _label('ℹ️ About'),
        _card([
          _info('App Version', kVersion),
          _div(),
          _info('Developer', 'ChasTech Group'),
          _div(),
          _info('Ads', 'Powered by Google AdMob'),
        ]),
        const SizedBox(height: 32),

        Center(child: TextButton(
          onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1a1f2e),
            title: const Text('Reset Progress?', style: TextStyle(color: Colors.white)),
            content: const Text('This will clear your high score, coins, and streak. Cannot be undone.',
                style: TextStyle(color: Colors.white54)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              TextButton(onPressed: () async { await StorageService.clearAll(); if (mounted) { Navigator.pop(context); setState(() {}); } },
                  child: const Text('Reset', style: TextStyle(color: Colors.red))),
            ],
          )),
          child: const Text('Reset Progress', style: TextStyle(color: Colors.red, fontSize: 13)),
        )),
      ]),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(t, style: const TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1, fontWeight: FontWeight.w600)));

  Widget _card(List<Widget> c) => Container(
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07))),
    child: Column(children: c),
  );

  Widget _toggle(String label, String sub, bool val, ValueChanged<bool> cb) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        Text(sub,   style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ])),
      Switch.adaptive(value: val, onChanged: cb, activeColor: kColBlaze, activeTrackColor: kColBlaze.withOpacity(0.3)),
    ]),
  );

  Widget _stat(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Text(l, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      const Spacer(),
      Text(v, style: const TextStyle(color: kColYolk, fontSize: 14, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _info(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Text(l, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      const Spacer(),
      Text(v, style: const TextStyle(color: Colors.white38, fontSize: 13)),
    ]),
  );

  Widget _div() => const Divider(color: Colors.white10, height: 1, indent: 16, endIndent: 16);
}
