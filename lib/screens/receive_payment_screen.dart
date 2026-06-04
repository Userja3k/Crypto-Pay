import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../providers/user_provider.dart';

class ReceivePaymentScreen extends ConsumerStatefulWidget {
  const ReceivePaymentScreen({super.key});

  @override
  ConsumerState<ReceivePaymentScreen> createState() => _ReceivePaymentScreenState();
}

class _ReceivePaymentScreenState extends ConsumerState<ReceivePaymentScreen> {
  final _amountController = TextEditingController();
  String? _bolt11;
  bool _isLoading = false;

  void _generateInvoice() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      final service = ref.read(supabaseServiceProvider);
      final result = await service.createLightningInvoice(
        userId: authState.user?['user_id'] ?? '',
        amountUsd: amount,
      );

      setState(() {
        _bolt11 = result['bolt11'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Recevoir')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      color: Colors.white12,
                      child: const Center(child: Icon(Icons.qr_code, size: 100, color: Colors.white54)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Scanner pour me payer', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                borderRadius: 16,
                opacity: 0.05,
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Montant souhaité (USD)',
                    labelStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GlassButton(onPressed: _generateInvoice, child: const Text('Générer une Facture Lightning')),
              if (_bolt11 != null) ...[
                const SizedBox(height: 24),
                SelectableText(_bolt11!, style: const TextStyle(color: LiquidGlassTheme.accent, fontSize: 12, fontFamily: 'Geist')),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
