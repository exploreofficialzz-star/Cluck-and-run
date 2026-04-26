// lib/screens/widgets/pause_overlay.dart

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.72),
      child: Center(
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0d1117), Color(0xFF1a1f2e)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kColBlaze.withOpacity(0.4), width: 1.5),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏸', style: TextStyle(fontSize: 42)),
              const SizedBox(height: 8),
              const Text('PAUSED',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 24),
              _btn('▶  Resume', kColBlaze, Colors.white, onResume),
              const SizedBox(height: 10),
              _btn('🔄  Restart', const Color(0xFF1e2632), Colors.white70, onRestart),
              const SizedBox(height: 10),
              _btn('🏠  Main Menu', const Color(0xFF1e2632), Colors.white38, onHome),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
