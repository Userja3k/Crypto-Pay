import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../providers/payment_provider.dart';
import '../services/haptic_service.dart';

class NfcPaymentScreen extends ConsumerStatefulWidget {
  const NfcPaymentScreen({super.key});

  @override
  ConsumerState<NfcPaymentScreen> createState() => _NfcPaymentScreenState();
}

class _NfcPaymentScreenState extends ConsumerState<NfcPaymentScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant en sats valide.')),
      );
      return;
    }

    HapticService.medium();
    // start payment and show snackbar with progress
    ref.read(nfcPaymentProvider.notifier).payWithNfc(
          amountSats: amount,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En attente du tag NFC...')));
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(nfcPaymentProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Paiement NFC'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scanner un tag NFC contenant une facture Lightning', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            _buildAmountInput(),
            const SizedBox(height: 20),
            _buildNoteInput(),
            const SizedBox(height: 24),
            GlassButton(
              onPressed: paymentState.isLoading
                  ? () {}
                  : () {
                      _submitPayment();
                    },







              child: Text(paymentState.isLoading ? 'En attente du tag...' : 'Démarrer le paiement NFC'),
            ),
            const SizedBox(height: 24),
            if (paymentState.status == PaymentStatus.success)
              GlassContainer(
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Paiement réussi', style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Hash : ${paymentState.paymentHash}', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('Sats envoyés : ${paymentState.amountSats}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            if (paymentState.status == PaymentStatus.failure)
              GlassContainer(
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erreur : ${paymentState.error}', style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 20,
      child: TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Montant en sats',
          hintStyle: TextStyle(color: Colors.white38),
          prefixIcon: Icon(Icons.payments_outlined, color: Colors.white38),
        ),
      ),
    );
  }

  Widget _buildNoteInput() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 20,
      child: TextField(
        controller: _noteController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Note (optionnel)',
          hintStyle: TextStyle(color: Colors.white38),
          prefixIcon: Icon(Icons.sticky_note_2_outlined, color: Colors.white38),
        ),
      ),
    );
  }
}
