import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../services/haptic_service.dart';
import '../providers/user_provider.dart';
import '../services/share_service.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final code = authState.user?['referral_code'] ?? '—';

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Parrainage')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.card_giftcard, size: 80, color: LiquidGlassTheme.accent),
              const SizedBox(height: 24),
              Text('Gagnez 5\$ par ami', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              const Text(
                'Partagez votre code avec vos proches. Ils reçoivent 2\$ à l\'inscription et vous recevez 5\$ après leur premier paiement.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 48),
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('VOTRE CODE', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(code, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    GlassButton(onPressed: () {
                      HapticService.selection();
                      final auth = ref.read(authProvider);
                      final svc = ShareService();
                      svc.shareReferralCode(code: code, userName: auth.user?['full_name'] ?? 'Utilisateur');
                    }, child: const Text('Partager mon code'))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
