// lib/services/nfc_service.dart
// Version complète avec écriture NFC

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';

// ════════════════════════════════════════════════════════════════
// TYPES
// ════════════════════════════════════════════════════════════════

enum NfcState {
  idle,
  scanning,
  reading,
  validating,
  confirming,
  processing,
  success,
  failure,
  timeout,
  cancelled,
}

class NfcResult {
  final bool success;
  final String? bolt11;
  final String? error;
  final String? paymentHash;
  final int? amountSats;
  final String? counterpartyName;
  final NfcState state;

  const NfcResult({
    required this.success,
    this.bolt11,
    this.error,
    this.paymentHash,
    this.amountSats,
    this.counterpartyName,
    this.state = NfcState.idle,
  });

  factory NfcResult.success({
    required String bolt11,
    required String paymentHash,
    required int amountSats,
    String? counterpartyName,
  }) {
    return NfcResult(
      success: true,
      bolt11: bolt11,
      paymentHash: paymentHash,
      amountSats: amountSats,
      counterpartyName: counterpartyName,
      state: NfcState.success,
    );
  }

  factory NfcResult.failure(String error, {NfcState state = NfcState.failure}) {
    return NfcResult(success: false, error: error, state: state);
  }

  factory NfcResult.timeout() {
    return NfcResult(
      success: false,
      error: 'Temps de lecture dépassé',
      state: NfcState.timeout,
    );
  }

  factory NfcResult.cancelled() {
    return NfcResult(
      success: false,
      error: 'Opération annulée par l\'utilisateur',
      state: NfcState.cancelled,
    );
  }
}

class NfcTagData {
  final String bolt11;
  final String? senderName;
  final String? senderId;
  final int? amountSats;
  final String? memo;
  final int timestamp;
  final String? signature;

  const NfcTagData({
    required this.bolt11,
    this.senderName,
    this.senderId,
    this.amountSats,
    this.memo,
    required this.timestamp,
    this.signature,
  });

  static NfcTagData? fromString(String data) {
    try {
      if (!data.startsWith('CRYPTO-PAY:')) return null;
      final parts = data.substring(11).split('|');
      String? bolt11;
      String? senderName;
      String? senderId;
      int? amountSats;
      String? memo;
      int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      String? signature;

      for (final part in parts) {
        if (part.startsWith('bolt11:')) {
          bolt11 = part.substring(7);
        } else if (part.startsWith('name:')) {
          senderName = part.substring(5);
        } else if (part.startsWith('sender:')) {
          senderId = part.substring(7);
        } else if (part.startsWith('amount:')) {
          amountSats = int.tryParse(part.substring(7));
        } else if (part.startsWith('memo:')) {
          memo = part.substring(5);
        } else if (part.startsWith('time:')) {
          timestamp = int.tryParse(part.substring(5)) ?? timestamp;
        } else if (part.startsWith('sig:')) {
          signature = part.substring(4);
        }
      }

      if (bolt11 == null) return null;
      return NfcTagData(
        bolt11: bolt11,
        senderName: senderName,
        senderId: senderId,
        amountSats: amountSats,
        memo: memo,
        timestamp: timestamp,
        signature: signature,
      );
    } catch (e) {
      return null;
    }
  }

  static String encode({
    required String bolt11,
    String? senderName,
    String? senderId,
    int? amountSats,
    String? memo,
    String? signature,
  }) {
    final parts = <String>['CRYPTO-PAY:v1', 'type:INVOICE', 'bolt11:$bolt11'];
    if (senderName != null) parts.add('name:$senderName');
    if (senderId != null) parts.add('sender:$senderId');
    if (amountSats != null) parts.add('amount:$amountSats');
    if (memo != null) parts.add('memo:$memo');
    if (signature != null) parts.add('sig:$signature');
    parts.add('time:${DateTime.now().millisecondsSinceEpoch ~/ 1000}');
    return parts.join('|');
  }
}

// ════════════════════════════════════════════════════════════════
// SERVICE NFC
// ════════════════════════════════════════════════════════════════

class NfcService {
  NfcService._internal();
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;

  final _stateController = StreamController<NfcState>.broadcast();
  Stream<NfcState> get stateStream => _stateController.stream;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  NfcState _state = NfcState.idle;
  NfcState get state => _state;

  // ════════════════════════════════════════════════════════════
  // INITIALISATION
  // ════════════════════════════════════════════════════════════

  Future<bool> checkAvailability() async {
    try {
      _isAvailable = await NfcManager.instance.isAvailable();
      return _isAvailable;
    } catch (e) {
      debugPrint('Erreur NFC: $e');
      _isAvailable = false;
      return false;
    }
  }

  Future<bool> isNfcEnabled() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // LECTURE NFC
  // ════════════════════════════════════════════════════════════

