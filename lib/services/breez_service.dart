import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BreezService {
  BreezService._internal();
  static final BreezService _instance = BreezService._internal();
  factory BreezService() => _instance;

  final _storage = const FlutterSecureStorage();
  final _sdk = BreezSDK();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    _sdk.initialize();
    _initialized = true;
  }

  Future<void> connect({
    required String apiKey,
    required String breezServer,
    required String chainnotifierUrl,
    required Network network,
  }) async {
    await initialize();

    final seed = await _getOrCreateSeed();

    final config = Config(
      breezserver: breezServer,
      chainnotifierUrl: chainnotifierUrl,
      mempoolspaceUrl: chainnotifierUrl,
      workingDir: '.',
      network: network,
      paymentTimeoutSec: 60,
      apiKey: apiKey,
      maxfeePercent: 0.01,
      exemptfeeMsat: 1000,
      nodeConfig: NodeConfig.greenlight(
        config: const GreenlightNodeConfig(),
      ),
    );

    await _sdk.connect(req: ConnectRequest(config: config, seed: seed));
  }

  Future<Uint8List> _getOrCreateSeed() async {
    final stored = await _storage.read(key: 'breez_seed');
    if (stored != null) {
      return base64Url.decode(stored);
    }

    final random = Random.secure();
    final seed = Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256)));
    await _storage.write(key: 'breez_seed', value: base64UrlEncode(seed));
    return seed;
  }

  Future<ReceivePaymentResponse> createInvoice({
    required int amountSats,
    required String description,
    int expiry = 3600,
  }) async {
    if (!_initialized) throw Exception('Breez SDK not initialized');
    return _sdk.receivePayment(
      req: ReceivePaymentRequest(
        amountMsat: amountSats * 1000,
        description: description,
        expiry: expiry,
      ),
    );
  }

  Future<SendPaymentResponse> sendPayment({
    required String bolt11,
    int? amountMsat,
    bool useTrampoline = false,
    String? label,
  }) async {
    if (!_initialized) throw Exception('Breez SDK not initialized');
    return _sdk.sendPayment(
      req: SendPaymentRequest(
        bolt11: bolt11,
        useTrampoline: useTrampoline,
        amountMsat: amountMsat,
        label: label,
      ),
    );
  }

  Future<Payment?> paymentByHash(String hash) async {
    if (!_initialized) throw Exception('Breez SDK not initialized');
    return _sdk.paymentByHash(hash: hash);
  }

  Future<LNInvoice> parseInvoice(String bolt11) async {
    if (!_initialized) throw Exception('Breez SDK not initialized');
    return _sdk.parseInvoice(bolt11);
  }

  Future<NodeState> getNodeState() async {
    if (!_initialized) throw Exception('Breez SDK not initialized');
    final info = await _sdk.nodeInfo();
    if (info == null) throw Exception('No node info');
    return info;
  }

  Future<Balance> getBalance() async {
    if (!_initialized) throw Exception('Breez SDK not initialized');
    final nodeInfo = await _sdk.nodeInfo();
    if (nodeInfo == null) {
      return Balance(onchainBalanceMsat: 0, channelBalanceMsat: 0);
    }
    return Balance(
      onchainBalanceMsat: nodeInfo.onchainBalanceMsat,
      channelBalanceMsat: nodeInfo.channelsBalanceMsat,
    );
  }

  Future<void> registerWebhook({required String webhookUrl}) async {
    await _sdk.registerWebhook(webhookUrl: webhookUrl);
  }
}

class Balance {
  final int onchainBalanceMsat;
  final int channelBalanceMsat;

  Balance({required this.onchainBalanceMsat, required this.channelBalanceMsat});
}
