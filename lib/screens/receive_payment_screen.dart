import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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

  void _triggerHaptic() {
    HapticFeedback.mediumImpact();
  }

  void _generateInvoice() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    _triggerHaptic();
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
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        title: const Text('Recevoir des fonds', style: TextStyle(fontWeight: FontWeight.bold))
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            children: [
              const SizedBox(height: 20),
              GlassContainer(
                padding: const EdgeInsets.all(40),
                borderRadius: 32,
                opacity: 0.1,
                child: Column(
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.qr_code_2, 
                          size: 160, 
                          color: Colors.white.withValues(alpha: _bolt11 == null ? 0.2 : 0.9)
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _bolt11 == null ? 'Générer une facture pour afficher le QR' : 'Scanner pour me payer', 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                borderRadius: 20,
                opacity: 0.05,
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Montant souhaité (USD)',
                    labelStyle: TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: Icon(Icons.attach_money, color: LiquidGlassTheme.accent),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading 
                ? const CircularProgressIndicator(color: LiquidGlassTheme.accent)
                : GlassButton(onPressed: _generateInvoice, child: const Text('Générer une Facture Lightning', style: TextStyle(fontWeight: FontWeight.bold))),
              
              if (_bolt11 != null) ...[
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ADRESSE LIGHTNING', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 16,
                  opacity: 0.1,
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _bolt11!, 
                          style: const TextStyle(color: LiquidGlassTheme.accent, fontSize: 12, fontFamily: 'Geist'),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _bolt11!));
                          HapticFeedback.vibrate();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copié dans le presse-papier')));
                        },
                        icon: const Icon(Icons.copy, size: 20, color: Colors.white54),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        onPressed: () => HapticFeedback.lightImpact(),
                        isPrimary: false,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.share, size: 18), SizedBox(width: 8), Text('Partager')],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GlassButton(
                        onPressed: () => HapticFeedback.lightImpact(),
                        isPrimary: false,
                        child: const Text('Demander par SMS'),
                      ),
                    ),
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
