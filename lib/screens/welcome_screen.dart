import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets/glass_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.bolt, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text('Crypto-Pay', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 40)),
              const SizedBox(height: 8),
              const Text(
                'Le mobile money du Bitcoin en Afrique.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),
              GlassButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              GlassButton(
                isPrimary: false,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Créer un compte', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
