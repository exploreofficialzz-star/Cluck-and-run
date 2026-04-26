// lib/screens/widgets/hud_overlay.dart
// (HUD is drawn directly on canvas in game_widget.dart for performance,
//  but this widget is used for the settings toggle row above the game canvas.)

import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/audio_service.dart';
import '../../utils/constants.dart';

class SettingsRow extends StatefulWidget {
  const SettingsRow({super.key});

  @override
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  bool _sound = true;

  @override
  void initState() {
    super.initState();
    _sound = StorageService.soundEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _iconToggle(
            icon:    _sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            active:  _sound,
            tooltip: 'Toggle Sound',
            onTap: () async {
              setState(() => _sound = !_sound);
              await StorageService.setSoundEnabled(_sound);
              if (!_sound) await AudioService.instance.pauseBgMusic();
              else         await AudioService.instance.resumeBgMusic();
            },
          ),
        ],
      ),
    );
  }

  Widget _iconToggle({
    required IconData icon,
    required bool     active,
    required String   tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: active ? kColBlaze.withOpacity(0.18) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? kColBlaze.withOpacity(0.5) : Colors.white12),
          ),
          child: Icon(icon, color: active ? kColBlaze : Colors.white30, size: 20),
        ),
      ),
    );
  }
}
