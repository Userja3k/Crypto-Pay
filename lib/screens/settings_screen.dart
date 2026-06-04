import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Paramètres')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          children: [
            _buildSection(context, 'Compte', [
              _buildTile(Icons.verified_user_outlined, 'Vérification d\'identité (KYC)', 'Niveau 0', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const KycSubmissionScreen()));
              }),
              _buildTile(Icons.lock_outline, 'Changer le PIN', ''),
            ]),
            const SizedBox(height: 32),
            _buildSection(context, 'Famille', [
              _buildTile(Icons.child_care_outlined, 'Gestion Enfants', 'Ajouter', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildManagementScreen()));
              }),
              _buildTile(Icons.playlist_add_check, 'Approbations', 'Demandes', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentApprovalScreen()));
              }),
            ]),
            const SizedBox(height: 32),
            _buildSection(context, 'Parrainage', [
              _buildTile(Icons.card_giftcard_outlined, 'Bonus de parrainage', 'Gagnez 5\$', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()));
              }),
            ]),
            const SizedBox(height: 48),
            TextButton(
              onPressed: () async {
                ref.read(authProvider.notifier).logout();
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Se déconnecter', style: TextStyle(color: LiquidGlassTheme.error)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, String trailing, {VoidCallback? onTap}) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      borderRadius: 16,
      opacity: 0.05,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(trailing, style: const TextStyle(color: LiquidGlassTheme.accent, fontSize: 12)),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
