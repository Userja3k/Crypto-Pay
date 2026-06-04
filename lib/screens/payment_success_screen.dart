import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final double amount;
  const PaymentSuccessScreen({super.key, required this.amount});

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
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(color: LiquidGlassTheme.accent, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 60, color: Colors.black),
              ),
              const SizedBox(height: 32),
              Text('Paiement Envoyé !', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 16),
              Text(
                'Vous avez envoyé \$${amount.toStringAsFixed(2)} avec succès.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),
              GlassButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Retour à l\'accueil', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
