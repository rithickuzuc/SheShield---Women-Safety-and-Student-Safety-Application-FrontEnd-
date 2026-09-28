import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sheshield/models/login_response.dart';
import 'package:sheshield/screens/home_screen.dart';
import 'package:sheshield/screens/login_screen.dart';
import 'package:sheshield/services/auth_service.dart';
import 'package:sheshield/services/push_notification_service.dart';
import 'package:sheshield/navigation/app_navigator.dart';
import 'package:sheshield/ui/sheshield_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SheShieldApp());
  _initializeFirebase();
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 8));
    await PushNotificationService.instance
        .initialize()
        .timeout(const Duration(seconds: 8));
    await PushNotificationService.instance.openInitialNotification();
  } catch (_) {
    // Login/dashboard must remain available even if Firebase is temporarily offline.
  }
}

class SheShieldApp extends StatelessWidget {
  const SheShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = SheShieldColors.wine;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: const Color(0xFFFFF8FC),
    );

    return MaterialApp(
      navigatorKey: AppNavigator.key,
      title: 'SheShield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, centerTitle: false, titleTextStyle: TextStyle(color: SheShieldColors.ink, fontSize: 22, fontWeight: FontWeight.w800), iconTheme: IconThemeData(color: SheShieldColors.ink)),
        cardTheme: CardThemeData(elevation: 0, color: Colors.white.withValues(alpha: .82), surfaceTintColor: Colors.transparent, shadowColor: SheShieldColors.wine.withValues(alpha: .12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: .8)))),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder(), TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(), TargetPlatform.windows: FadeForwardsPageTransitionsBuilder()}),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: .88),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE4D8DE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE4D8DE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: primary, width: 1.6),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: SheShieldColors.wine,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      builder: (context, child) => SheShieldBackground(child: child ?? const SizedBox.shrink()),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<LoginResponse?> _session = AuthService().readSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _AnimatedSplash();
        }
        final session = snapshot.data;
        return session == null
            ? const LoginScreen()
            : HomeScreen(user: session);
      },
    );
  }
}

class _AnimatedSplash extends StatefulWidget { const _AnimatedSplash(); @override State<_AnimatedSplash> createState() => _AnimatedSplashState(); }
class _AnimatedSplashState extends State<_AnimatedSplash> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat(reverse: true);
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: AnimatedBuilder(animation: controller, builder: (_, child) => Transform.scale(scale: .92 + controller.value * .10, child: Opacity(opacity: .75 + controller.value * .25, child: child)), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 110, height: 110, decoration: BoxDecoration(gradient: const LinearGradient(colors: [SheShieldColors.rose, SheShieldColors.violet]), borderRadius: BorderRadius.circular(34), boxShadow: [BoxShadow(color: SheShieldColors.rose.withValues(alpha: .35), blurRadius: 30, spreadRadius: 5)]), child: const Icon(Icons.shield_rounded, color: Colors.white, size: 66)), const SizedBox(height: 22), const Text('SheShield', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: SheShieldColors.wine)), const SizedBox(height: 6), const Text('Your safety. Always connected.', style: TextStyle(color: Colors.black54))]))));
}
