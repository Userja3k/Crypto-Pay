import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
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
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693, NfcPollingOption.iso18092},
      onDiscovered: (NfcTag tag) async {
        try {
          final invoice = await _readTag(tag);
          if (invoice != null && invoice.isNotEmpty) {
            _invoiceStreamController.add(invoice);
            await NfcManager.instance.stopSession();
          }
        } catch (e) {
          debugPrint('Erreur lecture NFC: $e');
        }
      },
    );
  }

  Future<void> stopListening() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      debugPrint('Erreur stop NFC: $e');
    }
  }

  Future<String?> _readTag(NfcTag tag) async {
    try {
      // Use ndef_record package for parsing
      final data = tag.data;
      if (data is Map && data.containsKey('ndef')) {
        final ndef = data['ndef'];
        if (ndef is Map && ndef.containsKey('cachedMessage')) {
          final message = ndef['cachedMessage'];
          if (message is Map && message['records'] is List && (message['records'] as List).isNotEmpty) {
            final record = (message['records'] as List).first;
            if (record is Map && record.containsKey('payload')) {
              final payload = List<int>.from(record['payload']);
              final decoded = _decodeNdefPayload(payload);
              if (_isBolt11(decoded)) return decoded;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur _readTag: $e');
    }
    return null;
  }

  String _decodeNdefPayload(List<int> payload) {
    if (payload.isEmpty) return '';
    try {
      final type = payload.first;
      if (payload.length > 1 && type == 0x01) {
        final textStart = payload[1] & 0x3F;
        return utf8.decode(payload.sublist(textStart + 1));
      }
      if (payload.length > 1 && type == 0x55) {
        const prefixes = [
          '', 'http://', 'https://', 'tel:', 'mailto:', 'ftp://', 'file://',
          'http://www.', 'https://www.', 'sip:', 'xmpp:'
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

  // API de nfc_manager (4.x) utilisée ici ne garantit pas la présence des types Ndef/NdefMessage/NdefRecord
  // sur toutes les plateformes. Pour éviter les erreurs de compilation, on retire l'écriture NDEF.
  Future<void> writeToTag(String payload) async {
    throw UnimplementedError('writeToTag non supporté avec cette version de nfc_manager');
  }


  void dispose() {
    _invoiceStreamController.close();
    NfcManager.instance.stopSession();
  }
}
