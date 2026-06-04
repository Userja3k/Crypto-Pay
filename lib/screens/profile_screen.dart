import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/user_provider.dart';
import 'kyc_submission_screen.dart';
import 'referral_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final fullName = user?['full_name'] ?? 'Jean';
    final userId = user?['user_id']?.toString().substring(0, 8).toUpperCase() ?? '587491';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 40),
              _buildAvatarSection(context, user),
              const SizedBox(height: 16),
              Text(
                fullName.split(' ')[0],
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              _buildIdSection(context, 'CP-$userId'),
              const SizedBox(height: 32),
              _buildActionButtons(context),
              const SizedBox(height: 32),
              _buildMenuSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Bonjour, Jean 👋',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 24),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined, size: 28),
        ),
      ],
    );
  }

  Widget _buildAvatarSection(BuildContext context, Map<String, dynamic>? user) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10, width: 2),
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white24,
            child: ClipOval(
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDwzUbqC4QgFkWcZCWJaw-nVRdq2IySRgc5dSCC2OLP1S7EqhURwsuQIBNOujaG11As66OFxvTBoxhYi-Glg3Z9EQWVFwPLRgCsszmFC7GVbovRwmmRF6fdVAZKaB97wyNTKqrW3jCzw9UH1HurXoYA-DsbqTRfzA71mkED36rW2CGpbnzZDQOb5RRGAkm6GYCZ--rBFD0V-EziDb2Y4Ovu88npZnchalO-5W2-EI8cEoZpmNCUPC8a__cP-S4h4976tNyMS9keyKs',
                fit: BoxFit.cover,
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: LiquidGlassTheme.accent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: LiquidGlassTheme.accent.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 14, color: Colors.black),
                SizedBox(width: 4),
                Text(
                  'Niveau 3',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdSection(BuildContext context, String id) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID copié !'), duration: Duration(seconds: 1)),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            id,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.copy, size: 16, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, color: Colors.black),
          SizedBox(width: 8),
          Text(
            'Ajouter aux favoris',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildMenuTile(Icons.edit_outlined, 'Modifier profil', onTap: () {}),
          const Divider(color: Colors.white10, indent: 56),
          _buildMenuTile(Icons.description_outlined, 'Documents', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const KycSubmissionScreen()));
          }),
          const Divider(color: Colors.white10, indent: 56),
          _buildMenuTile(Icons.security_outlined, 'Sécurité', showDot: true, onTap: () {}),
          const Divider(color: Colors.white10, indent: 56),
          _buildMenuTile(Icons.card_giftcard_outlined, 'Parrainage', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, {bool showDot = false, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: const BoxDecoration(color: LiquidGlassTheme.accent, shape: BoxShape.circle),
            ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }
}
