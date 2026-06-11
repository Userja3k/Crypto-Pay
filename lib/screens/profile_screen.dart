import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/user_provider.dart';

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
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => HapticFeedback.lightImpact(),
            icon: const Icon(Icons.edit_outlined),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildAvatar(user),
              const SizedBox(height: 24),
              Text(
                user?['full_name'] ?? 'Utilisateur',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: LiquidGlassTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LiquidGlassTheme.accent.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: LiquidGlassTheme.accent),
                    SizedBox(width: 6),
                    Text('Vérifié Niveau 1', style: TextStyle(color: LiquidGlassTheme.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ID: CP-587491', // Placeholder as per logic
                style: TextStyle(color: Colors.white38, fontSize: 14, fontFamily: 'Geist'),
              ),
              const SizedBox(height: 48),
              _buildStatRow(),
              const SizedBox(height: 48),
              _buildActionList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic>? user) {
    return Center(
      child: Stack(
        children: [
          GlassContainer(
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(4),
            opacity: 0.1,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white10,
              backgroundImage: const NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDwzUbqC4QgFkWcZCWJaw-nVRdq2IySRgc5dSCC2OLP1S7EqhURwsuQIBNOujaG11As66OFxvTBoxhYi-Glg3Z9EQWVFwPLRgCsszmFC7GVbovRwmmRF6fdVAZKaB97wyNTKqrW3jCzw9UH1HurXoYA-DsbqTRfzA71mkED36rW2CGpbnzZDQOb5RRGAkm6GYCZ--rBFD0V-EziDb2Y4Ovu88npZnchalO-5W2-EI8cEoZpmNCUPC8a__cP-S4h4976tNyMS9keyKs'),
              child: user == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => HapticFeedback.mediumImpact(),
              child: GlassContainer(
                shape: BoxShape.circle,
                padding: const EdgeInsets.all(10),
                opacity: 0.2,
                blur: 10,
                child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statItem('Transactions', '124'),
        Container(width: 1, height: 40, color: Colors.white10),
        _statItem('Amis', '12'),
        Container(width: 1, height: 40, color: Colors.white10),
        _statItem('Bonus', '\$45'),
      ],
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionList(BuildContext context) {
    return Column(
      children: [
        _actionTile(Icons.person_outline, 'Modifier mon profil', () {}),
        _actionTile(Icons.description_outlined, 'Mes documents', () {}),
        _actionTile(Icons.shield_outlined, 'Sécurité avancée', () {}),
        _actionTile(Icons.card_giftcard_outlined, 'Parrainage', () {}),
      ],
    );
  }

  Widget _actionTile(IconData icon, String title, VoidCallback onTap) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 20,
      opacity: 0.05,
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 16),
      ),
    );
  }
}
