## Crypto-Pay — Résumé du projet

### Objectif du projet
Crypto-Pay est une application mobile Flutter de portefeuille Bitcoin / Lightning visant à permettre aux utilisateurs de :
- envoyer et recevoir des paiements,
- gérer un solde en USD et Bitcoin,
- vérifier des comptes avec KYC,
- utiliser des comptes enfants sous supervision parentale.

---

## Fonctionnalités principales

### 1. Authentification et compte utilisateur
- Connexion / inscription avec email et mot de passe.
- Gestion de l’état utilisateur via Riverpod (`authProvider`).
- Intégration avec Supabase pour l’authentification, le stockage et la logique métier.

### 2. Dashboard principal
- Affiche le solde principal en USD et une estimation BTC.
- Affiche les dernières transactions et statistiques de la semaine.
- Boutons rapides pour :
  - envoyer de l’argent,
  - recevoir de l’argent,
  - accéder aux paramètres,
  - rechercher.

### 3. Envoyer un paiement
- Page de paiement avec :
  - montant,
  - destinataire (ID / email / Lightning),
  - note facultative.
- Contrôle de confirmation en glissant avec un cercle blanc et icône éclair.
- Appel du service Supabase pour exécuter la transaction.
- Écran de succès après paiement validé.

### 4. Recevoir un paiement
- Génération d’une demande / facture Lightning.
- Affichage du code QR et éventuellement des détails de réception.

### 5. Profil et compte
- Affiche les informations du compte utilisateur.
- Page de profil avec navigation vers :
  - historique des transactions,
  - paramètres,
  - informations personnelles.

### 6. Paramètres et support
- Réglages de l’application :
  - intensité de l’interface,
  - biométrie (Face ID / empreinte),
  - langue.
- Page “À propos” avec :
  - politique de confidentialité,
  - conditions d’utilisation,
  - version et copyright.

### 7. Gestion des comptes mineurs
- Interface parent/enfant.
- Création de comptes enfants.
- Approbation des transactions enfants.

---

## Architecture technique

### Flutter + Riverpod
- UI construite en Flutter.
- État géré par Riverpod.
- Composants réutilisables :
  - `GlassContainer`,
  - `GlassButton`,
  - thèmes personnalisés.

### Backend Supabase
- Appels à Supabase pour :
  - récupération du solde,
  - historique de transactions,
  - envoi de paiements,
  - création d’invoices Lightning,
  - gestion des comptes/KYC.

### UI et expérience
- Thème sombre “Liquid Glass”
- Décorations glassmorphiques
- Animations simples (barres de statistiques, slide-to-pay)

---

## Points importants à expliquer à l’équipe

- L’app ne repose plus sur des mock data pour les pages critiques : profil, statistiques, paiements.
- Le paiement utilise maintenant un geste de glissement réel plutôt qu’un simple bouton.
- La page de notification et la page “À propos” ont été ajoutées pour rendre l’expérience plus complète.
- La donnée utilisateur est centralisée via `authProvider` et les providers Supabase.
- Le projet est conçu pour être extensible :
  - ajout de nouveaux services Supabase,
  - amélioration des écrans KYC / parental,
  - renforcement des règles métier.

---

## Priorités pour la suite du projet

1. Finaliser les notifications réelles et l’historique de messages.
2. Ajouter des écrans de paramétrage plus complets (sécurité, support).
3. Renforcer la logique KYC / fraude.
4. Ajouter des tests d’intégration sur les flux paiement et profil.
5. Prévoir l’internationalisation si besoin.

---

## Résumé pour présentation
Crypto-Pay est une application de portefeuille Bitcoin + Lightning, orientée utilisateur, avec :
- gestion de compte,
- paiement et réception rapides,
- supervision parentale,
- interface premium,
- backend Supabase.

> Le projet est désormais structurée autour d’UI dynamiques et de données réelles, prêt pour l’étape suivante : enrichir les fonctionnalités de sécurité, d’historique et de notifications.