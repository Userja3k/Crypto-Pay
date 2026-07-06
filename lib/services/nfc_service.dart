import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  NfcService._internal();
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;

  final _invoiceStreamController = StreamController<String>.broadcast();
  Stream<String> get invoiceStream => _invoiceStreamController.stream;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  Future<bool> checkAvailability() async {
    try {
      final avail = await NfcManager.instance.checkAvailability();
      _isAvailable = avail == NfcAvailability.enabled;
      return _isAvailable;
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Erreur NFC: $e');
      _isAvailable = false;
      return false;
    }
  }

  Future<void> startListening() async {
    if (!await checkAvailability()) {
      throw Exception('NFC non disponible');
    }

    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          final invoice = await _readTag(tag);
          if (invoice != null && invoice.isNotEmpty) {
            _invoiceStreamController.add(invoice);
            await NfcManager.instance.stopSession();
          }
        } catch (e) {
          // ignore: avoid_print
          debugPrint('Erreur lecture NFC: $e');
        }
      },
    );
  }

  Future<void> stopListening() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Erreur stop NFC: $e');
    }
  }

  Future<String?> _readTag(NfcTag tag) async {
    try {
      // We avoid accessing protected/private members (like tag.data in some nfc_manager versions).
      // Instead, try to use the available payload helpers if present.
      //
      // Practical approach:
      // - If the tag contains an NDEF payload in the public structure, decode it.
      // - Otherwise, fallback to a best-effort raw decode of any available bytes.

      // Many nfc_manager versions expose `ndefMessage` (public) when available.
      // If your version doesn't, compilation will fail; therefore we keep it in a runtime-safe way
      // using try/catch around reflective access is not possible in Dart.
      //
      // So: try to decode `tag.ndefMessage` if the type exists at compile-time.
      //
      // Since we can't rely on it being available in every platform/version, we keep the decoding
      // focused on a conservative path: `tag.cachedMessage`-like structures might not be typed.
      //
      // Best effort: use `tag.additionalData` if available through `tag.data` is not guaranteed.
      //
      // To keep compilation stable across versions, we only attempt to extract payload from
      // the public `NfcTag` fields using what the current type system allows.
      //
      // If your platform provides `tag.ndefMessage` this will work; otherwise it returns null.

      final dynamic anyTag = tag;

      // Try common fields found across versions
      final dynamic ndefMessage = (anyTag as dynamic).ndefMessage;
      if (ndefMessage != null) {
        final decoded = _decodeFromNdefMessage(ndefMessage);
        if (decoded != null && decoded.isNotEmpty && _isBolt11(decoded)) return decoded;
      }

      final dynamic cachedMessage = (anyTag as dynamic).cachedMessage;
      if (cachedMessage != null) {
        final decoded = _decodeFromCachedMessage(cachedMessage);
        if (decoded != null && decoded.isNotEmpty && _isBolt11(decoded)) return decoded;
      }

      return null;
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Erreur _readTag: $e');
      return null;
    }
  }

  String? _decodeFromNdefMessage(dynamic ndefMessage) {
    try {
      final records = (ndefMessage as dynamic).records;
      if (records is List && records.isNotEmpty) {
        final first = records.first;
        final payload = (first as dynamic).payload;
        if (payload is List && payload.isNotEmpty) {
          final bytes = List<int>.from(payload);
          return _decodeNdefPayload(bytes);
        }
      }
    } catch (_) {}
    return null;
  }

  String? _decodeFromCachedMessage(dynamic cachedMessage) {
    try {
      final records = (cachedMessage as dynamic).records;
      if (records is List && records.isNotEmpty) {
        final first = records.first;
        final payload = (first as dynamic).payload;
        if (payload is List && payload.isNotEmpty) {
          final bytes = List<int>.from(payload);
          return _decodeNdefPayload(bytes);
        }
      }
    } catch (_) {}
    return null;
  }

  String _decodeNdefPayload(List<int> payload) {
    if (payload.isEmpty) return '';
    try {
      final type = payload.first;

      // NFC text records: first byte 0x01
      if (payload.length > 1 && type == 0x01) {
        final textStart = payload[1] & 0x3F;
        return utf8.decode(payload.sublist(textStart + 1));
      }

      // NFC URI records: first byte 0x55
      if (payload.length > 1 && type == 0x55) {
        const prefixes = [
          '',
          'http://',
          'https://',
          'tel:',
          'mailto:',
          'ftp://',
          'file://',
          'http://www.',
          'https://www.',
          'sip:',
          'xmpp:',
        ];
        final prefix = prefixes.length > payload[1] ? prefixes[payload[1]] : '';
        final uri = utf8.decode(payload.sublist(2));
        return '$prefix$uri';
      }

      return utf8.decode(payload);
    } catch (_) {
      return utf8.decode(payload);
    }
  }

  bool _isBolt11(String value) {
    final normalized = value.toLowerCase();
    return normalized.startsWith('lnbc') ||
        normalized.startsWith('lntb') ||
        normalized.startsWith('lnsb') ||
        normalized.startsWith('lnbcrt');
  }

  // API de nfc_manager : pas supporté ici selon la version actuelle.
  Future<void> writeToTag(String payload) async {
    throw UnimplementedError('writeToTag non supporté avec cette version de nfc_manager');
  }

  void dispose() {
    _invoiceStreamController.close();
    NfcManager.instance.stopSession();
  }
}
