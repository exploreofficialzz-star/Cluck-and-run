import 'dart:math' as math;
// lib/screens/menu_screen.dart
// Animated main menu with high score, streak, settings, and banner ad.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _logoCtrl;
  late Animation<double>   _logoBounce;
  late Animation<double>   _logoFloat;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _logoBounce = Tween<double>(begin: 0, end: -12).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut));
    _logoFloat = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ).then((_) => setState(() {})); // refresh on return
  }

  @override
  Widget build(BuildContext context) {
    final hi     = StorageService.highScore;
    final streak = StorageService.streakDays;
    final coins  = StorageService.totalCoins;
    final banner = AdService.instance.bannerAd;
    final size   = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kColDark,
      body: Stack(
        children: [
          // ── Animated gradient bg ─────────────────────────────────────────────
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0a1628),
                    Color.lerp(const Color(0xFF0d2b1a), const Color(0xFF1a0d00), _floatAnim.value)!,
                  ],
                ),
              ),
            ),
          ),

          // ── Floating farm scene ───────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0, height: size.height * 0.38,
            child: CustomPaint(painter: _FarmScenePainter(t: _floatAnim.value)),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ── Logo ─────────────────────────────────────────────────────────
                AnimatedBuilder(
                  animation: _logoBounce,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _logoBounce.value),
                    child: _Logo(),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Stats row ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      _statCard('🏆', 'Best',   hi.toString()),
                      const SizedBox(width: 12),
                      _statCard('🔥', 'Streak', '${streak}d'),
                      const SizedBox(width: 12),
                      _statCard('💰', 'Coins',  coins.toString()),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── Play button ──────────────────────────────────────────────────
                _PlayButton(onTap: _startGame),

                const SizedBox(height: 18),

                // ── Secondary actions ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _iconBtn(Icons.leaderboard_rounded, 'Scores',  () {}),
                    const SizedBox(width: 20),
                    _iconBtn(Icons.settings_rounded,    'Settings', _openSettings),
                    const SizedBox(width: 20),
                    _iconBtn(Icons.share_rounded,       'Share',    _onShare),
                  ],
                ),

                const Spacer(),

                // ── Banner Ad ────────────────────────────────────────────────────
                if (banner != null)
                  SizedBox(
                    width:  banner.size.width.toDouble(),
                    height: banner.size.height.toDouble(),
                    child:  AdWidget(ad: banner),
                  )
                else
                  const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Animation<double> get _floatAnim => _bgCtrl;

  void _onShare() {
    final hi = StorageService.highScore;
    HapticFeedback.lightImpact();
    // In production you'd use share_plus package here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🐔 My best in Cluck & Run is $hi! Can you beat me?'),
        backgroundColor: kColBlaze,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _statCard(String icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Text(icon,  style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: kColYolk, fontSize: 18, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: Colors.white70, size: 24),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Logo widget ───────────────────────────────────────────────────────────────
class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('🐔', style: TextStyle(fontSize: 72)),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [kColYolk, kColBlaze, Color(0xFFFF1744)],
          ).createShader(b),
          child: const Text('CLUCK & RUN',
            style: TextStyle(
              color:       Colors.white,
              fontSize:    42,
              fontWeight:  FontWeight.w900,
              letterSpacing: 2,
              height:      1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text('🌾  Escape the Hungry Farmer!  🌾',
          style: TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 1)),
      ],
    );
  }
}

// ── Play button ───────────────────────────────────────────────────────────────
class _PlayButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 220, height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kColYolk, kColBlaze],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: kColBlaze.withOpacity(0.6), blurRadius: 24, offset: const Offset(0, 8)),
              BoxShadow(color: kColYolk.withOpacity(0.3), blurRadius: 12, spreadRadius: -4),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('▶', style: TextStyle(fontSize: 22, color: Colors.black)),
              SizedBox(width: 10),
              Text('PLAY NOW',
                style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Background farm scene painter ─────────────────────────────────────────────
class _FarmScenePainter extends CustomPainter {
  final double t;
  const _FarmScenePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {

    // Sky gradient at bottom of menu
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, const Color(0xFF0a1e12).withOpacity(0.9)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), sky);

    // Rolling hills
    final hillPaint = Paint()..color = const Color(0xFF1a3d22).withOpacity(0.9);
    final path = Path()..moveTo(0, size.height * 0.45);
    for (double x = 0; x <= size.width; x += 12) {
      path.lineTo(x, size.height * 0.45 + math.sin((x * 0.01) + t * 2) * 18);
    }
    path..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(path, hillPaint);

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
      Paint()..color = const Color(0xFF0d1a0e),
    );
  }

  @override
  bool shouldRepaint(covariant _FarmScenePainter old) => old.t != t;
}
