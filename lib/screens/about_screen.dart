import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('À propos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              opacity: 0.08,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Crypto-Pay', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 12),
                  Text('Version 1.0.0', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('© 2026 Crypto-Pay. Tous droits réservés.', style: TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassContainer(
              borderRadius: 24,
              opacity: 0.08,
              child: Column(
                children: [
                  _AboutButton(
                    label: 'Politique de confidentialité',
                    description: 'Voir la politique de confidentialité',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                    },
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  _AboutButton(
                    label: 'Conditions d\'utilisation',
                    description: 'Voir les conditions d\'utilisation',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfUseScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Version 1.0.0 • © 2026 Crypto-Pay',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutButton extends StatelessWidget {
  final String label;
  final String description;
  final VoidCallback onTap;

  const _AboutButton({
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Politique de confidentialité'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('POLITIQUE DE CONFIDENTIALITÉ – CRYPTO-PAY', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Dernière mise à jour : 1er juin 2026', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 20),
            Text('1. INTRODUCTION', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Crypto-Pay ("nous", "notre", "nos") respecte votre vie privée. Cette politique explique quelles données nous collectons, pourquoi nous les collectons, et comment nous les protégeons.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 8),
            Text('En utilisant l\'application Crypto-Pay, vous acceptez les termes décrits ci-dessous.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('2. QUELLES DONNÉES NOUS COLLECTONS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Données que vous nous fournissez :', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 4),
            Text('- Nom et prénom\n- Adresse email\n- Numéro de téléphone\n- Date de naissance (pour vérification de l\'âge)\n- Photo d\'identité (pour les comptes vérifiés)\n- Numéro d\'identification national (selon votre pays)', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 12),
            Text('Données générées par l\'utilisation :', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 4),
            Text('- Adresses Lightning utilisées\n- Montants des transactions (uniquement le montant, pas l\'objet)\n- Horodatage des transactions\n- Type d\'appareil et système d\'exploitation\n- Adresse IP (anonymisée après 30 jours)', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 12),
            Text('Données que nous NE collectons PAS :', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 4),
            Text('- Votre clé privée Bitcoin (elle reste sur votre appareil)\n- Votre mot de passe (il est haché)\n- Le contenu de vos messages ou communications\n- Vos contacts téléphoniques', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('3. POURQUOI NOUS COLLECTONS CES DONNÉES', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Nom, email, téléphone : Créer et gérer votre compte\nDate de naissance : Vérifier que vous avez l\'âge légal (18 ans)\nPhoto d\'identité : Prévenir la fraude et le blanchiment d\'argent\nTransactions : Calculer votre solde et générer l\'historique\nAdresse IP : Protéger contre les attaques informatiques', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('4. STOCKAGE ET SÉCURITÉ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Vos données sont stockées sur des serveurs sécurisés. Les mots de passe sont hachés (nous ne pouvons pas les lire). Les transactions sont chiffrées de bout en bout.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 8),
            Text('Durée de conservation :\n- Données de compte : jusqu\'à suppression de votre compte\n- Transactions : 5 ans (obligation légale)\n- Adresses IP : 30 jours', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('5. PARTAGE DES DONNÉES', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Nous ne vendons jamais vos données personnelles. Nous partageons uniquement dans ces cas :', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 4),
            Text('Autorités légales : Si un tribunal nous y oblige.\nPartenaires techniques : Notre hébergeur et notre fournisseur Lightning. Ces partenaires signent un accord de confidentialité.\nTransfert international : Vos données peuvent être stockées hors de votre pays. Nous choisissons des pays avec des lois protectrices.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('6. VOS DROITS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Selon votre pays, vous pouvez :\n- Accéder à toutes vos données\n- Corriger une erreur\n- Supprimer votre compte (et toutes vos données)\n- Exporter vos transactions (format PDF ou CSV)\n- Retirer votre consentement à tout moment', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 8),
            Text('Pour exercer ces droits : confidentialite@crypto-pay.com', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('7. COMPTES MINEURS (MOINS DE 18 ANS)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Un mineur ne peut pas créer de compte seul. Le parent ou tuteur doit créer son propre compte, ajouter un compte "enfant", et approuver chaque transaction.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('8. NOTIFICATIONS ET PERMISSIONS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Notifications push : Vous pouvez les désactiver.\nCaméra (QR code) : Utilisée uniquement quand vous scannez.\nNFC/Bluetooth : Utilisés uniquement pendant un paiement.\nBiométrie : Les données restent sur votre appareil.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('9. EN CAS DE PERTE DE TÉLÉPHONE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Contactez-nous immédiatement : support@crypto-pay.com. Nous gèlerons votre compte. Restaurez-le avec votre phrase de récupération (12 mots). Sans cette phrase, nous ne pouvons pas restaurer vos fonds.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('10. MODIFICATIONS DE CETTE POLITIQUE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('En cas de changement important, vous recevrez une notification dans l\'application et devrez accepter les nouvelles conditions.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('11. NOUS CONTACTER', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Email : confidentialite@crypto-pay.com\nDélai de réponse : 7 jours ouvrés maximum.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('12. PLAINTE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Contactez-nous d\'abord. Si vous n\'êtes pas satisfait, contactez l\'autorité de protection des données de votre pays.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Conditions d\'utilisation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('CONDITIONS D\'UTILISATION – CRYPTO-PAY', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Dernière mise à jour : 1er juin 2026', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 20),
            Text('1. ACCEPTATION DES CONDITIONS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('En créant un compte ou en utilisant l\'application Crypto-Pay ("l\'Application"), vous acceptez d\'être lié par ces Conditions d\'Utilisation ("Conditions").', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('2. DESCRIPTION DU SERVICE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Crypto-Pay est une application de portefeuille Bitcoin qui utilise le réseau Lightning Network pour permettre l\'envoi, la réception de paiements, la conversion entre USD et Bitcoin, et la gestion de comptes.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 8),
            Text('Avertissement : Crypto-Pay n\'est pas une banque. Les fonds ne sont pas assurés.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('3. ÉLIGIBILITÉ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Compte adulte : 18 ans et plus.\nCompte mineur : Moins de 18 ans, avec parent ou tuteur.\nSont exclus : Personnes sous sanctions, pays où Bitcoin est interdit.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('4. CRÉATION ET SÉCURITÉ DU COMPTE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Vous êtes responsable de votre mot de passe, phrase de récupération (12 mots), et de la sécurité de votre téléphone. Sans la phrase de récupération, les fonds sont définitivement perdus.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('5. TRANSACTIONS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Les transactions sur Lightning sont quasi-instantanées et irréversibles. Limites selon vérification. Vérifiez toujours l\'adresse avant confirmation.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('6. FRAIS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Envoi (<10\$) : 1%\nEnvoi (10\$-100\$) : 0.5%\nEnvoi (>100\$) : 0.3%\nRéception : gratuit\nConversion : 0.5%\nInactivité (12 mois) : 1\$/mois', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('7. CONVERSION DE DEVISES', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Le solde affiché est en USD. Le Bitcoin sous-jacent fluctue. Frais de conversion : 0.5%.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('8. COMPORTEMENTS INTERDITS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Sont interdits : blanchiment, terrorisme, biens illégaux, fraude, jeux d\'argent non autorisés, contournement des sanctions. Conséquences : suspension, gel des fonds, signalement.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('9. SUSPENSION ET RÉSILIATION', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Nous pouvons suspendre ou supprimer votre compte pour fraude ou inactivité (3 ans). Vous pouvez supprimer votre compte dans Paramètres.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('10. DISPONIBILITÉ DU SERVICE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Service 24/7, mais des interruptions peuvent survenir (panne électrique, attaque, décision gouvernementale). Nous ne sommes pas responsables des pertes liées.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('11. LIMITATION DE RESPONSABILITÉ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Nous ne sommes pas responsables des pertes dues à erreur utilisateur, vol, fluctuation du Bitcoin, ou décision gouvernementale. Responsabilité maximale : les frais payés les 12 derniers mois.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('12. PROPRIÉTÉ INTELLECTUELLE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('L\'Application est notre propriété. Usage personnel uniquement. Pas de copie, revente, ou produit concurrent.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('13. CESSION', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Le compte est personnel et non transférable.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('14. DROIT APPLICABLE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Lois de la République Démocratique du Congo. Litiges d\'abord résolus à l\'amiable.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('15. COMMUNICATIONS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Notifications, email, SMS. Contact : support@crypto-pay.com', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('16. MODIFICATIONS DES CONDITIONS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Notification 30 jours avant tout changement majeur. Refuser = fermer le compte.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('17. DIVERS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Ces Conditions remplacent tout accord précédent.', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 16),
            Text('18. NOUS CONTACTER', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Email : support@crypto-pay.com', style: TextStyle(color: Colors.white70, height: 1.5)),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
