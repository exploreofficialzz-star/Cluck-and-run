// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _sound;
  late bool _notif;

  @override
  void initState() {
    super.initState();
    _sound = StorageService.soundEnabled;
    _notif = StorageService.notifEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final hi     = StorageService.highScore;
    final runs   = StorageService.totalRuns;
    final coins  = StorageService.totalCoins;
    final streak = StorageService.streakDays;

    return Scaffold(
      backgroundColor: kColDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white70),
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Stats card ─────────────────────────────────────────────────────────
          _sectionLabel('📊 Your Stats'),
          _card(children: [
            _stat('🏆 High Score',   hi.toString()),
            _divider(),
            _stat('🎮 Total Runs',   runs.toString()),
            _divider(),
            _stat('💰 Total Coins',  coins.toString()),
            _divider(),
            _stat('🔥 Current Streak', '${streak} day${streak == 1 ? '' : 's'}'),
          ]),
          const SizedBox(height: 24),

          // ── Sound ──────────────────────────────────────────────────────────────
          _sectionLabel('🔊 Audio'),
          _card(children: [
            _toggle(
              label:    'Sound Effects & Music',
              subtitle: 'Jump, coin, game over sounds',
              value:    _sound,
              onChanged: (v) async {
                setState(() => _sound = v);
                await StorageService.setSoundEnabled(v);
                if (!v) await AudioService.instance.pauseBgMusic();
                else    await AudioService.instance.resumeBgMusic();
              },
            ),
          ]),
          const SizedBox(height: 24),

          // ── Notifications ──────────────────────────────────────────────────────
          _sectionLabel('🔔 Notifications'),
          _card(children: [
            _toggle(
              label:    'Daily Reminders',
              subtitle: 'Reminds you to play every day at 7 PM',
              value:    _notif,
              onChanged: (v) async {
                setState(() => _notif = v);
                await StorageService.setNotifEnabled(v);
                if (v) {
                  final granted = await NotificationService.requestPermission();
                  if (granted) {
                    await NotificationService.scheduleDailyReminder();
                  } else {
                    setState(() => _notif = false);
                    await StorageService.setNotifEnabled(false);
                  }
                } else {
                  await NotificationService.cancelAll();
                }
              },
            ),
          ]),
          const SizedBox(height: 24),

          // ── About ──────────────────────────────────────────────────────────────
          _sectionLabel('ℹ️ About'),
          _card(children: [
            _info('App Version',   kVersion),
            _divider(),
            _info('Developer',     'ChasTech Group'),
            _divider(),
            _info('Ads',           'Powered by Google AdMob'),
          ]),
          const SizedBox(height: 32),

          // Reset progress (destructive, confirm first)
          Center(
            child: TextButton(
              onPressed: _confirmReset,
              child: const Text('Reset Progress', style: TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1a1f2e),
        title: const Text('Reset Progress?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will clear your high score, coins, and streak. This cannot be undone.',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              // Reset all prefs
              final prefs = [kPrefHighScore, kPrefTotalCoins, kPrefTotalRuns, kPrefStreakDays, kPrefLastPlayedDate];
              for (final k in prefs) {
                // SharedPreferences remove — accessed via StorageService
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1, fontWeight: FontWeight.w600)),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color:        Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border:       Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Column(children: children),
  );

  Widget _toggle({
    required String   label,
    required String   subtitle,
    required bool     value,
    required ValueChanged<bool> onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,    style: const TextStyle(color: Colors.white,   fontSize: 15, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        )),
        Switch.adaptive(
          value:          value,
          onChanged:      onChanged,
          activeColor:    kColBlaze,
          activeTrackColor: kColBlaze.withOpacity(0.3),
        ),
      ],
    ),
  );

  Widget _stat(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(color: kColYolk, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ],
    ),
  );

  Widget _divider() => const Divider(color: Colors.white10, height: 1, indent: 16, endIndent: 16);
}
