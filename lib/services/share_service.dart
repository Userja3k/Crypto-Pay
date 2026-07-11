// lib/services/share_service.dart
// Version complète avec LNURL

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  ShareService._internal();
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;

  // ════════════════════════════════════════════════════════
  // MÉTHODES EXISTANTES
  // ════════════════════════════════════════════════════════

  Future<void> shareText({required String text, String? subject}) async {
    try {
      await Share.share(text, subject: subject);
    } catch (e) {
      debugPrint('Erreur de partage: $e');
      rethrow;
    }
  }

  Future<void> shareReferralCode(
      {required String code, required String userName}) async {
    final message = '''
🎉 Rejoins Crypto-Pay avec mon code de parrainage !

Code: $code

Télécharge l'app et utilise le code pour recevoir 2 dollards à l'inscription !
''';
    await shareText(text: message, subject: 'Code de parrainage Crypto-Pay');
  }

  Future<void> sharePaymentReceipt({
    required double amount,
    required String recipient,
    required String date,
    String? transactionId,
  }) async {
    final receipt = '''
═══════════════════════════════════
         REÇU CRYPTO-PAY
═══════════════════════════════════

📅 Date : $date
💰 Montant : ${amount.toStringAsFixed(2)}
👤 Destinataire : $recipient
${transactionId != null ? '🆔 Transaction : $transactionId' : ''}

═══════════════════════════════════
    ''';
    await shareText(text: receipt, subject: 'Reçu de paiement Crypto-Pay');
  }

  Future<void> shareProfile({
    required String userName,
    required String userId,
    required String referralCode,
  }) async {
    final profile = '''
═══════════════════════════════════
        PROFIL CRYPTO-PAY
═══════════════════════════════════

👤 Nom : $userName
🆔 ID : $userId
🎯 Code parrainage : $referralCode

═══════════════════════════════════
    ''';
    await shareText(text: profile, subject: 'Mon profil Crypto-Pay');
  }

  // ════════════════════════════════════════════════════════
  // NOUVEAU : LNURL
  // ════════════════════════════════════════════════════════

  /// Partage un LNURL-Withdraw pour recevoir des fonds
  Future<void> shareLnurlWithdraw({
    required String lnurl,
    required double amountUsd,
    String? memo,
  }) async {
    final message = '''
═══════════════════════════════════
    DEMANDE DE PAIEMENT
═══════════════════════════════════

💰 Montant : ${amountUsd.toStringAsFixed(2)}
${memo != null ? '📝 Note : $memo' : ''}

📡 LNURL :
$lnurl

Scannez ce LNURL avec votre wallet Lightning.
    ''';
    await shareText(text: message, subject: 'Demande de paiement Crypto-Pay');
  }

  /// Partage un LNURL-Pay pour recevoir des paiements (commerçant)
  Future<void> shareLnurlPay({
    required String lnurl,
    String? merchantName,
    String? description,
  }) async {
    final message = '''
═══════════════════════════════════
    PAIEMENT CRYPTO-PAY
═══════════════════════════════════

${merchantName != null ? '🏪 $merchantName' : 'Paiement Crypto-Pay'}
${description != null ? '📝 $description' : ''}

📡 LNURL-Pay :
$lnurl

Scannez ce LNURL pour effectuer un paiement.
    ''';
    await shareText(text: message, subject: 'Paiement Crypto-Pay');
  }

  /// Partage une adresse Lightning
  Future<void> shareLightningAddress({
    required String address,
    String? recipientName,
  }) async {
    final message = '''
═══════════════════════════════════
    ADRESSE LIGHTNING
═══════════════════════════════════

${recipientName != null ? '👤 $recipientName' : ''}
⚡ $address

Envoyez-moi des sats sur cette adresse Lightning.
    ''';
    await shareText(text: message, subject: 'Adresse Lightning Crypto-Pay');
  }
}
