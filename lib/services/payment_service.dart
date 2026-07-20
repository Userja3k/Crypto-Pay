// lib/services/payment_service.dart
// Version complète avec enregistrement DB

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'breez_service.dart';
import 'bluetooth_service.dart';
import 'nfc_service.dart';
import 'supabase_service.dart';

// ════════════════════════════════════════════════════════════════
// TYPES
// ════════════════════════════════════════════════════════════════

enum PaymentMethod { nfc, bluetooth, qrCode, lightningAddress, internal }

class PaymentResult {
  final bool success;
  final String? paymentHash;
  final int? amountSats;
  final String? counterpartyName;
  final String? error;
  final PaymentMethod method;
  final DateTime timestamp;

  const PaymentResult({
    required this.success,
    this.paymentHash,
    this.amountSats,
    this.counterpartyName,
    this.error,
    required this.method,
    required this.timestamp,
  });

  factory PaymentResult.success({
    required String paymentHash,
    required int amountSats,
    required PaymentMethod method,
    String? counterpartyName,
  }) {
    return PaymentResult(
      success: true,
      paymentHash: paymentHash,
      amountSats: amountSats,
      counterpartyName: counterpartyName,
      method: method,
      timestamp: DateTime.now(),
    );
  }

  factory PaymentResult.failure({
    required String error,
    required PaymentMethod method,
  }) {
    return PaymentResult(
      success: false,
      error: error,
      method: method,
      timestamp: DateTime.now(),
    );
  }

