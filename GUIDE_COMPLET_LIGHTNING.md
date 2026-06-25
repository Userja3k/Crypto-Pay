# 🚀 Guide Complet : Intégration Lightning dans Crypto-Pay

## Le problème
Tu as des scripts TypeScript dans `supabase/functions/` mais tu ne sais pas:
- Où ils s'exécutent
- Comment ils se connectent à l'app Flutter
- Comment s'y connecter
- Par où commencer

**Bonne nouvelle**: Je vais tout clarifier étape par étape.

---

## 📊 L'architecture générale

```
┌─────────────────────────────────────────────────────────────────┐
│                      TON APPLICATION FLUTTER                    │
│                   (screens/ providers/)                          │
│  - send_payment_screen.dart                                     │
│  - receive_payment_screen.dart                                  │
│  - user_provider.dart (authProvider)                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Appels réseau via Supabase SDK
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              SUPABASE BACKEND (Cloud)                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Edge Functions (TypeScript/Deno)                         │  │
│  │ - supabase/functions/lnd-integration/index.ts           │  │
│  │ - supabase/functions/price-oracle/index.ts              │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Base de données PostgreSQL                              │  │
│  │ - users, transactions, balances, exchange_rates         │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Appels via REST/gRPC
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      TON NŒUD LIGHTNING (LND)                   │
│                    (mainnet ou testnet)                         │
│  - API gRPC pour créer des factures                            │
│  - API REST pour envoyer des paiements                         │
│  - Clés macaroon pour l'authentification                       │
└─────────────────────────────────────────────────────────────────┘
```

**Ce qui est important comprendre:**
- Les scripts TypeScript **ne s'exécutent pas sur ton ordinateur**
- Ils s'exécutent sur **les serveurs de Supabase** (c'est du cloud)
- Ils agissent comme un **pont** entre l'app Flutter et le nœud Lightning

---

## 🔍 Où se trouve quoi

### 1. ✅ L'app Flutter (déjà codée)
```
lib/
  screens/
    send_payment_screen.dart      ← Page pour envoyer du Bitcoin
    receive_payment_screen.dart   ← Page pour recevoir du Bitcoin
    home_screen.dart              ← Affiche le solde et transactions
  providers/
    user_provider.dart            ← Gère l'authentification et les appels
  services/
    supabase_service.dart         ← Logique métier (appels Supabase)
```

### 2. 🔧 Les scripts TypeScript (serveurs cloud Supabase)
```
supabase/
  functions/
    lnd-integration/
      index.ts                    ← Le PONT VERS LIGHTNING
    price-oracle/
      index.ts                    ← Met à jour le prix du Bitcoin
  migrations/
    001_create_tables.sql         ← Schéma de la base de données
```

### 3. ⚡ Ton nœud Lightning (ta propriété)
```
Sur un serveur (VPS, Raspberry Pi, etc.)
  LND (Lightning Network Daemon)
    ├── API gRPC (port 10009)
    ├── admin.macaroon (autorisation)
    └── tls.cert (certificat SSL)
```

---

## 🎯 CE QU'IL FAUT FAIRE - Ordre d'action

### Phase 1 : Comprendre le flux (30 min)

#### Étape 1.1 : Lire le code Flutter qui appelle Supabase
Ouvre `lib/providers/user_provider.dart` et cherche cette fonction:

```dart
final supabaseServiceProvider = Provider((ref) {
  return SupabaseService();
});
```

C'est elle qui fait les appels au backend.

#### Étape 1.2 : Lire le code qui appelle le service
Ouvre `lib/screens/send_payment_screen.dart` et cherche:

```dart
final result = await ref.read(supabaseServiceProvider).sendPayment(
  senderUserId: ...,
  amountUsd: ...,
  ...
);
```

**Comprendre**: Cette ligne appelle une fonction Supabase qui, elle-même, va appeler le nœud Lightning.

#### Étape 1.3 : Lire les scripts TypeScript (le pont)
Ouvre `supabase/functions/lnd-integration/index.ts`.

Tu verras:
```typescript
serve(async (req) => {
  const { action, amount_sats, invoice, memo } = await req.json()
  
  // TODO: Appeler le nœud LND ici
  if (action === 'create_invoice') {
    // Créer une facture Lightning
  }
  if (action === 'send_payment') {
    // Envoyer un paiement Lightning
  }
})
```

**Comprendre**: Ce code reçoit des ordres de Flutter et contacte le nœud Lightning.

