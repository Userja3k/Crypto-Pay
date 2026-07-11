// lib/services/breez_service_interface.dart
// Interface commune pour BreezService

import 'package:breez_sdk/bridge_generated.dart';

abstract class IBreezService {
  Future<void> initialize();
  Future<void> connect({required String apiKey, required String breezServer, required String chainnotifierUrl, required Network network});
  Future<ReceivePaymentResponse> createInvoice({required int amountSats, required String description, int expiry = 3600});
  Future<SendPaymentResponse> sendPayment({required String bolt11, int? amountMsat, bool useTrampoline = false, String? label});
  Future<LNInvoice> parseInvoice(String bolt11);
  Future<NodeState> getNodeState();
  Future<Balance> getBalance();
  Future<Payment?> paymentByHash(String hash);
  Future<void> registerWebhook({required String webhookUrl});
  Future<bool> backupSeedToCloud({String? userId});
  Future<String?> restoreSeedFromCloud({String? userId});
}

class Balance {
  final int onchainBalanceMsat;
  final int channelBalanceMsat;
  Balance({required this.onchainBalanceMsat, required this.channelBalanceMsat});
}