  factory PaymentResult.cancelled({required PaymentMethod method}) {
    return PaymentResult(
      success: false,
      error: 'Annulé par l\'utilisateur',
      method: method,
      timestamp: DateTime.now(),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SERVICE DE PAIEMENT
// ════════════════════════════════════════════════════════════════

class PaymentService {
  final NfcService _nfcService;
  final BluetoothService _bluetoothService;
  final BreezService _breezService;
  final SupabaseService _supabaseService;

  PaymentService({
    required NfcService nfcService,
    required BluetoothService bluetoothService,
    required BreezService breezService,
    required SupabaseService supabaseService,
  }) : _nfcService = nfcService,
       _bluetoothService = bluetoothService,
       _breezService = breezService,
       _supabaseService = supabaseService;

  // ════════════════════════════════════════════════════════════
  // NFC - PAYER
  // ════════════════════════════════════════════════════════════

  Future<PaymentResult> payWithNfc({
    required int amountSats,
    required String userId,
    String? note,
    bool requireConfirmation = true,
  }) async {
    try {
      // 1. Lecture NFC
      final result = await _nfcService.readNfc(
        timeout: Duration(seconds: 30),
        requireConfirmation: requireConfirmation,
        validateBolt11: true,
        expectedAmountSats: amountSats,
      );

      if (!result.success || result.bolt11 == null) {
        return PaymentResult.failure(
          error: result.error ?? 'Lecture NFC échouée',
          method: PaymentMethod.nfc,
        );
      }

      // 2. Validation du BOLT11
      final invoice = await _breezService.parseInvoice(result.bolt11!);
      if (invoice.amountMsat == null) {
        return PaymentResult.failure(
          error: 'Facture sans montant',
          method: PaymentMethod.nfc,
        );
      }

      final invoiceSats = invoice.amountMsat! ~/ 1000;

      // 3. Envoi du paiement
      final sendResult = await _breezService.sendPaymentWithRetry(
        bolt11: result.bolt11!,
        amountMsat: invoice.amountMsat,
        label: note,
      );

      final status = sendResult.payment.status.toString().toLowerCase();
      if (status.contains('complete') || status.contains('confirmed')) {
        // 4. Enregistrement en DB
        await _supabaseService.recordNfcPayment(
          userId: userId,
          amountSats: invoiceSats,
          bolt11: result.bolt11!,
          paymentHash: sendResult.payment.id,
          note: note,
        );

        return PaymentResult.success(
          paymentHash: sendResult.payment.id,
          amountSats: invoiceSats,
          method: PaymentMethod.nfc,
          counterpartyName: result.counterpartyName,
        );
      }

      return PaymentResult.failure(
        error: sendResult.payment.error ?? 'Paiement NFC échoué',
        method: PaymentMethod.nfc,
      );
    } catch (e) {
      return PaymentResult.failure(
        error: 'Erreur NFC: $e',
        method: PaymentMethod.nfc,
      );
    } finally {
      _nfcService.reset();
    }
  }

  // ════════════════════════════════════════════════════════════
  // NFC - RECEVOIR (Écrire sur tag)
  // ════════════════════════════════════════════════════════════

  Future<PaymentResult> receiveWithNfc({
    required int amountSats,
    required String userId,
    required String userName,
    String? note,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // 1. Génération de la facture
      final invoice = await _breezService.createInvoice(
        amountSats: amountSats,
        description: note ?? 'Paiement NFC',
      );

      // 2. Écriture sur la tag NFC
      final writeResult = await _nfcService.writeNfc(
        bolt11: invoice.lnInvoice.bolt11,
        amountSats: amountSats,
        senderName: userName,
        senderId: userId,
        memo: note,
        timeout: timeout,
      );

      if (!writeResult.success) {
        return PaymentResult.failure(
          error: writeResult.error ?? 'Échec d\'écriture NFC',
          method: PaymentMethod.nfc,
        );
      }

      // 3. Enregistrement en DB
      await _supabaseService.recordNfcPayment(
        userId: userId,
        amountSats: amountSats,
        bolt11: invoice.lnInvoice.bolt11,
        paymentHash: invoice.lnInvoice.paymentHash,
        note: note,
      );

      return PaymentResult.success(
        paymentHash: invoice.lnInvoice.paymentHash,
        amountSats: amountSats,
        method: PaymentMethod.nfc,
        counterpartyName: 'En attente de paiement NFC',
      );
    } catch (e) {
      return PaymentResult.failure(
        error: 'Erreur NFC: $e',
        method: PaymentMethod.nfc,
      );
    } finally {
      _nfcService.reset();
    }
  }

  // ════════════════════════════════════════════════════════════
  // BLUETOOTH - PAYER
  // ════════════════════════════════════════════════════════════

  Future<PaymentResult> payWithBluetooth({
    required fbp.BluetoothDevice device,
    required int amountSats,
    required String userId,
    String? note,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      // 1. Connexion sécurisée
      final connectResult = await _bluetoothService.connectSecurely(
        device: device,
        clientId: userId,
        publicKey: await _getPublicKey(userId),
        timeout: timeout,
      );

      if (!connectResult.success) {
        return PaymentResult.failure(
          error: connectResult.error ?? 'Échec de connexion Bluetooth',
          method: PaymentMethod.bluetooth,
        );
      }

      // 2. Génération de la facture
      final invoice = await _breezService.createInvoice(
        amountSats: amountSats,
        description: note ?? 'Paiement Bluetooth',
      );

      // 3. Envoi de la demande de paiement
      final requestResult = await _bluetoothService.sendPaymentRequest(
        bolt11: invoice.lnInvoice.bolt11,
        amountSats: amountSats,
        senderId: userId,
        memo: note,
        timeout: timeout,
      );

      if (!requestResult.success) {
        return PaymentResult.failure(
          error: requestResult.error ?? 'Échec d\'envoi Bluetooth',
          method: PaymentMethod.bluetooth,
        );
      }

      // 4. Envoi du paiement Lightning
      final sendResult = await _breezService.sendPaymentWithRetry(
        bolt11: invoice.lnInvoice.bolt11,
        amountMsat: amountSats * 1000,
        label: note,
      );

      // 5. Enregistrement en DB
      await _supabaseService.recordBluetoothPayment(
        userId: userId,
        amountSats: amountSats,
        bolt11: invoice.lnInvoice.bolt11,
        paymentHash: sendResult.payment.id,
        note: note,
      );

      // 6. Déconnexion
      await _bluetoothService.disconnect();

      return PaymentResult.success(
        paymentHash: sendResult.payment.id,
        amountSats: amountSats,
        method: PaymentMethod.bluetooth,
        counterpartyName: device.platformName.isNotEmpty ? device.platformName : 'Appareil Bluetooth',
      );
    } catch (e) {
      await _bluetoothService.disconnect();
      return PaymentResult.failure(
        error: 'Erreur Bluetooth: $e',
        method: PaymentMethod.bluetooth,
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // BLUETOOTH - RECEVOIR
  // ════════════════════════════════════════════════════════════

  Future<PaymentResult> receiveWithBluetooth({
    required String userId,
    required String userName,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    try {
      // 1. Attente d'une demande de paiement
      final requestResult = await _bluetoothService.receivePaymentRequest(
        serverId: userId,
        serverPublicKey: await _getPublicKey(userId),
        timeout: timeout,
      );

      if (!requestResult.success) {
        return PaymentResult.failure(
          error: requestResult.error ?? 'Échec de réception Bluetooth',
          method: PaymentMethod.bluetooth,
        );
      }

      // 2. Enregistrement en DB
      await _supabaseService.recordBluetoothPayment(
        userId: userId,
        amountSats: requestResult.amountSats ?? 0,
        bolt11: requestResult.bolt11 ?? '', // Sera rempli par le webhook
        paymentHash: null,
        note: null,
      );

      // 3. Déconnexion
      await _bluetoothService.disconnect();

      return PaymentResult.success(
        paymentHash: '',
        amountSats: requestResult.amountSats ?? 0,
        method: PaymentMethod.bluetooth,
        counterpartyName: requestResult.counterpartyName,
      );
    } catch (e) {
      await _bluetoothService.disconnect();
      return PaymentResult.failure(
        error: 'Erreur Bluetooth: $e',
        method: PaymentMethod.bluetooth,
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // UTILITAIRES
  // ════════════════════════════════════════════════════════════

  Future<String> _getPublicKey(String userId) async {
    // TODO: Récupérer la clé publique depuis le SDK Breez
    // Pour l'instant, on retourne une clé temporaire
    return 'temp_public_key_$userId';
  }

  /// Annule toutes les opérations en cours
  void cancelAll() {
    _nfcService.reset();
    _bluetoothService.disconnect();
  }
}