  Future<NfcResult> readNfc({
    required Duration timeout,
    bool requireConfirmation = true,
    bool validateBolt11 = true,
    int? expectedAmountSats,
  }) async {
    if (!await checkAvailability()) {
      return NfcResult.failure('NFC non disponible sur cet appareil');
    }

    final completer = Completer<NfcResult>();
    Timer? timeoutTimer;

    _setState(NfcState.scanning);

    try {
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          _setState(NfcState.timeout);
          completer.complete(NfcResult.timeout());
        }
      });

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          try {
            _setState(NfcState.reading);
            final rawData = await _readTagPayload(tag);
            if (rawData == null || rawData.isEmpty) {
              if (!completer.isCompleted) {
                completer.complete(NfcResult.failure('Tag NFC vide'));
              }
              return;
            }

            final tagData = NfcTagData.fromString(rawData);
            if (tagData == null) {
              if (!completer.isCompleted) {
                completer.complete(
                  NfcResult.failure('Format de données NFC invalide'),
                );
              }
              return;
            }

            if (requireConfirmation) {
              _setState(NfcState.confirming);
            }
            _setState(NfcState.success);

            if (!completer.isCompleted) {
              timeoutTimer?.cancel();
              completer.complete(
                NfcResult.success(
                  bolt11: tagData.bolt11,
                  paymentHash: '',
                  amountSats: tagData.amountSats ?? 0,
                  counterpartyName: tagData.senderName,
                ),
              );
            }
          } catch (e) {
            if (!completer.isCompleted) {
              _setState(NfcState.failure);
              completer.complete(
                NfcResult.failure('Erreur de lecture NFC: $e'),
              );
            }
          }
        },
      );

      return await completer.future;
    } on PlatformException catch (e) {
      _setState(NfcState.failure);
      return NfcResult.failure('Erreur NFC: ${e.message}');
    } catch (e) {
      _setState(NfcState.failure);
      return NfcResult.failure('Erreur inattendue: $e');
    } finally {
      timeoutTimer?.cancel();
      await NfcManager.instance.stopSession();
    }
  }

  // ════════════════════════════════════════════════════════════
  // ÉCRITURE NFC (NOUVEAU)
  // ════════════════════════════════════════════════════════════

  Future<NfcResult> writeNfc({
    required String bolt11,
    required int amountSats,
    String? senderName,
    String? senderId,
    String? memo,
    String? signature,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!await checkAvailability()) {
      return NfcResult.failure('NFC non disponible sur cet appareil');
    }

    final completer = Completer<NfcResult>();
    Timer? timeoutTimer;

    _setState(NfcState.processing);

    try {
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          _setState(NfcState.timeout);
          completer.complete(NfcResult.timeout());
        }
      });

      // Encode les données
      final encoded = NfcTagData.encode(
        bolt11: bolt11,
        senderName: senderName,
        senderId: senderId,
        amountSats: amountSats,
        memo: memo,
        signature: signature,
      );

      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (NfcTag tag) async {
          try {
            _setState(NfcState.reading);

            if (defaultTargetPlatform != TargetPlatform.android &&
                defaultTargetPlatform != TargetPlatform.iOS) {
              if (!completer.isCompleted) {
                completer.complete(
                  NfcResult.failure('Écriture NFC non disponible sur cette plateforme'),
                );
              }
              return;
            }

            if (!completer.isCompleted) {
              _setState(NfcState.failure);
              completer.complete(
                NfcResult.failure(
                  'Écriture NFC non prise en charge par la version actuelle du plugin',
                ),
              );
            }
          } catch (e) {
            if (!completer.isCompleted) {
              _setState(NfcState.failure);
              completer.complete(
                NfcResult.failure('Erreur d\'écriture NFC: $e'),
              );
            }
          }
        },
      );

      return await completer.future;
    } on PlatformException catch (e) {
      _setState(NfcState.failure);
      return NfcResult.failure('Erreur NFC: ${e.message}');
    } catch (e) {
      _setState(NfcState.failure);
      return NfcResult.failure('Erreur inattendue: $e');
    } finally {
      timeoutTimer?.cancel();
      await NfcManager.instance.stopSession();
    }
  }

  // ════════════════════════════════════════════════════════════
  // UTILITAIRES
  // ════════════════════════════════════════════════════════════

  Future<String?> _readTagPayload(NfcTag tag) async {
    try {
      final dynamic anyTag = tag;
      final dynamic ndefMessage = anyTag.ndefMessage;
      if (ndefMessage != null) {
        final records = (ndefMessage as dynamic).records;
        if (records is List && records.isNotEmpty) {
          final first = records.first;
          final payload = (first as dynamic).payload;
          if (payload is List && payload.isNotEmpty) {
            final bytes = List<int>.from(payload);
            return utf8.decode(bytes, allowMalformed: true);
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur _readTagPayload: $e');
      return null;
    }
  }

  void _setState(NfcState state) {
    _state = state;
    _stateController.add(state);
  }

  void reset() {
    _setState(NfcState.idle);
  }

  void dispose() {
    _stateController.close();
    NfcManager.instance.stopSession();
  }
}
