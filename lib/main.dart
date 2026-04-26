// lib/main.dart
// App entry point — initialises all services before the first frame.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/storage_service.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'screens/menu_screen.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait on launch; game screen switches to landscape
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Transparent status/nav bars
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:           Colors.transparent,
    statusBarBrightness:      Brightness.dark,
    statusBarIconBrightness:  Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialise services in parallel where safe
  await StorageService.init();

  await Future.wait([
    AdService.instance.init(),
    AudioService.instance.init(),
    NotificationService.init(),
  ]);

  // Schedule daily reminder if user enabled it
  if (StorageService.notifEnabled) {
    await NotificationService.scheduleDailyReminder();
  }

  runApp(const CluckAndRunApp());
}

class CluckAndRunApp extends StatelessWidget {
  const CluckAndRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:        kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3:       true,
        colorScheme:        ColorScheme.dark(primary: kColBlaze, secondary: kColYolk),
        scaffoldBackgroundColor: kColDark,
        fontFamily:         'sans-serif',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SplashGate(),
    );
  }
}

// ── Splash gate — brief branded splash then route to menu ────────────────────
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();

    // Navigate after 2 seconds
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:       (_, __, ___) => const MenuScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColDark,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE066), kColBlaze, Color(0xFFC43E00)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: kColBlaze.withOpacity(0.55), blurRadius: 40, spreadRadius: 4),
                    ],
                  ),
                  child: const Center(child: Text('🐔', style: TextStyle(fontSize: 64))),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [kColYolk, kColBlaze],
                  ).createShader(b),
                  child: const Text(
                    'CLUCK & RUN',
                    style: TextStyle(
                      color:       Colors.white,
                      fontSize:    36,
                      fontWeight:  FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('by ChasTech Group',
                  style: TextStyle(color: Colors.white24, fontSize: 13, letterSpacing: 2)),
                const SizedBox(height: 48),
                SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(
                    backgroundColor:  Colors.white12,
                    color:            kColBlaze,
                    borderRadius:     BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
