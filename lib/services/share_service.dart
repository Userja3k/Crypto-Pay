import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  ShareService._internal();
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;

  Future<void> shareText({required String text, String? subject}) async {
    try {
      await Share.share(text, subject: subject);
    } catch (e) {
      debugPrint('Erreur de partage: $e');
      rethrow;
    }
  }

  Future<void> shareReferralCode({required String code, required String userName}) async {
    final message = '''🎉 Rejoins Crypto-Pay avec mon code de parrainage !\n\nCode: $code\n\nTélécharge l'app et utilise le code.''';
    await shareText(text: message, subject: 'Code de parrainage Crypto-Pay');
  }

  Future<void> sharePaymentReceipt({required double amount, required String recipient, required String date, String? transactionId}) async {
    final receipt = '''Reçu Crypto-Pay\nDate: $date\nMontant: \$${amount.toStringAsFixed(2)}\nDestinataire: $recipient\n${transactionId != null ? 'Transaction: $transactionId' : ''}''';
    await shareText(text: receipt, subject: 'Reçu de paiement');
  }

  Future<void> shareProfile({required String userName, required String userId, required String referralCode}) async {
    final profile = 'Profil Crypto-Pay\nNom: $userName\nID: $userId\nCode: $referralCode';
    await shareText(text: profile, subject: 'Mon profil Crypto-Pay');
  }
}
