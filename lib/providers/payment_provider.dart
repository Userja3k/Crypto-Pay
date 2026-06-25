import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/breez_service.dart';
import '../services/bluetooth_service.dart';
import '../services/nfc_service.dart';
import '../services/payment_service.dart';
import 'user_provider.dart';

final nfcServiceProvider = Provider((ref) => NfcService());
final bluetoothServiceProvider = Provider((ref) => BluetoothService());

final paymentServiceProvider = Provider((ref) {
  final nfc = ref.watch(nfcServiceProvider);
  final bluetooth = ref.watch(bluetoothServiceProvider);
  final breez = ref.watch(breezServiceProvider);
  return PaymentService(
    nfcService: nfc,
    bluetoothService: bluetooth,
    breezService: breez,
  );
});

class PaymentState {
  final bool isLoading;
  final String? paymentHash;
  final int? amountSats;
  final String? error;
  final PaymentStatus status;

  const PaymentState({
    this.isLoading = false,
    this.paymentHash,
    this.amountSats,
    this.error,
    this.status = PaymentStatus.idle,
  });

  factory PaymentState.loading() => const PaymentState(isLoading: true, status: PaymentStatus.loading);
  factory PaymentState.success(String hash, int amount) => PaymentState(
        paymentHash: hash,
        amountSats: amount,
        status: PaymentStatus.success,
      );
  factory PaymentState.failure(String error) => PaymentState(
        error: error,
        status: PaymentStatus.failure,
      );
  factory PaymentState.idle() => const PaymentState();

  PaymentState copyWith({
    bool? isLoading,
    String? paymentHash,
    int? amountSats,
    String? error,
    PaymentStatus? status,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      paymentHash: paymentHash ?? this.paymentHash,
      amountSats: amountSats ?? this.amountSats,
      error: error ?? this.error,
      status: status ?? this.status,
    );
  }
}

enum PaymentStatus { idle, loading, success, failure }

final nfcPaymentProvider = StateNotifierProvider<NfcPaymentNotifier, PaymentState>((ref) {
  return NfcPaymentNotifier(ref);
});

class NfcPaymentNotifier extends StateNotifier<PaymentState> {
  final Ref _ref;
  NfcPaymentNotifier(this._ref) : super(const PaymentState());

  Future<void> payWithNfc({
    required int amountSats,
    String? note,
  }) async {
    state = PaymentState.loading();

    try {
      final paymentService = _ref.read(paymentServiceProvider);
      final result = await paymentService.payWithNfc(
        amountSats: amountSats,
        note: note,
      );

      if (result.success) {
        state = PaymentState.success(result.paymentHash ?? '', result.amountSats ?? 0);
      } else {
        state = PaymentState.failure(result.error ?? 'Erreur NFC inconnue');
      }
    } catch (e) {
      state = PaymentState.failure(e.toString());
    }
  }

  void reset() {
    state = PaymentState.idle();
  }

}

final bluetoothPaymentProvider = StateNotifierProvider<BluetoothPaymentNotifier, PaymentState>((ref) {
  return BluetoothPaymentNotifier(ref);
});

class BluetoothPaymentNotifier extends StateNotifier<PaymentState> {
  final Ref _ref;
  BluetoothPaymentNotifier(this._ref) : super(const PaymentState());

  Future<void> payWithBluetooth({
    required int amountSats,
    required fbp.BluetoothDevice device,
    String? note,
  }) async {
    state = PaymentState.loading();

    try {
      final paymentService = _ref.read(paymentServiceProvider);
      final result = await paymentService.payWithBluetooth(
        amountSats: amountSats,
        device: device,
        note: note,
      );

      if (result.success) {
        state = PaymentState.success(result.paymentHash ?? '', result.amountSats ?? 0);
      } else {
        state = PaymentState.failure(result.error ?? 'Erreur Bluetooth inconnue');
      }
    } catch (e) {
      state = PaymentState.failure(e.toString());
    }
  }

  void reset() {
    state = PaymentState.idle();
  }

}

final bluetoothDevicesProvider = StateProvider<List<fbp.BluetoothDevice>>((ref) => []);
final bluetoothScanningProvider = StateProvider<bool>((ref) => false);

final nfcAvailableProvider = FutureProvider<bool>((ref) async {
  final nfc = ref.watch(nfcServiceProvider);
  return nfc.checkAvailability();
});

final bluetoothAvailableProvider = FutureProvider<bool>((ref) async {
  final bluetooth = ref.watch(bluetoothServiceProvider);
  return bluetooth.checkAvailability();
});
