import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/user_provider.dart';
import '../services/haptic_service.dart';

class ReceivePaymentScreen extends ConsumerStatefulWidget {
  const ReceivePaymentScreen({super.key});

  @override
  ConsumerState<ReceivePaymentScreen> createState() => _ReceivePaymentScreenState();
}

class _ReceivePaymentScreenState extends ConsumerState<ReceivePaymentScreen> {
  final _amountController = TextEditingController();
  String? _bolt11;
  bool _isLoading = false;

  Future<void> _generateInvoice() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);
    HapticService.selection();

    try {
      final authState = ref.read(authProvider);
      final result = await ref.read(supabaseServiceProvider).createLightningInvoice(
        userId: authState.user!['user_id'],
        amountUsd: amount,
      );
      setState(() => _bolt11 = result['bolt11']);
      HapticService.success();
    } catch (e) {
      debugPrint('Invoice error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userAddress = "CP-${authState.user?['referral_code'] ?? '123456'}";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Recevoir'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          children: [
            _buildQRCodeSection(userAddress),
            const SizedBox(height: 32),
            _buildRequestSection(),
            const SizedBox(height: 32),
            _buildExternalLinksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection(String address) {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: 32,
          child: Column(
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.qr_code_2, size: 180, color: Colors.black),
              ),
              const SizedBox(height: 24),
              Text(address, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              const Text('Votre ID Crypto-Pay unique', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _actionIconButton(Icons.copy, 'Copier'),
            const SizedBox(width: 24),
            _actionIconButton(Icons.share, 'Partager'),
          ],
        ),
      ],
    );
  }

  Widget _actionIconButton(IconData icon, String label) {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(12),
          borderRadius: 16,
          opacity: 0.1,
          child: Icon(icon, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _buildRequestSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Demander un montant', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    prefixText: '\$ ',
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_isLoading)
                const CircularProgressIndicator(color: LiquidGlassTheme.accent)
              else
                IconButton(
                  onPressed: _generateInvoice,
                  icon: const Icon(Icons.arrow_forward, color: LiquidGlassTheme.accent),
                ),
            ],
          ),
          if (_bolt11 != null) ...[
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Text(
              _bolt11!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExternalLinksSection() {
    final authState = ref.watch(authProvider);
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            leading: const Icon(Icons.bolt, color: Colors.orange),
            title: const Text('Adresse Lightning'),
            subtitle: Text(authState.user?['email'] ?? '—'),
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: () {
              HapticService.selection();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Adresse Lightning non disponible pour le moment')),
              );
            },
          ),
        ),
      ],
    );
  }
}
