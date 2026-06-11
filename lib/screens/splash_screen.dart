import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/user_provider.dart';
import 'welcome_screen.dart';
import 'home_screen.dart';
import 'dart:math' as math;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      final authState = ref.read(authProvider);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => authState.isAuthenticated ? const HomeScreen() : const WelcomeScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo: White circle on black, Bold B inclined 80deg left, "opening" the circle
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(-10, 0), // Push slightly left to "open" the circle
                      child: Transform.rotate(
                        angle: -80 * (math.pi / 180),
                        child: const Text(
                          '₿',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 110,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Crypto-Pay',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'LIQUID ASSETS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 6,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 64),
              const Text(
                'Tous droits réservés',
                style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
