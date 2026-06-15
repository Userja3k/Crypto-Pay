import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets/glass_button.dart';
import '../core/widgets/crypto_pay_logo.dart';
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
              const CryptoPayLogo(size: 100),
              const SizedBox(height: 24),
              Text('Bienvenue sur\nCrypto-Pay', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36, height: 1.2)),
              const SizedBox(height: 12),
              const Text(
                'Envoyez et recevez de l\'argent instantanément.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 16, height: 1.4),
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
