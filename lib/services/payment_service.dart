import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;


import 'breez_service.dart';
import 'bluetooth_service.dart';
import 'nfc_service.dart';


class PaymentService {
  final NfcService _nfcService;
  final BluetoothService _bluetoothService;
  final BreezService _breezService;

  PaymentService({
    required NfcService nfcService,
    required BluetoothService bluetoothService,
    required BreezService breezService,
  })  : _nfcService = nfcService,
        _bluetoothService = bluetoothService,
        _breezService = breezService;

  Future<PaymentResult> payWithNfc({
    required int amountSats,
    String? note,
  }) async {
    try {
      await _nfcService.startListening();
      final invoice = await _nfcService.invoiceStream.first;
      final response = await _breezService.sendPayment(
        bolt11: invoice,
        useTrampoline: true,
        label: note,
      );

      // Breez SDK: status type vient de breez_sdk (pas de l'enum local PaymentStatus)
      if (response.payment.status == 'Complete') {

        return PaymentResult.success(
          paymentHash: response.payment.id,
          amountSats: amountSats,
        );
      }
      return PaymentResult.failure(
        error: response.payment.error ?? 'Paiement NFC échoué',
      );
    } catch (e) {
      return PaymentResult.failure(error: e.toString());
    } finally {
      await _nfcService.stopListening();
    }
  }

  Future<PaymentResult> payWithBluetooth({
    required int amountSats,
    required fbp.BluetoothDevice device,
    String? note,
  }) async {

    try {
      await _bluetoothService.connect(device);
      final invoiceResponse = await _breezService.createInvoice(
        amountSats: amountSats,
        description: note ?? 'Paiement Crypto-Pay',
      );
      final bolt11 = invoiceResponse.lnInvoice.bolt11;

      await _bluetoothService.sendMessage(bolt11);
      final message = await _bluetoothService.messageStream.first;

      if (message.contains('PAYMENT_SUCCESS')) {
        return PaymentResult.success(
          paymentHash: invoiceResponse.lnInvoice.paymentHash,
          amountSats: amountSats,
        );
      }

      return PaymentResult.failure(error: 'Paiement Bluetooth refusé : $message');
    } catch (e) {
      return PaymentResult.failure(error: e.toString());
    } finally {
      await _bluetoothService.disconnect();
    }
  }
}

class PaymentResult {
  final bool success;
  final String? paymentHash;
  final int? amountSats;
  final String? error;

  const PaymentResult._({
    required this.success,
    this.paymentHash,
    this.amountSats,
    this.error,
  });

  factory PaymentResult.success({
    required String paymentHash,
    required int amountSats,
  }) {
    return PaymentResult._(
      success: true,
      paymentHash: paymentHash,
      amountSats: amountSats,
    );
  }

  factory PaymentResult.failure({
    required String error,
  }) {
    return PaymentResult._(
      success: false,
      error: error,
    );
  }
}
