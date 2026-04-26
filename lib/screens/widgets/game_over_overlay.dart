// lib/screens/widgets/game_over_overlay.dart

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class GameOverOverlay extends StatefulWidget {
  final int  score;
  final int  coins;
  final int  highScore;
  final bool isNewRecord;
  final bool reviveUsed;
  final bool rewardedReady;
  final VoidCallback onRevive;
  final VoidCallback onDoubleCoins;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.coins,
    required this.highScore,
    required this.isNewRecord,
    required this.reviveUsed,
    required this.rewardedReady,
    required this.onRevive,
    required this.onDoubleCoins,
    required this.onRestart,
    required this.onHome,
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmt(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black.withOpacity(0.78),
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1a0a00), Color(0xFF2d1400)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kColYolk.withOpacity(0.55), width: 2),
                boxShadow: [
                  BoxShadow(color: kColBlaze.withOpacity(0.35), blurRadius: 32, spreadRadius: 4),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon + title
                  const Text('🐔💥', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 6),
                  Text(
                    widget.isNewRecord ? '🎉 NEW RECORD!' : 'CAUGHT!',
                    style: TextStyle(
                      color:      widget.isNewRecord ? kColYolk : const Color(0xFFFF6B6B),
                      fontSize:   28, fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isNewRecord
                        ? 'The farmer caught you — but you set a new high score!'
                        : 'The hungry farmer got you!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 18),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statBox('SCORE',  _fmt(widget.score),    kColYolk),
                      _statBox('COINS',  '💰 ${widget.coins}', kColYolk),
                      _statBox('BEST',   _fmt(widget.highScore), const Color(0xFF69F0AE)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Revive button (rewarded)
                  if (!widget.reviveUsed) ...[
                    _adButton(
                      icon:    '📺',
                      label:   'Watch Ad → Keep Running!',
                      color:   kColYolk,
                      textClr: Colors.black,
                      onTap:   widget.onRevive,
                      badge:   widget.rewardedReady ? null : 'Ad loading…',
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 2× coins button (rewarded)
                  _adButton(
                    icon:    '📺',
                    label:   'Watch Ad → 2× Coins! 💰',
                    color:   const Color(0xFF1B5E20),
                    textClr: Colors.white,
                    onTap:   widget.onDoubleCoins,
                    badge:   widget.rewardedReady ? null : 'Ad loading…',
                  ),
                  const SizedBox(height: 12),

                  // Play again
                  _outlineButton(
                    label: '🔄  Play Again',
                    onTap: widget.onRestart,
                  ),
                  const SizedBox(height: 8),

                  // Home
                  GestureDetector(
                    onTap: widget.onHome,
                    child: const Text(
                      '🏠 Main Menu',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _adButton({
    required String icon,
    required String label,
    required Color  color,
    required Color  textClr,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 14, offset: const Offset(0,4))],
        ),
        child: Column(
          children: [
            Text('$icon  $label', style: TextStyle(color: textClr, fontSize: 15, fontWeight: FontWeight.w800)),
            if (badge != null) ...[
              const SizedBox(height: 2),
              Text(badge, style: TextStyle(color: textClr.withOpacity(0.6), fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _outlineButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
