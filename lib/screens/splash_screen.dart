import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/user_provider.dart';
import 'welcome_screen.dart';
import 'home_screen.dart';

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
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.bolt, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'Crypto-Pay',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'LIQUID ASSETS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 4,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