---

### Phase 2 : Préparer l'infrastructure (1-2 jours)

#### Étape 2.1 : Obtenir un nœud Lightning LND
Tu as 3 choix:

**Option A: Louer un nœud (RECOMMANDÉ pour commencer)**
- Voltage.cloud (gratuit jusqu'à 10 millions de satoshis)
- Phoenix pour testnet
- Start9 pour auto-hébergement

**Option B: Installer localement**
- Sur Windows: Umbrel sur un NAS ou VPS
- Sur Linux: Suivre https://github.com/lightningnetwork/lnd

**Option C: Testnet (pour tester)**
- Utiliser le testnet Bitcoin de Voltage

**⚠️ Pour commencer**: Utilise Voltage.cloud en testnet (gratuit, plus facile).

#### Étape 2.2 : Récupérer les infos du nœud
Une fois que tu as un nœud, récupère:

```
LND_HOST = https://[mon-noeud]:8080
LND_MACAROON = [le contenu du fichier admin.macaroon en base64]
LND_CERT = [le contenu du fichier tls.cert en base64]
```

**Attention**: Ces infos sont **secrètes**. Ne les mets jamais sur GitHub.

---

### Phase 3 : Configurer Supabase (30 min)

#### Étape 3.1 : Ajouter les secrets dans Supabase

Va dans ton Dashboard Supabase:
- Settings > Secrets (ou Env > Secrets)
- Ajoute:
  - `LND_HOST` → la valeur récupérée
  - `LND_MACAROON` → la valeur récupérée
  - `LND_CERT` → la valeur récupérée

Ces variables seront disponibles dans les scripts TypeScript via `Deno.env.get('LND_HOST')`, etc.

#### Étape 3.2 : Vérifier la base de données
Les tables doivent déjà exister (créées par les migrations):
- `users`
- `transactions`
- `balances`
- `exchange_rates`

Si elles n'existent pas, exécute les migrations dans `supabase/migrations/`.

---

### Phase 4 : Implémenter le vrai code Lightning (2-3 jours)

#### Étape 4.1 : Implémenter `lnd-integration/index.ts`

Actuellement, le fichier est vide. Tu dois le remplir pour qu'il:

1. **Reçoive** les ordres de Flutter
2. **Appelle** le nœud Lightning
3. **Renvoie** les réponses

Exemple simplifié:

```typescript
// supabase/functions/lnd-integration/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { action, amount_sats, invoice, memo } = await req.json()

  const LND_HOST = Deno.env.get('LND_HOST')
  const LND_MACAROON = Deno.env.get('LND_MACAROON')

  if (action === 'create_invoice') {
    // Appel au nœud LND pour créer une facture
    const response = await fetch(`${LND_HOST}/v1/invoices`, {
      method: 'POST',
      headers: {
        'Grpc-Metadata-macaroon': LND_MACAROON,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        value: amount_sats,
        memo: memo,
      }),
    })

    const data = await response.json()
    return new Response(JSON.stringify({
      bolt11: data.payment_request,
      payment_hash: data.r_hash,
    }), { headers: { "Content-Type": "application/json" } })
  }

  if (action === 'send_payment') {
    // Appel au nœud LND pour envoyer un paiement
    const response = await fetch(`${LND_HOST}/v1/channels/transactions`, {
      method: 'POST',
      headers: {
        'Grpc-Metadata-macaroon': LND_MACAROON,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        payment_request: invoice,
      }),
    })

    const data = await response.json()
    return new Response(JSON.stringify({
      success: true,
      preimage: data.payment_preimage,
    }), { headers: { "Content-Type": "application/json" } })
  }

  return new Response("Action non reconnue", { status: 400 })
})
```

#### Étape 4.2 : Déployer la fonction
Avec la CLI Supabase:
```bash
supabase functions deploy lnd-integration
```

Ou avec l'interface web Supabase:
- Copie le code dans une Edge Function nommée `lnd-integration`

---

### Phase 5 : Tester (1 jour)

#### Étape 5.1 : Tester avec Testnet
- Crée un compte utilisateur dans l'app
- Va sur "Recevoir" → clique "Générer facture"
  - Devrait appeler `lnd-integration` avec `action = create_invoice`
  - Devrait renvoyer un code QR avec une facture Lightning
- Va sur "Envoyer" → scanne la facture et envoie
  - Devrait appeler `lnd-integration` avec `action = send_payment`
  - Devrait afficher "Paiement réussi"

#### Étape 5.2 : Vérifier les logs
Va dans Supabase:
- Functions > Logs
- Vérifie que `lnd-integration` a reçu les appels
- Regarde les erreurs (probablement des problèmes de connexion LND)

#### Étape 5.3 : Déboguer les erreurs
Les erreurs courantes:
- `Connection refused` → ton nœud n'est pas accessible
- `Unauthorized` → macaroon invalide
- `Certificate error` → certificat TLS invalide

---

### Phase 6 : Passer à Mainnet (optionnel, risqué)

⚠️ **Ne fais ça QUE si Phase 5 fonctionne parfaitement**

1. Crée un nœud LND en mainnet
2. Ajoute des Bitcoins réels (petits montants au début)
3. Change les secrets Supabase
4. Teste avec très peu de Bitcoin
5. Augmente progressivement

---

## 📋 Checklist d'action

- [X] Comprendre l'architecture (Lire le guide ci-dessus)
- [ ] Avoir un nœud LND (Voltage.cloud testnet)
- [ ] Récupérer `LND_HOST`, `LND_MACAROON`, `LND_CERT`
- [ ] Ajouter les secrets dans Supabase
- [ ] Implémenter `lnd-integration/index.ts` correctement
- [ ] Déployer la fonction sur Supabase
- [ ] Tester "Recevoir" → génère facture Lightning
- [ ] Tester "Envoyer" → envoie paiement Lightning
- [ ] Vérifier les logs Supabase
- [ ] Déboguer les erreurs
- [ ] Tester avec mainnet (optionnel)

---

## 🆘 Aide-mémoire : Les 4 fichiers clés

### 1. Ce que Flutter appelle
📄 `lib/screens/send_payment_screen.dart`
```dart
await ref.read(supabaseServiceProvider).sendPayment(...)
```

### 2. Le service qui fait l'appel
📄 `lib/services/supabase_service.dart` ou `lib/providers/user_provider.dart`
- Contient la logique pour appeler Supabase

### 3. Le pont Supabase vers LND
📄 `supabase/functions/lnd-integration/index.ts`
- Reçoit les ordres de Flutter
- Appelle le nœud LND
- Renvoie les réponses

### 4. Le nœud qui fait le vrai travail
⚡ Ton nœud LND (sur un serveur externe)
- Crée les factures
- Envoie les paiements
- Stocke l'historique

---

## 💡 Points clés à retenir

1. **Les scripts TypeScript ne s'exécutent PAS sur ton PC**
   - Ils s'exécutent sur **les serveurs Supabase** (cloud)
   - Ils se déploient via la CLI ou l'interface web

2. **Tu dois avoir un nœud Lightning**
   - Gratuit en testnet (Voltage.cloud)
   - Coûte de l'argent en mainnet

3. **Le flux est**: Flutter → Supabase Edge Function → Nœud LND

4. **Les secrets (macaroon, cert) ne vont JAMAIS dans Flutter**
   - Ils vont dans les **Variables d'environnement Supabase**

5. **Tu peux tester sans argent réel** en utilisant testnet

---

## 📞 Si tu es bloqué

1. **Erreur `Connection refused`**
   - Vérifie que ton nœud LND est en ligne
   - Teste la connexion: `curl https://[LND_HOST]/v1/getinfo`

2. **Erreur `Unauthorized`**
   - Le macaroon est incorrect ou expiré
   - Régénère-le depuis ton nœud

3. **Erreur `Certificate error`**
   - Le certificat TLS est invalide
   - Obtiens un nouveau certificat du nœud

4. **Les appels n'arrivent pas à Supabase**
   - Regarde les logs Supabase (Functions > Logs)
   - Vérifie que la fonction est déployée correctement

---

## 🎓 Pour expliquer à la team

"On a une architecture en 3 couches:
1. **Flutter app** (le client)
2. **Supabase** (le serveur / le pont)
3. **Nœud Lightning** (le vrai Bitcoin)

Les scripts TypeScript (dans `supabase/functions/`) s'exécutent **sur les serveurs Supabase**, pas sur nos machines. Ils reçoivent les ordres de l'app Flutter et les envoient au nœud Lightning.

Ordre d'action:
1. Louer un nœud Lightning (Voltage.cloud testnet)
2. Configurer les secrets dans Supabase
3. Implémenter le code du pont (`lnd-integration`)
4. Tester d'abord en testnet
5. Puis passer à mainnet avec de petits montants"
