import 'package:flutter/material.dart';

class QrScannerService {
  QrScannerService._internal();
  static final QrScannerService _instance = QrScannerService._internal();
  factory QrScannerService() => _instance;

  bool isLightningInvoice(String code) {
    final normalized = code.trim().toLowerCase();
    return normalized.startsWith('lnbc') ||
        normalized.startsWith('lntb') ||
        normalized.startsWith('lnsb') ||
        normalized.startsWith('lnbcrt') ||
        normalized.startsWith('lightning:');
  }

  String? extractBolt11(String code) {
    var clean = code.trim();
    if (clean.toLowerCase().startsWith('lightning:')) {
      clean = clean.substring(10);
    }
    if (isLightningInvoice(clean)) return clean;
    return null;
  }

  QrCodeType analyzeCode(String code) {
    final lower = code.trim().toLowerCase();
    if (isLightningInvoice(code)) return QrCodeType.lightningInvoice;
    if (lower.startsWith('http://') || lower.startsWith('https://')) return QrCodeType.url;
    if (code.startsWith('CP-') || code.startsWith('cp-')) return QrCodeType.cryptoPayId;
    return QrCodeType.unknown;
  }
}

enum QrCodeType { lightningInvoice, url, cryptoPayId, unknown }
