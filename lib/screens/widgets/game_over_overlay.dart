// lib/screens/widgets/game_over_overlay.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class GameOverOverlay extends StatefulWidget {
  final int  score, coins, highScore;
  final bool isNewRecord, reviveUsed, rewardedReady;
  final VoidCallback onRevive, onDoubleCoins, onRestart, onHome;
  const GameOverOverlay({super.key,
    required this.score, required this.coins, required this.highScore,
    required this.isNewRecord, required this.reviveUsed, required this.rewardedReady,
    required this.onRevive, required this.onDoubleCoins, required this.onRestart, required this.onHome});
  @override State<GameOverOverlay> createState() => _State();
}

class _State extends State<GameOverOverlay> with TickerProviderStateMixin {
  late AnimationController _entry, _pulse;
  late Animation<double> _scale, _fade, _pulseA;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(vsync:this, duration:const Duration(milliseconds:400));
    _pulse = AnimationController(vsync:this, duration:const Duration(milliseconds:800))..repeat(reverse:true);
    _scale = CurvedAnimation(parent:_entry, curve:Curves.elasticOut);
    _fade  = CurvedAnimation(parent:_entry, curve:Curves.easeIn);
    _pulseA= Tween<double>(begin:0.9,end:1.0).animate(_pulse);
    _entry.forward();
  }
  @override void dispose() { _entry.dispose(); _pulse.dispose(); super.dispose(); }

  String _fmt(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),(m)=>'${m[1]},');

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade,
      child: Container(
        color: Colors.black.withOpacity(0.82),
        child: Center(
          child: ScaleTransition(scale: _scale,
            child: Container(
              width: 330,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1C0A00), Color(0xFF2E1600), Color(0xFF1A1000)],
                  stops: [0, 0.55, 1],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: kColYolk.withOpacity(0.50), width: 1.8),
                boxShadow: [
                  BoxShadow(color: kColBlaze.withOpacity(0.45), blurRadius: 40, spreadRadius: 2),
                  BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // ── Header ───────────────────────────────────────────────────
                Image.asset('assets/images/chicken_sprite.png', width: 72, height: 72),
                const SizedBox(height: 8),

                if (widget.isNewRecord)
                  ScaleTransition(scale: _pulseA,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kColYolk, kColBlaze]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('🎉 NEW RECORD!',
                          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                  )
                else
                  Text('CAUGHT!', style: TextStyle(
                    color: const Color(0xFFFF6B6B), fontSize: 30, fontWeight: FontWeight.w900,
                    shadows: [Shadow(blurRadius: 12, color: kColRed.withOpacity(0.5))],
                  )),

                const SizedBox(height: 4),
                Text(
                  widget.isNewRecord
                    ? 'The farmer caught you — but you crushed your record!'
                    : 'The farmer got you. Run faster next time! 🏃',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                ),
                const SizedBox(height: 18),

                // ── Stats row ─────────────────────────────────────────────────
                Row(children: [
                  _StatBox('SCORE', _fmt(widget.score), kColYolk),
                  _vDivider(),
                  _StatBox('COINS', '💰 ${widget.coins}', kColYolk),
                  _vDivider(),
                  _StatBox('BEST', _fmt(widget.highScore), const Color(0xFF69F0AE)),
                ]),
                const SizedBox(height: 20),

                // ── AD BUTTONS (aggressive, professional) ────────────────────
                // 1. Revive — highest value rewarded ad
                if (!widget.reviveUsed) ...[
                  _AdBtn(
                    icon: '📺', label: 'Watch Ad — Keep Running!',
                    sublabel: widget.rewardedReady ? 'Ad ready ✓' : 'Loading ad…',
                    colors: [const Color(0xFFFFD600), const Color(0xFFFF6D00)],
                    textColor: Colors.black,
                    onTap: widget.onRevive,
                  ),
                  const SizedBox(height: 10),
                ],

                // 2. Double coins rewarded
                _AdBtn(
                  icon: '📺', label: 'Watch Ad — Double Coins! 💰',
                  sublabel: widget.rewardedReady ? '+${widget.coins} bonus coins' : 'Loading ad…',
                  colors: [const Color(0xFF1B5E20), const Color(0xFF43A047)],
                  textColor: Colors.white,
                  onTap: widget.onDoubleCoins,
                ),
                const SizedBox(height: 14),

                // 3. Play again (free, but less prominent)
                GestureDetector(
                  onTap: widget.onRestart,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.20)),
                    ),
                    child: const Text('🔄  Play Again',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: widget.onHome,
                  child: const Text('🏠 Main Menu',
                      style: TextStyle(color: Colors.white30, fontSize: 13)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(width:1, height:40, color:Colors.white.withOpacity(0.10),
      margin: const EdgeInsets.symmetric(horizontal:8));
}

class _StatBox extends StatelessWidget {
  final String label, value; final Color color;
  const _StatBox(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
    const SizedBox(height: 3),
    Text(value, style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w900),
        maxLines: 1, overflow: TextOverflow.ellipsis),
  ]));
}

class _AdBtn extends StatelessWidget {
  final String icon, label, sublabel;
  final List<Color> colors; final Color textColor;
  final VoidCallback onTap;
  const _AdBtn({required this.icon, required this.label, required this.sublabel,
      required this.colors, required this.textColor, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: colors.last.withOpacity(0.50), blurRadius: 16, offset: const Offset(0,5))],
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w800)),
          Text(sublabel, style: TextStyle(color: textColor.withOpacity(0.60), fontSize: 11)),
        ])),
        Icon(Icons.play_circle_filled_rounded, color: textColor.withOpacity(0.75), size: 26),
      ]),
    ),
  );
}
