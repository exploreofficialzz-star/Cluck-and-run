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
  late AnimationController _bg, _logo, _chicken, _pulse;
  late Animation<double> _logoY, _pulseS;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _bg      = AnimationController(vsync:this, duration:const Duration(seconds:8))..repeat(reverse:true);
    _logo    = AnimationController(vsync:this, duration:const Duration(milliseconds:1100))..repeat(reverse:true);
    _chicken = AnimationController(vsync:this, duration:const Duration(milliseconds:500))..repeat();
    _pulse   = AnimationController(vsync:this, duration:const Duration(milliseconds:950))..repeat(reverse:true);

    _logoY  = Tween<double>(begin:0, end:-9).animate(CurvedAnimation(parent:_logo, curve:Curves.easeInOut));
    _pulseS = Tween<double>(begin:1.0, end:1.055).animate(CurvedAnimation(parent:_pulse, curve:Curves.easeInOut));
  }

  @override
  void dispose() { _bg.dispose(); _logo.dispose(); _chicken.dispose(); _pulse.dispose(); super.dispose(); }

  void _play() {
    HapticFeedback.mediumImpact();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_,__,___) => const GameScreen(),
      transitionsBuilder: (_,a,__,child) => FadeTransition(opacity:a,child:child),
      transitionDuration: const Duration(milliseconds:350),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final banner = AdService.instance.bannerAd;

    return Scaffold(
      backgroundColor: kColDark,
      body: AnimatedBuilder(
        animation: Listenable.merge([_bg, _logo, _chicken, _pulse]),
        builder: (_, __) {
          final hi     = StorageService.highScore;
          final streak = StorageService.streakDays;
          final coins  = StorageService.totalCoins;
          return Stack(children: [
            // ── Animated bg gradient ─────────────────────────────────────
            Container(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0A1628),
                Color.lerp(const Color(0xFF0F2218), const Color(0xFF1C0D02), _bg.value)!,
                const Color(0xFF070D15),
              ],
              stops: const [0, 0.55, 1],
            ))),

            // ── Road preview at bottom ────────────────────────────────────
            Positioned(bottom: 0, left: 0, right: 0, height: size.height * 0.30,
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x88000000)],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: Image.asset('assets/images/road_bg.jpg',
                    fit: BoxFit.cover, alignment: Alignment.bottomCenter),
              ),
            ),

            // ── Content ────────────────────────────────────────────────────
            SafeArea(child: Column(children: [
              const SizedBox(height: 28),

              // ── TITLE ────────────────────────────────────────────────────
              Transform.translate(offset: Offset(0, _logoY.value), child: Column(children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFFFE000), Color(0xFFFF6D00), Color(0xFFFF1744)],
                  ).createShader(b),
                  child: const Text('CLUCK & RUN', style: TextStyle(
                    color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900,
                    letterSpacing: 2.5, height: 1,
                    shadows: [Shadow(blurRadius: 12, color: Colors.black54)],
                  )),
                ),
                const SizedBox(height: 5),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🌾 ', style: TextStyle(fontSize: 14)),
                  Text('Escape the Hungry Farmer!',
                    style: TextStyle(color: Colors.white.withOpacity(0.45),
                        fontSize: 13, letterSpacing: 1.2)),
                  const Text(' 🌾', style: TextStyle(fontSize: 14)),
                ]),
              ])),

              const SizedBox(height: 30),

              // ── ANIMATED CHARACTERS PREVIEW ──────────────────────────────
              SizedBox(height: 120, child: _CharacterPreview(
                chickenAnim: _chicken.value, bgAnim: _bg.value)),

              const SizedBox(height: 30),

              // ── STATS ───────────────────────────────────────────────────
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  _StatCard(emoji:'🏆', label:'Best',   value:_fmtNum(hi)),
                  const SizedBox(width: 10),
                  _StatCard(emoji:'🔥', label:'Streak', value:'${streak}d'),
                  const SizedBox(width: 10),
                  _StatCard(emoji:'💰', label:'Coins',  value:_fmtNum(coins)),
                ])),

              const SizedBox(height: 36),

              // ── PLAY BUTTON ───────────────────────────────────────────────
              ScaleTransition(scale: _pulseS, child: GestureDetector(
                onTap: _play,
                child: Container(
                  width: 228, height: 68,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD600), Color(0xFFFF6D00)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFF6D00).withOpacity(0.7),
                          blurRadius: 28, offset: const Offset(0,8)),
                      BoxShadow(color: const Color(0xFFFFD600).withOpacity(0.25),
                          blurRadius: 10, spreadRadius: -2),
                    ],
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('▶', style: TextStyle(fontSize: 24, color: Colors.black87)),
                    SizedBox(width: 10),
                    Text('PLAY NOW', style: TextStyle(color: Colors.black87, fontSize: 23,
                        fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ]),
                ),
              )),

              const SizedBox(height: 24),

              // ── BOTTOM ACTIONS ─────────────────────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _ActionBtn(icon: Icons.leaderboard_rounded, label: 'Scores',   onTap: () {}),
                const SizedBox(width: 28),
                _ActionBtn(icon: Icons.settings_rounded,    label: 'Settings',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder:(_)=>const SettingsScreen()))
                        .then((_)=>setState((){})),
                ),
                const SizedBox(width: 28),
                _ActionBtn(icon: Icons.share_rounded, label: 'Share', onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('🐔 My best in Cluck & Run is ${StorageService.highScore}! Can you beat me?'),
                    backgroundColor: kColBlaze, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                }),
              ]),

              const Spacer(),

              // ── BANNER AD ──────────────────────────────────────────────────
              if (banner != null)
                Container(
                  width: banner.size.width.toDouble(),
                  height: banner.size.height.toDouble(),
                  decoration: BoxDecoration(color: Colors.black,
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06)))),
                  child: AdWidget(ad: banner),
                )
              else
                const SizedBox(height: 52),
            ])),
          ]);
        },
      ),
    );
  }

  String _fmtNum(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ── Animated characters preview ──────────────────────────────────────────────
class _CharacterPreview extends StatelessWidget {
  final double chickenAnim, bgAnim;
  const _CharacterPreview({required this.chickenAnim, required this.bgAnim});

  @override
  Widget build(BuildContext context) {
    final runBob  = math.sin(chickenAnim * 2 * math.pi) * 4;
    final legSwing= math.sin(chickenAnim * 2 * math.pi);

    return Stack(alignment: Alignment.center, children: [
      // Farmer (behind, slightly smaller)
      Positioned(left: MediaQuery.of(context).size.width * 0.12,
        child: Transform.translate(offset: Offset(0, -runBob * 0.6),
          child: Opacity(opacity: 0.88,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Image.asset('assets/images/farmer_nobg.png',
                  width: 62, height: 88, fit: BoxFit.contain),
              // animated legs under farmer
              CustomPaint(size: const Size(50, 22),
                  painter: _LegPainter(swing: legSwing, isChicken: false)),
            ]),
          ),
        ),
      ),

      // Distance label
      Positioned(left: MediaQuery.of(context).size.width * 0.28,
        top: 50,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.35)),
          ),
          child: const Text('CHASING!', style: TextStyle(
              color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ),
      ),

      // Chicken (center, larger)
      Positioned(right: MediaQuery.of(context).size.width * 0.14,
        child: Transform.translate(offset: Offset(0, -runBob),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Transform(
              transform: Matrix4.identity()
                ..scale(1.0 + (math.sin(chickenAnim * 2 * math.pi * 2).abs() * 0.04), 1.0),
              alignment: Alignment.center,
              child: Image.asset('assets/images/chicken_sprite.png',
                  width: 80, height: 80, fit: BoxFit.contain),
            ),
            CustomPaint(size: const Size(70, 28),
                painter: _LegPainter(swing: legSwing, isChicken: true)),
          ]),
        ),
      ),

      // Motion lines (speed effect)
      ...List.generate(4, (i) {
        final yo = -30.0 + i * 18;
        final xo = math.sin(chickenAnim * 2 * math.pi + i) * 6;
        return Positioned(
          left: MediaQuery.of(context).size.width * 0.12 + xo,
          top: 45 + yo,
          child: Opacity(opacity: 0.3,
            child: Container(width: 22, height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.transparent, kColYolk.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(1),
                )),
          ),
        );
      }),
    ]);
  }
}

class _LegPainter extends CustomPainter {
  final double swing;
  final bool isChicken;
  const _LegPainter({required this.swing, required this.isChicken});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = isChicken ? const Color(0xFFE8A020) : const Color(0xFF0D47A1)
      ..strokeWidth = isChicken ? 2.8 : 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    for (int i = 0; i < 2; i++) {
      final phase = i == 0 ? swing : -swing;
      final lx = cx + (i == 0 ? -size.width*0.12 : size.width*0.12);
      final ky = size.height * 0.45 - phase.abs() * size.height * 0.25;
      final fx = lx + phase * size.width * 0.14;
      canvas.drawLine(Offset(lx, 0), Offset((lx+fx)/2, ky), p);
      canvas.drawLine(Offset((lx+fx)/2, ky), Offset(fx, size.height * 0.9), p);
    }
  }

  @override bool shouldRepaint(covariant _LegPainter o) => o.swing != swing;
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  const _StatCard({required this.emoji, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.055),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.09)),
    ),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 21)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: kColYolk, fontSize: 19, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
    ]),
  ));
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(width: 54, height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Icon(icon, color: Colors.white70, size: 25)),
      const SizedBox(height: 5),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
    ]),
  );
}
