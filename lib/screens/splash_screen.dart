import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../widgets/piggy_icon.dart';
import 'home_screen.dart';
import 'signin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl, curve: const Interval(0.3, 1.0, curve: Curves.easeIn)),
    );
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  Future<void> _navigate() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    final appProvider = context.read<AppProvider>();
    final navigator = Navigator.of(context);

    if (firebaseUser != null) {
      await firebaseUser.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null || !refreshedUser.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        appProvider.clearUser();
        navigator.pushReplacement(
            MaterialPageRoute(builder: (_) => const SignInScreen()));
        return;
      }

      await appProvider.loadUser(refreshedUser.uid);
      if (!mounted) return;
      if (appProvider.user?.isDisabled ?? false) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        appProvider.clearUser();
        navigator.pushReplacement(
            MaterialPageRoute(builder: (_) => const SignInScreen()));
        return;
      }
      navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const SignInScreen()));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B35),
              Color(0xFFE85D28),
              Color(0xFFFF8C5A),
            ],
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PiggyBankIcon(size: 120),
                  const SizedBox(height: 20),
                  const Text(
                    'Finbot',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your smart money companion 🐷',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white.withOpacity(0.6),
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
}
