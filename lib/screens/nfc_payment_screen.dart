import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../core/widgets/water_drop_success_overlay.dart';
import '../providers/payment_provider.dart';
import '../services/haptic_service.dart';

class NfcPaymentScreen extends ConsumerStatefulWidget {
  final bool initialReceiving;
  const NfcPaymentScreen({super.key, this.initialReceiving = false});

  @override
  ConsumerState<NfcPaymentScreen> createState() => _NfcPaymentScreenState();
}

class _NfcPaymentScreenState extends ConsumerState<NfcPaymentScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late bool _isReceiving;

  @override
  void initState() {
    super.initState();
    _isReceiving = widget.initialReceiving;
  }

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
        const SnackBar(
            content: Text('Veuillez saisir un montant en sats valide.')),
      );
      return;
    }

    HapticService.medium();

    if (_isReceiving) {
      await ref.read(nfcPaymentProvider.notifier).receiveWithNfc(
            amountSats: amount,
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
          );
    } else {
      await ref.read(nfcPaymentProvider.notifier).payWithNfc(
            amountSats: amount,
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
          );
    }

    final success = ref.read(nfcPaymentProvider).status == NfcStatus.success;
    if (success && mounted) {
      WaterDropSuccessOverlay.show(context, () {
        // L'animation de la goutte d'eau a été jouée
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(nfcPaymentProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Paiement NFC'),
        actions: [
          ToggleButtons(
            isSelected: [!_isReceiving, _isReceiving],
            onPressed: (index) {
              setState(() {
                _isReceiving = index == 1;
              });
              ref.read(nfcPaymentProvider.notifier).reset();
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Payer'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Recevoir'),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isReceiving
                  ? 'Écrivez une facture sur une tag NFC'
                  : 'Scannez une tag NFC contenant une facture',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            _buildAmountInput(),
            const SizedBox(height: 20),
            _buildNoteInput(),
            const SizedBox(height: 24),
            GlassButton(
              onPressed: paymentState.isLoading ? null : _submitPayment,
              child: Text(
                paymentState.isLoading
                    ? _isReceiving
                        ? 'Écriture en cours...'
                        : 'Lecture en cours...'
                    : _isReceiving
                        ? 'Écrire sur NFC'
                        : 'Lire NFC',
              ),
            ),
            const SizedBox(height: 24),
            _buildStatusCard(paymentState),
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

  Widget _buildStatusCard(NfcPaymentState state) {
    if (state.status == NfcStatus.success) {
      return GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                SizedBox(width: 8),
                Text('Paiement réussi',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (state.paymentHash != null && state.paymentHash!.isNotEmpty)
              Text('Hash: ${state.paymentHash}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (state.amountSats != null)
              Text('Montant: ${state.amountSats} sats',
                  style: const TextStyle(color: Colors.white70)),
            if (state.counterpartyName != null)
              Text('De: ${state.counterpartyName}',
                  style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            GlassButton(
              onPressed: () => ref.read(nfcPaymentProvider.notifier).reset(),
              child: const Text('Nouvelle opération'),
            ),
          ],
        ),
      );
    }

    if (state.status == NfcStatus.failure) {
      return GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text('Erreur',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(state.error ?? 'Erreur inconnue',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            GlassButton(
              onPressed: () => ref.read(nfcPaymentProvider.notifier).reset(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.isLoading) {
      return GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(color: LiquidGlassTheme.accent),
            const SizedBox(height: 12),
            Text(
              _isReceiving
                  ? 'Approchez la tag NFC...'
                  : 'En attente de la tag NFC...',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
