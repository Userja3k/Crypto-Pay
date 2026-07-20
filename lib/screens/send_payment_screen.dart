import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:breez_sdk/bridge_generated.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/payment_confirm_slider.dart';
import '../core/widgets/water_drop_success_overlay.dart';
import '../services/haptic_service.dart';
import '../providers/user_provider.dart';
import '../core/utils/ui_utils.dart';
import 'payment_success_screen.dart';
import 'qr_scanner_screen.dart';

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
  String? _validationError;
  final String _paymentMethod = 'internal';

  @override
  void initState() {
    super.initState();
    if (widget.recipientName != null) {
      _destinationController.text = widget.recipientName!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  bool _isBolt11Invoice(String destination) {
    final normalized = destination.toLowerCase();
    return normalized.startsWith('lnbc') ||
        normalized.startsWith('lntb') ||
        normalized.startsWith('lnsb') ||
        normalized.startsWith('lnbcrt');
  }

  Future<void> _handleQRScan() async {
    HapticService.selection();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          onScanComplete: (code) async {
            await _validateAndSetDestination(code);
          },
        ),
      ),
    );
  }

  Future<void> _validateAndSetDestination(String code) async {
    setState(() {
      _isLoading = true;
      _validationError = null;
    });

    try {
      bool isValid = false;
      String cleanCode = code.trim();

      // 1. Check if it's a Lightning Invoice (BOLT11)
      if (_isBolt11Invoice(cleanCode)) {
        isValid = true; // Breez will validate it further
      } else {
        // 2. Check if it's a valid Crypto-Pay user (ID, Email, or Lightning Address)
        final supabase = ref.read(supabaseServiceProvider);
        
        // Search for user
        final users = await supabase.searchUsers(cleanCode);
        if (users.isNotEmpty) {
          isValid = true;
          // If we found exact match, use the ID
          final exactMatch = users.firstWhere(
            (u) => u['email'] == cleanCode || u['phone'] == cleanCode || u['id'] == cleanCode,
            orElse: () => users.first,
          );
          cleanCode = exactMatch['id'] ?? cleanCode;
        } else {
          // Check if it's a Lightning Address registered in our system
          final laService = ref.read(lightningAddressServiceProvider);
          final userId = await laService.getUserIdFromAddress(cleanCode);
          if (userId != null) {
            isValid = true;
            cleanCode = userId;
          }
        }
      }

      if (isValid) {
        _destinationController.text = cleanCode;
        HapticService.success();
        if (mounted) {
          _showSuccessPopup('Code validé', 'Le destinataire a été identifié avec succès.');
        }
      } else {
        setState(() {
          _validationError = 'Informations invalides : Destinataire introuvable';
        });
        HapticService.medium();
      }
    } catch (e) {
      setState(() {
        _validationError = 'Erreur lors de la validation';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GÉNIAL', style: TextStyle(color: LiquidGlassTheme.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);
    HapticService.medium();

    try {
      final destination =
          (widget.recipientId ?? _destinationController.text).trim();
      if (destination.isEmpty) throw Exception('Destinataire manquant');

      final authState = ref.read(authProvider);
      final userId = authState.userId;
      if (userId == null) throw Exception('Utilisateur non authentifié');

      if (_isBolt11Invoice(destination)) {
        final breez = ref.read(breezServiceProvider);
        final invoice = await breez.parseInvoice(destination);

        final bool hasAmount = invoice.amountMsat != null;
        final int? amountMsat =
            hasAmount ? null : (amount > 0 ? (amount * 1000).round() : null);

        final response = await breez.sendPaymentWithRetry(
          bolt11: destination,
          amountMsat: amountMsat,
          useTrampoline: true,
          label: _noteController.text.isNotEmpty ? _noteController.text : null,
        );

        if (response.payment.status == PaymentStatus.Complete) {
          if (mounted) {
            WaterDropSuccessOverlay.show(context, () {
              _showSuccess(amount, destination);
            });
          }
        } else {
          throw Exception(response.payment.error ?? 'Paiement échoué');
        }
      } else {
        // Paiement interne
        final result = await ref.read(supabaseServiceProvider).sendPayment(
              senderUserId: userId,
              amountUsd: amount,
              destinationType: _paymentMethod,
              destinationIdentifier: destination,
              note: _noteController.text,
            );

        if (result['status'] == 'completed' ||
            result['status'] == 'pending_approval') {
          HapticService.success();
          if (mounted) {
            WaterDropSuccessOverlay.show(context, () {
              _showSuccess(amount, destination);
            });
          }
        } else {
          throw Exception(result['message'] ?? 'Erreur inconnue');
        }
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(double amount, String recipient) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            amount: amount,
            recipient: widget.recipientName ?? recipient,
          ),
        ),
      );
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
            const Text('Montant à envoyer',
                style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 16),
            _buildAmountInput(),
            const SizedBox(height: 32),
            const Text('Destinataire', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 12),
            _buildDestinationInput(),
            if (_validationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                child: Text(
                  _validationError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 24),
            _buildNoteInput(),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Frais de réseau',
                    style: TextStyle(color: Colors.white38)),
                Text('~ 0.1%', style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 24),
            PaymentConfirmSlider(
              isLoading: _isLoading,
              onConfirm: _processPayment,
              label: 'Glisser pour payer',
            ),
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
            style: const TextStyle(
                fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: const InputDecoration(
              prefixText: '\$',
              prefixStyle: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white24),
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
          icon:
              const Icon(Icons.person_outline, color: LiquidGlassTheme.accent),
          suffixIcon: widget.recipientId == null
              ? IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white38),
                  onPressed: _handleQRScan,
                )
              : null,
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
}
