import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/qr_scanner_service.dart';

final qrScannerServiceProvider = Provider((ref) => QrScannerService());

class QrScanState {
  final bool isScanning;
  final String? scannedData;
  final String? error;

  const QrScanState({this.isScanning = false, this.scannedData, this.error});

  QrScanState copyWith({bool? isScanning, String? scannedData, String? error}) {
    return QrScanState(
      isScanning: isScanning ?? this.isScanning,
      scannedData: scannedData ?? this.scannedData,
      error: error ?? this.error,
    );
  }
}

class QrScannerNotifier extends StateNotifier<QrScanState> {
  QrScannerNotifier() : super(const QrScanState());

  void startScan() => state = state.copyWith(isScanning: true, error: null);
  void stopScan() => state = state.copyWith(isScanning: false);

  void onScanComplete(String data) {
    final service = QrScannerService();
    final type = service.analyzeCode(data);
    if (type == QrCodeType.lightningInvoice) {
      final bolt11 = service.extractBolt11(data);
      state = state.copyWith(isScanning: false, scannedData: bolt11, error: null);
    } else if (type == QrCodeType.cryptoPayId) {
      state = state.copyWith(isScanning: false, scannedData: data, error: null);
    } else {
      state = state.copyWith(isScanning: false, scannedData: null, error: 'Code QR non reconnu');
    }
  }

  void reset() => state = const QrScanState();
  void setError(String error) => state = state.copyWith(error: error, isScanning: false);
}

final qrScannerProvider = StateNotifierProvider<QrScannerNotifier, QrScanState>((ref) {
  return QrScannerNotifier();
});
