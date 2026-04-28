// lib/main.dart
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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await StorageService.init();
  await Future.wait([
    AdService.instance.init(),
    AudioService.instance.init(),
    NotificationService.init(),
  ]);
  if (StorageService.notifEnabled) await NotificationService.scheduleDailyReminder();
  runApp(const CluckAndRunApp());
}

class CluckAndRunApp extends StatelessWidget {
  const CluckAndRunApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(primary: kColBlaze, secondary: kColYolk),
        scaffoldBackgroundColor: kColDark,
      ),
      home: const SplashGate(),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MenuScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ));
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColDark,
      body: Center(
        child: FadeTransition(opacity: _fade,
          child: ScaleTransition(scale: _scale,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFE066), kColBlaze, Color(0xFFC43E00)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: kColBlaze.withOpacity(0.6), blurRadius: 45, spreadRadius: 4)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(kImgChicken, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 28),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(colors: [kColYolk, kColBlaze]).createShader(b),
                child: const Text('CLUCK & RUN', style: TextStyle(color: Colors.white, fontSize: 38,
                    fontWeight: FontWeight.w900, letterSpacing: 3)),
              ),
              const SizedBox(height: 6),
              const Text('by ChasTech Group',
                  style: TextStyle(color: Colors.white24, fontSize: 13, letterSpacing: 2)),
              const SizedBox(height: 52),
              SizedBox(width: 150, child: LinearProgressIndicator(
                  backgroundColor: Colors.white12, color: kColBlaze,
                  borderRadius: BorderRadius.circular(4))),
            ]),
          ),
        ),
      ),
    );
  }
}
