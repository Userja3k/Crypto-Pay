import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/breez_service.dart';
import '../services/bluetooth_service.dart';
import '../services/nfc_service.dart';
import '../services/payment_service.dart';
import 'user_provider.dart';

// ════════════════════════════════════════════════════════
// ÉTATS NFC
// ════════════════════════════════════════════════════════

class NfcPaymentState {
  final bool isLoading;
  final String? paymentHash;
  final int? amountSats;
  final String? error;
  final String? counterpartyName;
  final NfcStatus status;

  const NfcPaymentState({
    this.isLoading = false,
    this.paymentHash,
    this.amountSats,
    this.error,
    this.counterpartyName,
    this.status = NfcStatus.idle,
  });

  factory NfcPaymentState.loading() => const NfcPaymentState(
        isLoading: true,
        status: NfcStatus.loading,
      );

  factory NfcPaymentState.success(String hash, int amount,
          {String? counterparty}) =>
      NfcPaymentState(
        paymentHash: hash,
        amountSats: amount,
        counterpartyName: counterparty,
        status: NfcStatus.success,
      );

  factory NfcPaymentState.failure(String error) => NfcPaymentState(
        error: error,
        status: NfcStatus.failure,
      );

  factory NfcPaymentState.idle() => const NfcPaymentState();

  NfcPaymentState copyWith({
    bool? isLoading,
    String? paymentHash,
    int? amountSats,
    String? error,
    String? counterpartyName,
    NfcStatus? status,
  }) {
    return NfcPaymentState(
      isLoading: isLoading ?? this.isLoading,
      paymentHash: paymentHash ?? this.paymentHash,
      amountSats: amountSats ?? this.amountSats,
      error: error ?? this.error,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      status: status ?? this.status,
    );
  }
}

enum NfcStatus { idle, loading, success, failure }

final nfcPaymentProvider =
    StateNotifierProvider<NfcPaymentNotifier, NfcPaymentState>((ref) {
  return NfcPaymentNotifier(ref);
});

class NfcPaymentNotifier extends StateNotifier<NfcPaymentState> {
  final Ref _ref;
  NfcPaymentNotifier(this._ref) : super(NfcPaymentState.idle());

  Future<void> payWithNfc({
    required int amountSats,
    String? note,
  }) async {
    final authState = _ref.read(authProvider);
    final userId = authState.userId;
    if (userId == null) {
      state = NfcPaymentState.failure('Utilisateur non authentifié');
      return;
    }

    state = NfcPaymentState.loading();

    try {
      final paymentService = _ref.read(paymentServiceProvider);
      final result = await paymentService.payWithNfc(
        amountSats: amountSats,
        userId: userId,
        note: note,
        requireConfirmation: true,
      );

      if (result.success) {
        state = NfcPaymentState.success(
          result.paymentHash ?? '',
          result.amountSats ?? 0,
          counterparty: result.counterpartyName,
        );
      } else {
        state = NfcPaymentState.failure(result.error ?? 'Erreur NFC inconnue');
      }
    } catch (e) {
      state = NfcPaymentState.failure(e.toString());
    }
  }

  Future<void> receiveWithNfc({
    required int amountSats,
    String? note,
  }) async {
    final authState = _ref.read(authProvider);
    final userId = authState.userId;
    final userName = authState.user?['full_name'] as String? ?? 'Utilisateur';

    if (userId == null) {
      state = NfcPaymentState.failure('Utilisateur non authentifié');
      return;
    }

    state = NfcPaymentState.loading();

    try {
      final paymentService = _ref.read(paymentServiceProvider);
      final result = await paymentService.receiveWithNfc(
        amountSats: amountSats,
        userId: userId,
        userName: userName,
        note: note,
      );

      if (result.success) {
        state = NfcPaymentState.success(
          result.paymentHash ?? '',
          result.amountSats ?? 0,
          counterparty: result.counterpartyName,
        );
      } else {
        state = NfcPaymentState.failure(result.error ?? 'Erreur NFC inconnue');
      }
    } catch (e) {
      state = NfcPaymentState.failure(e.toString());
    }
  }

  void reset() {
    state = NfcPaymentState.idle();
  }
}

// ════════════════════════════════════════════════════════
// ÉTATS BLUETOOTH
// ════════════════════════════════════════════════════════

class BluetoothPaymentState {
  final bool isLoading;
  final String? paymentHash;
  final int? amountSats;
  final String? error;
  final String? counterpartyName;
  final BluetoothStatus status;

