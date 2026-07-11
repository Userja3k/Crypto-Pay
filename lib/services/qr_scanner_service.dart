// lib/services/qr_scanner_service.dart
// Version complète avec LNURL

import 'package:flutter/material.dart';

class QrScannerService {
  QrScannerService._internal();
  static final QrScannerService _instance = QrScannerService._internal();
  factory QrScannerService() => _instance;

  // ════════════════════════════════════════════════════════════
  // DÉTECTION
  // ════════════════════════════════════════════════════════════

  bool isLightningInvoice(String code) {
    final normalized = code.trim().toLowerCase();
    return normalized.startsWith('lnbc') ||
        normalized.startsWith('lntb') ||
        normalized.startsWith('lnsb') ||
        normalized.startsWith('lnbcrt') ||
        normalized.startsWith('lightning:');
  }

  bool isLnurl(String code) {
    final lower = code.trim().toLowerCase();
    return lower.startsWith('lnurl') ||
        lower.startsWith('lnurlp') ||
        lower.startsWith('lnurlw') ||
        lower.contains('lnurlp') ||
        lower.contains('lnurlw');
  }

  bool isLightningAddress(String code) {
    final trimmed = code.trim();
    return trimmed.contains('@') &&
        trimmed.contains('.') &&
        !trimmed.startsWith('http') &&
        trimmed.length > 5;
  }

  bool isCryptoPayId(String code) {
    final trimmed = code.trim().toUpperCase();
    return trimmed.startsWith('CP-') || trimmed.startsWith('CP');
  }

  bool isUrl(String code) {
    final lower = code.trim().toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  // ════════════════════════════════════════════════════════════
  // EXTRACTION
  // ════════════════════════════════════════════════════════════

  String? extractBolt11(String code) {
    var clean = code.trim();
    if (clean.toLowerCase().startsWith('lightning:')) {
      clean = clean.substring(10);
    }
    if (isLightningInvoice(clean)) return clean;
    return null;
  }

  String? extractLnurl(String code) {
    var clean = code.trim();
    // Si c'est une URL avec paramètre LNURL
    if (clean.toLowerCase().startsWith('http')) {
      final uri = Uri.tryParse(clean);
      if (uri != null) {
        // Cherche le paramètre 'lnurl' ou 'lightning'
        if (uri.queryParameters.containsKey('lnurl')) {
          return uri.queryParameters['lnurl'];
        }
        if (uri.queryParameters.containsKey('lightning')) {
          return uri.queryParameters['lightning'];
        }
      }
    }
    if (isLnurl(clean)) return clean;
    return null;
  }

  String? extractCryptoPayId(String code) {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.startsWith('CP-') || trimmed.startsWith('CP')) {
      // Nettoie pour avoir uniquement l'ID
      final match = RegExp(r'(CP-?[A-Z0-9]{6,})').firstMatch(trimmed);
      return match?.group(1) ?? trimmed;
    }
    return null;
  }

  // ════════════════════════════════════════════════════════════
  // ANALYSE
  // ════════════════════════════════════════════════════════════

  QrCodeType analyzeCode(String code) {
    final trimmed = code.trim();
    if (isLightningInvoice(trimmed)) return QrCodeType.lightningInvoice;
    if (isLnurl(trimmed)) return QrCodeType.lnurl;
    if (isLightningAddress(trimmed)) return QrCodeType.lightningAddress;
    if (isCryptoPayId(trimmed)) return QrCodeType.cryptoPayId;
    if (isUrl(trimmed)) return QrCodeType.url;
    return QrCodeType.unknown;
  }

  /// Analyse détaillée avec plus d'informations
  QrAnalysisResult analyzeDetailed(String code) {
    final type = analyzeCode(code);
    return QrAnalysisResult(
      type: type,
      raw: code,
      bolt11: type == QrCodeType.lightningInvoice ? extractBolt11(code) : null,
      lnurl: type == QrCodeType.lnurl ? extractLnurl(code) : null,
      cryptoPayId: type == QrCodeType.cryptoPayId
          ? extractCryptoPayId(code)
          : null,
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TYPES
// ════════════════════════════════════════════════════════════════

enum QrCodeType {
  lightningInvoice,
  lnurl,
  lightningAddress,
  cryptoPayId,
  url,
  unknown,
}

class QrAnalysisResult {
  final QrCodeType type;
  final String raw;
  final String? bolt11;
  final String? lnurl;
  final String? cryptoPayId;

  QrAnalysisResult({
    required this.type,
    required this.raw,
    this.bolt11,
    this.lnurl,
    this.cryptoPayId,
  });

  bool get isLightning =>
      type == QrCodeType.lightningInvoice || type == QrCodeType.lnurl;
  bool get isCryptoPay =>
      type == QrCodeType.cryptoPayId || type == QrCodeType.lightningAddress;
  bool get isUnknown => type == QrCodeType.unknown;
}
