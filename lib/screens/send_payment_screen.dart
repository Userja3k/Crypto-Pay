import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../services/haptic_service.dart';
import '../providers/user_provider.dart';
import 'payment_success_screen.dart';

class SendPaymentScreen extends ConsumerStatefulWidget {
  final String? recipientId;
  final String? recipientName;

  const SendPaymentScreen({super.key, this.recipientId, this.recipientName});

  @override
  ConsumerState<SendPaymentScreen> createState() => _SendPaymentScreenState();
}

class _SendPaymentScreenState extends ConsumerState<SendPaymentScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _destinationController = TextEditingController();

  bool _isLoading = false;
  String _paymentMethod = 'internal'; // 'internal' or 'lightning'

  @override
  void initState() {
    super.initState();
    if (widget.recipientName != null) {
      _destinationController.text = widget.recipientName!;
    }
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);
    HapticService.medium();

    try {
      final authState = ref.read(authProvider);
      final result = await ref.read(supabaseServiceProvider).sendPayment(
        senderUserId: authState.user!['user_id'],
        amountUsd: amount,
        destinationType: _paymentMethod,
        destinationIdentifier: widget.recipientId ?? _destinationController.text,
        note: _noteController.text,
      );

      if (result['status'] == 'completed') {
        HapticService.success();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => PaymentSuccessScreen(amount: amount, recipient: widget.recipientName ?? _destinationController.text))
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${result['message']}')),
          );
        }
      }
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
        title: const Text('Envoyer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Montant à envoyer', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 16),
            _buildAmountInput(),
            const SizedBox(height: 32),
            const Text('Destinataire', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 12),
            _buildDestinationInput(),
            const SizedBox(height: 24),
            _buildNoteInput(),
            const SizedBox(height: 48),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accent))
            else
              _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 20),
      borderRadius: 24,
      child: Center(
        child: IntrinsicWidth(
          child: TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: const InputDecoration(
              prefixText: '\$',
              prefixStyle: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white24),
              border: InputBorder.none,
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.white10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationInput() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: 16,
      child: TextField(
        controller: _destinationController,
        readOnly: widget.recipientId != null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'ID, Email ou Adresse Lightning',
          border: InputBorder.none,
          icon: const Icon(Icons.person_outline, color: LiquidGlassTheme.accent),
          suffixIcon: widget.recipientId == null ? const Icon(Icons.qr_code_scanner, color: Colors.white38) : null,
        ),
      ),
    );
  }

  Widget _buildNoteInput() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: 16,
      child: TextField(
        controller: _noteController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Ajouter une note (optionnel)',
          border: InputBorder.none,
          icon: Icon(Icons.sticky_note_2_outlined, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Frais de réseau', style: TextStyle(color: Colors.white38)),
            Text('\$0.15', style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 24),
        GlassButton(
          onPressed: _processPayment,
          child: const Text('Glisser pour payer', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
