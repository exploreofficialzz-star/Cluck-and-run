import 'dart:math' as math;
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
  @override State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _bgCtrl, _logoCtrl, _chickenCtrl;
  late Animation<double> _logoBounce, _chickenRun;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _bgCtrl      = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _logoCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _chickenCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..repeat();
    _logoBounce  = Tween<double>(begin: 0, end: -10).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut));
    _chickenRun  = CurvedAnimation(parent: _chickenCtrl, curve: Curves.linear);
  }

  @override
  void dispose() { _bgCtrl.dispose(); _logoCtrl.dispose(); _chickenCtrl.dispose(); super.dispose(); }

  void _play() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const GameScreen(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hi = StorageService.highScore; final streak = StorageService.streakDays; final coins = StorageService.totalCoins;
    final banner = AdService.instance.bannerAd;

    return Scaffold(
      backgroundColor: kColDark,
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, __) => Stack(children: [
          // BG gradient
          Container(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [const Color(0xFF0a1628),
                Color.lerp(const Color(0xFF0d2b1a), const Color(0xFF1a0d00), _bgCtrl.value)!]))),

          // Farm background image  
          Positioned(bottom: 0, left: 0, right: 0,
            child: Opacity(opacity: 0.18,
              child: Image.asset(kImgFarmBg, fit: BoxFit.cover, height: 260))),

          SafeArea(child: Column(children: [
            const SizedBox(height: 32),

            // Animated logo
            AnimatedBuilder(animation: _logoBounce, builder: (_, __) =>
              Transform.translate(offset: Offset(0, _logoBounce.value), child: _buildLogo())),

            const SizedBox(height: 28),

            // Animated chicken preview
            AnimatedBuilder(animation: _chickenRun, builder: (_, __) =>
              SizedBox(height: 100, child: Stack(alignment: Alignment.center, children: [
                // Farmer chasing (small, behind)
                Positioned(left: 40,
                  child: Opacity(opacity: 0.7,
                    child: Image.asset(kImgFarmer, width: 55, height: 75, fit: BoxFit.contain))),
                // Chicken running (centre)
                Positioned(left: 110 + math.sin(_chickenRun.value * 2 * math.pi) * 4,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..scale(1.0 + math.sin(_chickenRun.value * 2 * math.pi * 2).abs() * 0.04, 1.0),
                    alignment: Alignment.center,
                    child: Image.asset(kImgChicken, width: 72, height: 88, fit: BoxFit.contain))),
              ]))),

            const SizedBox(height: 22),

            // Stats row
            Padding(padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(children: [
                _stat('🏆', 'Best',   hi.toString()),
                const SizedBox(width: 10),
                _stat('🔥', 'Streak', '${streak}d'),
                const SizedBox(width: 10),
                _stat('💰', 'Coins',  coins.toString()),
              ])),

            const SizedBox(height: 32),
            _PlayButton(onTap: _play),
            const SizedBox(height: 22),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _iconBtn(Icons.leaderboard_rounded, 'Scores',  () {}),
              const SizedBox(width: 22),
              _iconBtn(Icons.settings_rounded,    'Settings', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())).then((_) => setState(() {}))),
              const SizedBox(width: 22),
              _iconBtn(Icons.share_rounded,       'Share',    _share),
            ]),

            const Spacer(),
            if (banner != null)
              SizedBox(width: banner.size.width.toDouble(), height: banner.size.height.toDouble(), child: AdWidget(ad: banner))
            else
              const SizedBox(height: 50),
          ])),
        ]),
      ),
    );
  }

  Widget _buildLogo() => Column(children: [
    ShaderMask(
      shaderCallback: (b) => const LinearGradient(colors: [kColYolk, kColBlaze, Color(0xFFFF1744)]).createShader(b),
      child: const Text('CLUCK & RUN', style: TextStyle(color: Colors.white, fontSize: 40,
          fontWeight: FontWeight.w900, letterSpacing: 2.5, height: 1)),
    ),
    const SizedBox(height: 4),
    const Text('🌾  Escape the Hungry Farmer!  🌾',
        style: TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 1)),
  ]);

  Widget _stat(String icon, String label, String value) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08))),
    child: Column(children: [
      Text(icon,  style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(color: kColYolk, fontSize: 18, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
    ]),
  ));

  Widget _iconBtn(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(width: 52, height: 52,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12)),
        child: Icon(icon, color: Colors.white70, size: 24)),
      const SizedBox(height: 5),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
    ]),
  );

  void _share() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🐔 My best in Cluck & Run is ${StorageService.highScore}! Can you beat me?'),
      backgroundColor: kColBlaze, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

class _PlayButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});
  @override State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _p;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true); _p = Tween<double>(begin:1.0,end:1.05).animate(CurvedAnimation(parent:_c,curve:Curves.easeInOut)); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _p,
    child: GestureDetector(onTap: widget.onTap,
      child: Container(width: 220, height: 66,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kColYolk, kColBlaze], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(33),
          boxShadow: [BoxShadow(color: kColBlaze.withOpacity(0.65), blurRadius: 28, offset: const Offset(0,8)),
                      BoxShadow(color: kColYolk.withOpacity(0.3),  blurRadius: 12, spreadRadius: -4)]),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('▶', style: TextStyle(fontSize: 22, color: Colors.black)),
          SizedBox(width: 10),
          Text('PLAY NOW', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ]),
      ),
    ),
  );
}