  const BluetoothPaymentState({
    this.isLoading = false,
    this.paymentHash,
    this.amountSats,
    this.error,
    this.counterpartyName,
    this.status = BluetoothStatus.idle,
  });

  factory BluetoothPaymentState.loading() => const BluetoothPaymentState(
        isLoading: true,
        status: BluetoothStatus.loading,
      );

  factory BluetoothPaymentState.success(String hash, int amount,
          {String? counterparty}) =>
      BluetoothPaymentState(
        paymentHash: hash,
        amountSats: amount,
        counterpartyName: counterparty,
        status: BluetoothStatus.success,
      );

  factory BluetoothPaymentState.failure(String error) => BluetoothPaymentState(
        error: error,
        status: BluetoothStatus.failure,
      );

  factory BluetoothPaymentState.idle() => const BluetoothPaymentState();

  BluetoothPaymentState copyWith({
    bool? isLoading,
    String? paymentHash,
    int? amountSats,
    String? error,
    String? counterpartyName,
    BluetoothStatus? status,
  }) {
    return BluetoothPaymentState(
      isLoading: isLoading ?? this.isLoading,
      paymentHash: paymentHash ?? this.paymentHash,
      amountSats: amountSats ?? this.amountSats,
      error: error ?? this.error,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      status: status ?? this.status,
    );
  }
}

enum BluetoothStatus { idle, loading, success, failure }

final bluetoothPaymentProvider =
    StateNotifierProvider<BluetoothPaymentNotifier, BluetoothPaymentState>(
        (ref) {
  return BluetoothPaymentNotifier(ref);
});

class BluetoothPaymentNotifier extends StateNotifier<BluetoothPaymentState> {
  final Ref _ref;
  BluetoothPaymentNotifier(this._ref) : super(BluetoothPaymentState.idle());

  Future<void> payWithBluetooth({
    required int amountSats,
    required fbp.BluetoothDevice device,
    String? note,
  }) async {
    final authState = _ref.read(authProvider);
    final userId = authState.userId;
    if (userId == null) {
      state = BluetoothPaymentState.failure('Utilisateur non authentifié');
      return;
    }

    state = BluetoothPaymentState.loading();

    try {
      final paymentService = _ref.read(paymentServiceProvider);
      final result = await paymentService.payWithBluetooth(
        amountSats: amountSats,
        device: device,
        userId: userId,
        note: note,
      );

      if (result.success) {
        state = BluetoothPaymentState.success(
          result.paymentHash ?? '',
          result.amountSats ?? 0,
          counterparty: result.counterpartyName,
        );
      } else {
        state = BluetoothPaymentState.failure(
            result.error ?? 'Erreur Bluetooth inconnue');
      }
    } catch (e) {
      state = BluetoothPaymentState.failure(e.toString());
    }
  }

  Future<void> receiveWithBluetooth({
    String? note,
  }) async {
    final authState = _ref.read(authProvider);
    final userId = authState.userId;
    final userName = authState.user?['full_name'] as String? ?? 'Utilisateur';

    if (userId == null) {
      state = BluetoothPaymentState.failure('Utilisateur non authentifié');
      return;
    }

    state = BluetoothPaymentState.loading();

    try {
      final paymentService = _ref.read(paymentServiceProvider);
      final result = await paymentService.receiveWithBluetooth(
        userId: userId,
        userName: userName,
      );

      if (result.success) {
        state = BluetoothPaymentState.success(
          result.paymentHash ?? '',
          result.amountSats ?? 0,
          counterparty: result.counterpartyName,
        );
      } else {
        state = BluetoothPaymentState.failure(
            result.error ?? 'Erreur Bluetooth inconnue');
      }
    } catch (e) {
      state = BluetoothPaymentState.failure(e.toString());
    }
  }

  void reset() {
    state = BluetoothPaymentState.idle();
  }
}

// ════════════════════════════════════════════════════════
// SCAN & DISPOSITIFS
// ════════════════════════════════════════════════════════

final bluetoothDevicesProvider =
    StateProvider<List<fbp.BluetoothDevice>>((ref) => []);
final bluetoothScanningProvider = StateProvider<bool>((ref) => false);

final nfcAvailableProvider = FutureProvider<bool>((ref) async {
  final nfc = ref.watch(nfcServiceProvider);
  return nfc.checkAvailability();
});

final bluetoothAvailableProvider = FutureProvider<bool>((ref) async {
  final bluetooth = ref.watch(bluetoothServiceProvider);
  return bluetooth.checkAvailability();
});
