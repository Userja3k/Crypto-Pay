import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../services/haptic_service.dart';
import 'about_screen.dart';
import 'child_management_screen.dart';
import 'parent_approval_screen.dart';
import 'kyc_submission_screen.dart';
import 'referral_screen.dart';
import 'profile_screen.dart';
import 'welcome_screen.dart';
import '../providers/user_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _glassIntensity = 1.0;
  bool _faceId = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Paramètres'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          children: [
            _buildSection('Compte', [
              _buildTile(Icons.person_outline, 'Profil', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
              }),
              _buildTile(Icons.verified_user_outlined, 'Vérification (KYC)', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const KycSubmissionScreen()));
              }),
              _buildTile(Icons.family_restroom, 'Crypto-Famille', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildManagementScreen()));
              }),
              _buildTile(Icons.approval, 'Approbations parentales', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentApprovalScreen()));
              }),
              _buildTile(Icons.group_add_outlined, 'Parrainage', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()));
              }),
            ]),
            const SizedBox(height: 24),
            _buildSection('Sécurité', [
              _buildTile(Icons.lock_outline, 'Modifier le code PIN', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Modification du code PIN non disponible pour le moment')),
                );
              }),
              SwitchListTile(
                title: const Text('Face ID / Empreinte'),
                value: _faceId,
                onChanged: (v) => setState(() => _faceId = v),
                activeThumbColor: LiquidGlassTheme.accent,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('Apparence', [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Intensité Liquid Glass', style: TextStyle(color: Colors.white70)),
                    Slider(
                      value: _glassIntensity,
                      max: 2,
                      divisions: 2,
                      label: _intensityLabel(),
                      activeColor: LiquidGlassTheme.accent,
                      onChanged: (v) => setState(() => _glassIntensity = v),
                    ),
                  ],
                ),
              ),
              _buildTile(Icons.translate, 'Langue', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('L\'application utilise le français')),
                );
              }),
            ]),
            const SizedBox(height: 24),
            _buildSection('Support', [
              _buildTile(Icons.help_outline, 'Centre d\'aide', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Centre d\'aide non disponible pour le moment')),
                );
              }),
              _buildTile(Icons.info_outline, 'À propos', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
              }),
            ]),
            const SizedBox(height: 48),
            TextButton(
              onPressed: () {
                HapticService.medium();
                ref.read(authProvider.notifier).logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Déconnexion', style: TextStyle(color: LiquidGlassTheme.error, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _intensityLabel() {
    if (_glassIntensity == 0) return 'Faible';
    if (_glassIntensity == 1) return 'Moyenne';
    return 'Forte';
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.2)),
        ),
        GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: () {
        HapticService.selection();
        onTap();
      },
    );
  }
}
