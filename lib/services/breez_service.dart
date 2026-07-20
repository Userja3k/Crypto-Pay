// lib/services/breez_service.dart
// Version Greenlight UNIQUE et stable

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class BreezService {
  BreezService._internal();
  static final BreezService _instance = BreezService._internal();
  factory BreezService() => _instance;

  final _storage = const FlutterSecureStorage();
  final _sdk = BreezSDK();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // ════════════════════════════════════════════════════════
  // INITIALISATION
  // ════════════════════════════════════════════════════════

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
    
    try {
      if (kBreezWebhookUrl.isNotEmpty) {
        await registerWebhook(webhookUrl: kBreezWebhookUrl);
      }
    } catch (e) {
      print('Failed to register Breez webhook: $e');
    }
  }

  Future<Uint8List> _getOrCreateSeed() async {
    final stored = await _storage.read(key: 'breez_seed');
    if (stored != null) {
      return base64Url.decode(stored);
    }

    final random = Random.secure();
    final seed = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256))
    );
    await _storage.write(key: 'breez_seed', value: base64UrlEncode(seed));
    return seed;
  }

  // ════════════════════════════════════════════════════════
  // FACTURES & PAIEMENTS
  // ════════════════════════════════════════════════════════

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

  Future<SendPaymentResponse> sendPaymentWithRetry({
    required String bolt11,
    int? amountMsat,
    bool useTrampoline = false,
    String? label,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 2),
  }) async {
    if (!_initialized) throw Exception('Breez SDK not initialized');

    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        final result = await sendPayment(
          bolt11: bolt11,
          amountMsat: amountMsat,
          useTrampoline: useTrampoline,
          label: label,
        );

        final status = result.payment.status.toString().toLowerCase();
        if (status.contains('complete') || status.contains('confirmed')) {
          return result;
        }

        attempt++;
        if (attempt >= maxRetries) {
          throw Exception('Échec du paiement après $maxRetries tentatives');
        }

        await Future.delayed(delay);
        delay = Duration(seconds: delay.inSeconds * 2);
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;
        await Future.delayed(delay);
        delay = Duration(seconds: delay.inSeconds * 2);
      }
    }

    throw Exception('Échec après $maxRetries tentatives');
  }

  // ════════════════════════════════════════════════════════
  // UTILITAIRES
  // ════════════════════════════════════════════════════════

  Future<bool> isInvoiceValid(String bolt11) async {
    try {
      final invoice = await parseInvoice(bolt11);
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(
        (invoice.timestamp + invoice.expiry) * 1000,
      );
      return expiryDate.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
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

  // ════════════════════════════════════════════════════════
  // SAUVEGARDE CLOUD
  // ════════════════════════════════════════════════════════

  Future<bool> backupSeedToCloud({String? userId}) async {
    try {
      final currentUserId = userId ?? Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return false;

      final seed = base64UrlEncode(await _getOrCreateSeed());
      final encryptedSeed = _encryptSeed(seed);

      await Supabase.instance.client.from('wallet_backups').upsert({
        'user_id': currentUserId,
        'encrypted_seed': encryptedSeed,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Erreur backup cloud: $e');
      return false;
    }
  }

  Future<String?> restoreSeedFromCloud({String? userId}) async {
    try {
      final currentUserId = userId ?? Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final response = await Supabase.instance.client
          .from('wallet_backups')
          .select('encrypted_seed')
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (response == null || response['encrypted_seed'] == null) {
        return null;
      }

      final decrypted = _decryptSeed(response['encrypted_seed'] as String);
      await _storage.write(key: 'breez_seed', value: decrypted);
      return decrypted;
    } catch (e) {
      print('Erreur restauration cloud: $e');
      return null;
    }
  }

  String _encryptSeed(String seed) {
    return 'enc:${base64UrlEncode(utf8.encode(seed))}';
  }

  String _decryptSeed(String encryptedSeed) {
    final payload = encryptedSeed.replaceFirst('enc:', '');
    return utf8.decode(base64Url.decode(payload));
  }
}

class Balance {
  final int onchainBalanceMsat;
  final int channelBalanceMsat;

  Balance({required this.onchainBalanceMsat, required this.channelBalanceMsat});
}