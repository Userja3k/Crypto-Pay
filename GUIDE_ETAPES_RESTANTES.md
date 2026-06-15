# Guide Simple : Les Étapes pour Lancer Crypto-Pay en Réel 🚀

Ce document t'explique simplement ce qu'il reste à faire pour que ton application passe de "maquette" à "application réelle" capable d'envoyer du vrai Bitcoin.

---

## 1. Le "Pont" vers Bitcoin (Intégration LND) ⚡
**C'est quoi ?** 
Ton application est comme une télécommande, mais il faut la brancher à la télévision (le réseau Bitcoin). Le nœud LND est ton récepteur Bitcoin.

**Ce que tu dois faire :**
- **Avoir un nœud Lightning** : Tu peux en louer un (Voltage, Umbrel, ou un VPS).
- **Récupérer 3 infos** : 
  1. L'adresse IP de ton nœud.
  2. Le fichier `tls.cert` (le certificat de sécurité).
  3. Le fichier `admin.macaroon` (ta clé d'autorisation).

**Ce que j'ai fait :** 
J'ai préparé le code (Edge Function) dans `supabase/functions/lnd-integration/` qui utilise ces 3 infos pour envoyer les ordres de paiement.

---

## 2. L'Horloge des Prix (Oracle de Taux) 📈
**C'est quoi ?** 
Le prix du Bitcoin change toutes les secondes. Il faut que ton application sache à chaque instant que 1$ = X satoshis.

**Ce que tu dois faire :**
- Rien de spécial, juste activer le script que j'ai préparé.
- (Optionnel) Créer un compte gratuit sur CoinGecko pour avoir une clé API plus rapide.

**Ce que j'ai fait :** 
Un script dans `supabase/functions/price-oracle/` qui va chercher le prix sur internet et met à jour ta base de données automatiquement.

---

## 3. Le Coffre-Fort (Stockage KYC) 🔐
**C'est quoi ?** 
Quand un utilisateur envoie sa carte d'identité, la photo doit être stockée quelque part en sécurité.

**Ce que tu dois faire :**
1. Va sur ton Dashboard **Supabase**.
2. Clique sur **Storage**.
3. Crée un "Bucket" nommé `kyc-documents`.
4. Coche la case "Restricted" (pour que seul toi puisse voir les documents).
(Done)
---

## 4. Les Alertes (Notifications FCM) 🔔
**C'est quoi ?** 
Prévenir l'utilisateur quand il reçoit de l'argent, même si l'application est fermée.

**Ce que tu dois faire :**
1. Crée un projet sur **Firebase Console** (gratuit).
2. Télécharge le fichier `google-services.json` pour Android et `GoogleService-Info.plist` pour iOS.
3. Mets-les dans les dossiers `android/app/` et `ios/Runner/` de ton projet Flutter.
4. Copie la "Clé Serveur" dans les paramètres Supabase.

---

## 5. Le Grand Lancement (Production & Mainnet) 🌍
**C'est quoi ?** 
Quitter le mode "Test" pour utiliser de l'argent réel.

**Ce que tu dois faire :**
- **Serveur (VPS)** : Loue un petit serveur (ex: Hetzner ou DigitalOcean) pour faire tourner ton nœud 24h/24.
- **Domaine** : Achète un nom de domaine (ex: `crypto-pay.cd`).
- **Mainnet** : Dans la configuration de ton nœud LND, remplace `testnet=1` par `mainnet=1`. **Attention :** utilise des petits montants au début pour tester !

---

## Résumé : De quoi as-tu besoin maintenant ?

| Élément | Source | Utilité |
| :--- | :--- | :--- |
| **VPS** | Hetzner / DigitalOcean | Héberger ton nœud Bitcoin |
| **Clé gRPC** | Ton nœud LND | Autoriser Supabase à envoyer des fonds |
| **Compte Firebase** | Google | Envoyer des notifications |
| **Compte Apple/Google** | Apple Store / Play Store | Publier l'application |

**Mon conseil :** Commence par faire fonctionner le point **#3 (KYC)** et **#2 (Prix)**, c'est le plus facile !
