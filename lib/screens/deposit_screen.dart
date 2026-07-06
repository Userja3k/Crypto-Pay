import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../providers/user_provider.dart';
import '../services/haptic_service.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitDeposit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant valide.')),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final userId = authState.user?['user_id'] as String?;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non authentifié.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticService.medium();

    try {
      final result = await ref.read(supabaseServiceProvider).depositFunds(
            userId: userId,
            amountUsd: amount,
            note: _noteController.text.isNotEmpty ? _noteController.text : 'Recharge de compte',
          );

      if (result['status'] == 'completed') {
        HapticService.success();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Compte alimenté avec succès.')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Impossible de recharger le compte.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de recharge : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Alimenter le compte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajoutez des fonds à votre compte Crypto-Pay.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              borderRadius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Montant', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: TextStyle(color: Colors.white54, fontSize: 22),
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              borderRadius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Note', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Ex: Recharge via partenaire',
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(),
            const SizedBox(height: 32),
            GlassButton(
              onPressed: _isLoading ? null : _submitDeposit,
              child: Text(_isLoading ? 'Traitement...' : 'Alimenter le compte'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      opacity: 0.08,
      child: const Text(
        'Ce flux permet d’alimenter votre compte rapidement. Pour la version finale, remplacez cette action par un partenaire de paiement externe (PSP) comme un agrégateur ou une API de carte bancaire).',
        style: TextStyle(color: Colors.white54, height: 1.5),
      ),
    );
  }
}
