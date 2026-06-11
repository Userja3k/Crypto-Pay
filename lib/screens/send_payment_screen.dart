import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../providers/user_provider.dart';
import 'payment_success_screen.dart';

class SendPaymentScreen extends ConsumerStatefulWidget {
  final String? initialDestination;
  const SendPaymentScreen({super.key, this.initialDestination});

  @override
  ConsumerState<SendPaymentScreen> createState() => _SendPaymentScreenState();
}

class _SendPaymentScreenState extends ConsumerState<SendPaymentScreen> {
  final _amountController = TextEditingController();
  final _destinationController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDestination != null) {
      _destinationController.text = widget.initialDestination!;
    }
  }

  Future<void> _handleSend() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      final service = ref.read(supabaseServiceProvider);
      
      final result = await service.sendPayment(
        senderUserId: authState.user?['user_id'] ?? '',
        amountUsd: amount,
        destinationType: 'internal', // Default for now
        destinationIdentifier: _destinationController.text,
        note: _noteController.text,
      );

      if (result['status'] == 'completed') {
        if (mounted) {
          ref.invalidate(userBalanceProvider(authState.user?['user_id'] ?? ''));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => PaymentSuccessScreen(amount: amount)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Échec')));
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Envoyer')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            children: [
              _buildInput('Destinataire (Email/Phone)', _destinationController),
              const SizedBox(height: 16),
              _buildInput('Montant (USD)', _amountController, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildInput('Note (Optionnel)', _noteController),
              const SizedBox(height: 48),
              _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : GlassButton(onPressed: _handleSend, child: const Text('Confirmer le Paiement', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 16,
      opacity: 0.05,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
