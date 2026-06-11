import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets/glass_button.dart';
import '../services/haptic_service.dart';
import 'home_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final double amount;
  final String recipient;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.recipient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildSuccessIcon(),
              const SizedBox(height: 32),
              Text(
                'Paiement envoyé !',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Vous avez envoyé \$${amount.toStringAsFixed(2)} à $recipient.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 16),
              ),
              const Spacer(),
              GlassButton(
                onPressed: () {
                  HapticService.light();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Retour à l\'accueil'),
              ),
              const SizedBox(height: 16),
              GlassButton(
                isPrimary: false,
                onPressed: () {
                  HapticService.light();
                },
                child: const Text('Partager le reçu', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: LiquidGlassTheme.accent.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: LiquidGlassTheme.accent.withValues(alpha: 0.5), width: 2),
      ),
      child: const Center(
        child: Icon(Icons.check, color: LiquidGlassTheme.accent, size: 48),
      ),
    );
  }
}
