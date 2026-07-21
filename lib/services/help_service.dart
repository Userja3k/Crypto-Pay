import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpService {
  HelpService._internal();
  static final HelpService _instance = HelpService._internal();
  factory HelpService() => _instance;

  List<FaqItem> getFaqs() {
    return [
      FaqItem(question: 'Comment envoyer un paiement ?', answer: 'Allez dans Payer, scannez un QR ou entrez l\'ID.'),
      FaqItem(question: 'Comment recevoir ?', answer: 'Générez une facture Lightning dans Recevoir.'),
      FaqItem(question: 'KYC', answer: 'Soumettez une pièce d\'identité dans Vérification.'),
    ];
  }

  Future<void> openHelpLink(String url) async {
    final uri = Uri.parse(url);
    try {
      var launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(uri);
      }
      if (!launched) {
        throw Exception('Impossible d\'ouvrir le lien');
      }
    } catch (error) {
      throw Exception('Impossible d\'ouvrir le lien: $error');
    }
  }

  String getDocumentationUrl() => 'https://docs.crypto-pay.com';
  String getSupportUrl() => 'mailto:support@crypto-pay.com';
}

class FaqItem {
  final String question;
  final String answer;
  FaqItem({required this.question, required this.answer});
}
