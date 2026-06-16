## ✅ Ce qu’il reste à faire

### 1. Comprendre où se trouve le code Supabase
Dans ton projet, les scripts TypeScript sont ici :
- index.ts
- index.ts

Ce ne sont pas des fichiers Flutter. Ce sont des fonctions “Edge Function” qui tournent sur Supabase / Deno. Elles servent de pont entre ton app mobile et des services externes (prix Bitcoin, nœud Lightning, etc.).

---

## Ce que fait chaque script

### `price-oracle/index.ts`
- Récupère le prix du Bitcoin sur CoinGecko.
- Appelle une RPC Supabase `admin_update_exchange_rate`.
- Met à jour la table des taux de change dans la base.
- C’est une tâche programmée : elle doit tourner régulièrement, par exemple toutes les 10 minutes.

### `lnd-integration/index.ts`
- C’est le point d’entrée de l’intégration Lightning.
- Il reçoit un JSON avec `action`, `amount_sats`, `invoice`, `memo`.
- Il doit appeler ton nœud LND :
  - `action = create_invoice` → créer une facture Lightning
  - `action = send_payment` → envoyer un paiement Lightning

Actuellement, il ne fait que renvoyer des réponses factices (`lnbc...`, `success: true`). Il n’est pas encore connecté à un vrai nœud.

---

## Pourquoi tu dois commencer par Lightning

Parce que c’est le cœur de Crypto-Pay :
- c’est lui qui permet d’envoyer et recevoir du vrai Bitcoin Lightning,
- c’est le côté le plus technique et le plus fragile.

L’ordre logique est donc :
1. configurer le nœud LND,
2. faire le pont via Supabase (`lnd-integration`),
3. connecter l’app à ce pont,
4. puis gérer le prix et KYC.

---

## Ce qu’il faut faire exactement — étape par étape

### Étape 1 : installer / obtenir un nœud Lightning LND
Tu as besoin d’un nœud qui fonctionne en `mainnet` ou `testnet`.

Tu dois récupérer :
- `LND_HOST` → l’adresse de ton nœud (ex : `https://mon-noeud:8080`)
- `tls.cert` → certificat TLS de ton nœud
- `admin.macaroon` → la clé d’administration pour autoriser les actions

Ces informations ne vont pas dans Flutter, elles vont dans Supabase comme secrets.

---

### Étape 2 : configurer les secrets dans Supabase
Dans Supabase, va dans :
- `Settings` > `Secrets`
- Ajoute :
  - `LND_HOST`
  - `LND_MACAROON`
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`

Ces variables sont utilisées par les fonctions Deno.

---

### Étape 3 : déployer les fonctions Supabase
Les fichiers TS sont déjà dans functions.
Tu dois les déployer sur Supabase pour qu’ils deviennent actifs.

Si tu utilises la CLI Supabase, ce sera quelque chose comme :
- `supabase login`
- `supabase init` (si besoin)
- `supabase functions deploy price-oracle`
- `supabase functions deploy lnd-integration`

Si tu utilises l’interface web Supabase, tu peux aussi copier/coller le code dans les fonctions Edge.

---

### Étape 4 : implémenter le vrai code Lightning
Aujourd’hui `lnd-integration/index.ts` est juste un squelette. Il faut :
- ajouter l’appel réel à LND
- gérer les réponses
- gérer les erreurs

Exemple de logique :
- `create_invoice` → appeler l’API LND pour créer une facture, puis renvoyer `bolt11`
- `send_payment` → envoyer un invoice ou payer un `bolt11`, puis renvoyer `preimage`

Tu peux utiliser :
- `fetch()` vers l’API REST de LND,
- ou un client gRPC si tu veux faire plus propre.

---

### Étape 5 : sécuriser le stockage KYC
Dans Supabase :
- crée un bucket `kyc-documents`
- marque-le `restricted`
- ne laisse pas ces fichiers publics

C’est important parce que tu stockes des pièces d’identité.

---

### Étape 6 : connecter l’application à ces fonctions
Dans Flutter, l’application doit appeler :
- la fonction `lnd-integration` pour envoyer et recevoir
- la fonction `price-oracle` éventuellement pour lire le prix ou suivre l’état

Normalement, ce sont des appels réseau protégés par Supabase / auth.

---

## Ce qui est confus dans la manière actuelle

### Pourquoi tu es perdu
- parce que tu as des scripts TypeScript dans Supabase, mais le code côté app n’est pas clair sur comment il les utilise
- parce qu’on ne t’a pas montré le “flux” :
  - App Flutter → Supabase Edge Function → LND
- parce que `lnd-integration` n’est pas rempli, donc on ne voit pas le vrai point d’entrée

---

## Ce qui reste à comprendre en priorité

### Le vrai point d’entrée Lightning
C’est index.ts.

C’est lui qui va :
- recevoir la requête,
- contacter le nœud Lightning,
- renvoyer le résultat à l’application.

En pratique, c’est la “porte d’entrée” vers Lightning.

### Ce qu’il faut chercher dans Supabase
- les fonctions Edge (`functions/`)
- les secrets
- les routes invoquées par l’app
- la table `exchange_rates` ou la fonction RPC `admin_update_exchange_rate`

---

## Liste précise des restants

### 1. Mettre en place le nœud LND
- choisir un nœud (local ou loué)
- récupérer `host`, `tls.cert`, `admin.macaroon`
- vérifier s’il est en `testnet` ou `mainnet`

### 2. Déployer et configurer `lnd-integration`
- ajouter les secrets Supabase
- implémenter les vraies requêtes LND
- tester avec `create_invoice` et `send_payment`

### 3. Déployer et configurer `price-oracle`
- s’assurer que la fonction peut accéder au service role key
- programmer l’exécution automatique
- vérifier que `exchange_rates` se met à jour

### 4. Configurer le stockage KYC
- créer `kyc-documents`
- restreindre l’accès

### 5. Relier Flutter à Supabase / Lightning
- vérifier dans le code Flutter où sont appelées les fonctions
- remplacer les mock/responses factices par des vraies requêtes

### 6. Tester
- commencer en `testnet`
- envoyer une petite somme
- recevoir une facture
- vérifier que la base de données réagit

---

## Comment le dire à la team

Tu peux dire :
- “On a deux éléments principaux : le client Flutter et le backend Supabase”
- “Le backend Supabase contient deux fonctions importantes : une pour le prix du BTC, une autre pour le lien avec LND”
- “Le point d’entrée Lightning est `lnd-integration`; c’est lui qui va appeler le nœud LND”
- “Il faut d’abord configurer notre nœud Lightning et les secrets dans Supabase avant de connecter l’app”
- “Ensuite on teste en `testnet`, puis on passe à `mainnet`”

---

## Conclusion
Ton dossier functions n’est pas du “javascript inutile” : c’est la couche serveur.
Ce qui manque vraiment, c’est de :
- déployer ces fonctions,
- les relier à un vrai nœud LND,
- puis faire communiquer Flutter avec elles.

Si tu veux, je peux maintenant te faire un schéma clair du flux exact :
`App Flutter → Supabase lnd-integration → Nœud LND` et te dire où placer chaque config.