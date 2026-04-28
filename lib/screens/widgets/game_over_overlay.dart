// lib/screens/widgets/game_over_overlay.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class GameOverOverlay extends StatefulWidget {
  final int  score, coins, highScore;
  final bool isNewRecord, reviveUsed, rewardedReady;
  final VoidCallback onRevive, onDoubleCoins, onRestart, onHome;
  const GameOverOverlay({super.key, required this.score, required this.coins,
    required this.highScore, required this.isNewRecord, required this.reviveUsed,
    required this.rewardedReady, required this.onRevive, required this.onDoubleCoins,
    required this.onRestart, required this.onHome});
  @override State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmt(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black.withOpacity(0.80),
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1a0a00), Color(0xFF2d1400)]),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: kColYolk.withOpacity(0.55), width: 2),
                boxShadow: [BoxShadow(color: kColBlaze.withOpacity(0.40), blurRadius: 36, spreadRadius: 4)],
              ),
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Header
                Image.asset(kImgChicken, width: 72, height: 72, fit: BoxFit.contain),
                const SizedBox(height: 8),
                Text(
                  widget.isNewRecord ? '🎉 NEW RECORD!' : 'CAUGHT!',
                  style: TextStyle(
                    color: widget.isNewRecord ? kColYolk : const Color(0xFFFF6B6B),
                    fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isNewRecord
                      ? 'The farmer caught you — but you set a new record!'
                      : 'The hungry farmer got you! Run faster next time!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 18),

                // Stats
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _stat('SCORE',  _fmt(widget.score),    kColYolk),
                  _stat('COINS',  '💰 ${widget.coins}', kColYolk),
                  _stat('BEST',   _fmt(widget.highScore), const Color(0xFF69F0AE)),
                ]),
                const SizedBox(height: 20),

                // Revive button (rewarded ad)
                if (!widget.reviveUsed) ...[
                  _adBtn(
                    emoji: '📺',
                    label: 'Watch Ad → Keep Running!',
                    sub: widget.rewardedReady ? null : 'Ad loading…',
                    grad: [kColYolk, kColBlaze],
                    textCol: Colors.black,
                    onTap: widget.onRevive,
                  ),
                  const SizedBox(height: 10),
                ],

                // 2× coins button (rewarded ad)
                _adBtn(
                  emoji: '📺',
                  label: 'Watch Ad → 2× Coins! 💰',
                  sub: widget.rewardedReady ? null : 'Ad loading…',
                  grad: [const Color(0xFF1B5E20), const Color(0xFF43A047)],
                  textCol: Colors.white,
                  onTap: widget.onDoubleCoins,
                ),
                const SizedBox(height: 12),

                // Play again
                _outlineBtn('🔄  Play Again', widget.onRestart),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: widget.onHome,
                  child: const Text('🏠 Main Menu',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String val, Color col) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
    const SizedBox(height: 2),
    Text(val,   style: TextStyle(color: col, fontSize: 20, fontWeight: FontWeight.w900)),
  ]);

  Widget _adBtn({required String emoji, required String label, String? sub,
    required List<Color> grad, required Color textCol, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: grad.last.withOpacity(0.45), blurRadius: 14, offset: const Offset(0,4))],
        ),
        child: Column(children: [
          Text('$emoji  $label', style: TextStyle(color: textCol, fontSize: 14, fontWeight: FontWeight.w800)),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: textCol.withOpacity(0.55), fontSize: 11)),
          ],
        ]),
      ),
    );
  }

  Widget _outlineBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24)),
      child: Text(label, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
    ),
  );
}
