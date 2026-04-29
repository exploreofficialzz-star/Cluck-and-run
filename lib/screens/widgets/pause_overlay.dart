import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume, onRestart, onHome;
  const PauseOverlay({super.key, required this.onResume, required this.onRestart, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.78),
      child: Center(child: Container(
        width: 290,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0E1320), Color(0xFF1A2030)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kColBlaze.withOpacity(0.38), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30)],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('⏸', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          const Text('PAUSED', style: TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 24),
          _btn('▶  Resume',     kColBlaze,                 Colors.white,  onResume),
          const SizedBox(height: 10),
          _btn('🔄  Restart',   const Color(0xFF1E2A40),   Colors.white70, onRestart),
          const SizedBox(height: 10),
          _btn('🏠  Main Menu', const Color(0xFF131A28),   Colors.white38, onHome),
        ]),
      )),
    );
  }

  Widget _btn(String label, Color bg, Color fg, VoidCallback onTap) =>
      GestureDetector(onTap: onTap, child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13),
            boxShadow: bg == kColBlaze ? [BoxShadow(color: kColBlaze.withOpacity(0.4), blurRadius: 12, offset: const Offset(0,4))] : null),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w700)),
      ));
}
