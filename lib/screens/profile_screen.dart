import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/user_provider.dart';
import '../services/share_service.dart';
import '../services/haptic_service.dart';
import 'transaction_history_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileCard(user),
            const SizedBox(height: 32),
            _buildStatsSection(user),
            const SizedBox(height: 32),
            _buildActionsList(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic>? user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: LiquidGlassTheme.accent, width: 2),
                image: const DecorationImage(
                  image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDwzUbqC4QgFkWcZCWJaw-nVRdq2IySRgc5dSCC2OLP1S7EqhURwsuQIBNOujaG11As66OFxvTBoxhYi-Glg3Z9EQWVFwPLRgCsszmFC7GVbovRwmmRF6fdVAZKaB97wyNTKqrW3jCzw9UH1HurXoYA-DsbqTRfzA71mkED36rW2CGpbnzZDQOb5RRGAkm6GYCZ--rBFD0V-EziDb2Y4Ovu88npZnchalO-5W2-EI8cEoZpmNCUPC8a__cP-S4h4976tNyMS9keyKs'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: LiquidGlassTheme.accent, shape: BoxShape.circle),
              child: const Icon(Icons.edit, size: 16, color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(user?['full_name'] ?? 'Jean Kasavubu', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(user?['email'] ?? '—', style: const TextStyle(color: Colors.white38)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: LiquidGlassTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LiquidGlassTheme.accent.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, size: 14, color: LiquidGlassTheme.accent),
              SizedBox(width: 6),
              Text('Utilisateur Vérifié', style: TextStyle(color: LiquidGlassTheme.accent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(Map<String, dynamic>? user) {
    return Row(
      children: [
        _statItem('Envoyé', '---'),
        const SizedBox(width: 16),
        _statItem('Reçu', '---'),
        const SizedBox(width: 16),
        _statItem('Transactions', '0'),
      ],
    );
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsList(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      borderRadius: 24,
      child: Column(
        children: [
          _actionTile(Icons.history, 'Historique complet', () {
            HapticService.selection();
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()));
          }),
          _actionTile(Icons.account_balance_wallet_outlined, 'Mes portefeuilles', () {
            HapticService.selection();
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()));
          }),
          _actionTile(Icons.qr_code_scanner, 'Mon code QR', () {
            HapticService.selection();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code QR disponible dans Recevoir')),
            );
          }),
          _actionTile(Icons.share, 'Partager mon profil', () async {
            HapticService.selection();
            final auth = ref.read(authProvider);
            final svc = ShareService();
            svc.shareProfile(userName: auth.user?['full_name'] ?? 'Utilisateur', userId: auth.user?['id'] ?? '-', referralCode: auth.user?['referral_code'] ?? '-');
          }),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () {
          HapticService.selection();
          onTap();
        },
      ),
    );
  }
}
