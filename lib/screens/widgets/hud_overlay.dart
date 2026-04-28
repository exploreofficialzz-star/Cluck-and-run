// lib/screens/widgets/hud_overlay.dart
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/audio_service.dart';
import '../../utils/constants.dart';

class SettingsRow extends StatefulWidget {
  const SettingsRow({super.key});
  @override State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  late bool _sound;
  @override void initState() { super.initState(); _sound = StorageService.soundEnabled; }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        GestureDetector(
          onTap: () async {
            setState(() => _sound = !_sound);
            await StorageService.setSoundEnabled(_sound);
            if (!_sound) await AudioService.instance.pauseBgMusic();
            else         await AudioService.instance.resumeBgMusic();
          },
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _sound ? kColBlaze.withOpacity(0.18) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _sound ? kColBlaze.withOpacity(0.5) : Colors.white12),
            ),
            child: Icon(_sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: _sound ? kColBlaze : Colors.white30, size: 20),
          ),
        ),
      ]),
    );
  }
}
