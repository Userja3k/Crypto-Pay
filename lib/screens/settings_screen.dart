import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';
import 'child_management_screen.dart';
import 'referral_screen.dart';
import 'parent_approval_screen.dart';
import 'kyc_submission_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _triggerHaptic() {
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          children: [
            _buildSection(context, 'Compte', [
              _buildTile(Icons.person_outline, 'Informations personnelles', 'Modifier'),
              _buildTile(Icons.verified_user_outlined, 'Vérification d\'identité (KYC)', 'Niveau 0', onTap: () {
                _triggerHaptic();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const KycSubmissionScreen()));
              }),
            ]),
            const SizedBox(height: 32),
            _buildSection(context, 'Sécurité', [
              _buildTile(Icons.lock_outline, 'Modifier le PIN', ''),
              _buildTile(Icons.password_outlined, 'Modifier le mot de passe', ''),
              _buildSwitchTile(Icons.face_retouching_natural, 'Face ID', true),
              _buildSwitchTile(Icons.fingerprint, 'Empreinte', true),
            ]),
            const SizedBox(height: 32),
            _buildSection(context, 'Paiements', [
              _buildTile(Icons.monetization_on_outlined, 'Devise principale', 'USD'),
              _buildTile(Icons.speed_outlined, 'Limites journalières', '5000\$'),
              _buildSwitchTile(Icons.security, 'Toujours demander le PIN', true),
            ]),
            const SizedBox(height: 32),
            _buildSection(context, 'Famille', [
              _buildTile(Icons.child_care_outlined, 'Gestion Enfants', 'Ajouter', onTap: () {
                _triggerHaptic();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildManagementScreen()));
              }),
              _buildTile(Icons.playlist_add_check, 'Approbations', 'Demandes', onTap: () {
                _triggerHaptic();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentApprovalScreen()));
              }),
            ]),
            const SizedBox(height: 32),
            _buildSection(context, 'Apparence', [
              _buildTile(Icons.dark_mode_outlined, 'Thème', 'Sombre'),
              _buildTile(Icons.opacity, 'Intensité Liquid Glass', 'Moyenne'),
              _buildSwitchTile(Icons.animation, 'Animations avancées', true),
            ]),
            const SizedBox(height: 32),
            _buildSection(context, 'Parrainage', [
              _buildTile(Icons.card_giftcard_outlined, 'Bonus de parrainage', 'Gagnez 5\$', onTap: () {
                _triggerHaptic();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()));
              }),
            ]),
            const SizedBox(height: 48),
            Center(
              child: TextButton(
                onPressed: () async {
                  _triggerHaptic();
                  ref.read(authProvider.notifier).logout();
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('Se déconnecter', style: TextStyle(color: LiquidGlassTheme.error, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Crypto-Pay v1.0.0\nLightning: Connecté • Serveur: Online',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 11, height: 1.5),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, String trailing, {VoidCallback? onTap}) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      borderRadius: 20,
      opacity: 0.05,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing.isNotEmpty) Text(trailing, style: const TextStyle(color: LiquidGlassTheme.accent, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool value) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      borderRadius: 20,
      opacity: 0.05,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: Switch.adaptive(
          value: value,
          onChanged: (_) => _triggerHaptic(),
          activeColor: LiquidGlassTheme.accent,
        ),
      ),
    );
  }
}
