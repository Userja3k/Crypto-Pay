# Architecture du projet Crypto-Pay

## Vue d'ensemble

Ce document décrit l'architecture complète de l'application mobile Crypto-Pay.

- Frontend : Flutter
- Gestion d'état : Riverpod
- Backend : Supabase (PostgreSQL + RPC)
- Thème : Liquid Glass
- Authentification : Passport Supabase + stockage local

---

## Diagramme d'architecture globale

```mermaid
flowchart TD
  subgraph AppMobile [Application Flutter]
    A[main.dart] --> B[ProviderScope]
    B --> C[AuthWrapper / SplashScreen]
    C --> D[Screens]
    D -->|appelle| E[Providers Riverpod]
    E -->|utilise| F[SupabaseService]
    F -->|RPC| G[Supabase PostgreSQL]
  end

  subgraph UI [Écrans]
    D1[Login / Register]
    D2[Home]
    D3[Send Payment]
    D4[Receive Payment]
    D5[Transaction History]
    D6[Profile / Settings]
    D7[KYC / Parental / Referral]
  end

  subgraph Backend [Supabase]
    G1[Tables SQL]
    G2[Functions RPC]
    G3[Row Level Security]
  end

  A --> D1
  A --> D2
  A --> D3
  A --> D4
  A --> D5
  A --> D6
  A --> D7

  F --> G1
  F --> G2
  G2 --> G1
  G1 --> G3
```
```

---

## Composants principaux

### Frontend Flutter

- `lib/main.dart`
  - Initialisation Supabase
  - Chargement du thème
  - Démarrage de l'application avec `ProviderScope`

- `lib/config.dart`
  - Variables de configuration Supabase via `--dart-define`

- `lib/core/theme.dart`
  - Thème sombre et design tokens
  - Typographie Google Fonts

- `lib/services/supabase_service.dart`
  - Interface entre Flutter et Supabase
  - Appels RPC exposés comme méthodes Dart

- `lib/providers/user_provider.dart`
  - Providers pour l'état utilisateur
  - Persistence avec `SharedPreferences`

- `lib/screens/`
  - Ecrans de l'application mobile
  - Navigation et UX

### Backend Supabase

- `supabase/migrations/20240601000000_initial_schema.sql`
  - Création du schema `cryptopay`
  - Définition des tables, types et fonctions RPC

- Tables clé :
  - `cryptopay.users`
  - `cryptopay.accounts`
  - `cryptopay.transactions`
  - `cryptopay.sessions`
  - `cryptopay.kyc_documents`
  - `cryptopay.referrals`
  - `cryptopay.notifications`

- Fonctions RPC clé :
  - `register_user`
  - `verify_login`
  - `get_user_salt`
  - `send_payment`
  - `create_lightning_invoice`
  - `get_balance`
  - `get_transaction_history`
  - `search_users`
  - `create_child_account`
  - `approve_child_transaction`
  - `submit_kyc_document`
  - `get_notifications`

- Sécurité : Row Level Security (RLS)
  - Politiques pour limiter l'accès aux données de l'utilisateur connecté

---

## Diagramme des relations de données

```mermaid
erDiagram
    USERS {
        UUID id PK
        VARCHAR email
        VARCHAR phone
        VARCHAR full_name
        DATE birth_date
        user_role_enum user_role
        UUID parent_id FK
        TEXT encrypted_pin_hash
        TEXT pin_salt
        kyc_level_enum kyc_level
        VARCHAR referral_code
        UUID referred_by FK
    }
    ACCOUNTS {
        UUID id PK
        UUID user_id FK
        DECIMAL balance_usd
        BIGINT balance_sats
        DECIMAL balance_cdf
    }
    TRANSACTIONS {
        UUID id PK
        UUID account_id FK
        transaction_type_enum transaction_type
        DECIMAL amount_usd
        DECIMAL fee_usd
        UUID counterparty_user_id FK
        UUID counterparty_account_id FK
        VARCHAR reference_number
        transaction_status_enum status
    }
    SESSIONS {
        UUID id PK
        UUID user_id FK
    }
    KYC_DOCUMENTS {
        UUID id PK
        UUID user_id FK
        VARCHAR document_type
        TEXT document_url
        VARCHAR status
    }
    REFERRALS {
        UUID id PK
        UUID referrer_user_id FK
        UUID referred_user_id FK
    }
    NOTIFICATIONS {
        UUID id PK
        UUID user_id FK
        VARCHAR title
        TEXT body
        BOOLEAN is_read
    }

    USERS ||--o{ ACCOUNTS : owns
    ACCOUNTS ||--o{ TRANSACTIONS : records
    USERS ||--o{ SESSIONS : has
    USERS ||--o{ KYC_DOCUMENTS : submits
    USERS ||--o{ REFERRALS : refers
    USERS ||--o{ NOTIFICATIONS : receives
```
```

---

## Flux utilisateur principal

### Inscription / connexion

1. L'utilisateur remplit le formulaire `register_screen`
2. `SupabaseService.registerUser()` appelle `register_user`
3. Le RPC crée l'utilisateur, le compte, et génère un code de parrainage
4. En cas de connexion, `verify_login` valide le PIN hash

### Paiement

1. L'utilisateur saisit un destinataire dans `send_payment_screen`
2. `SupabaseService.sendPayment()` appelle `send_payment`
3. Le RPC vérifie le solde, calcule les frais, et enregistre la transaction
4. Une notification peut être créée via `create_notification`

### KYC / parrainage / enfants

- `submit_kyc_document` gère l'envoi de documents
- `create_child_account` et `approve_child_transaction` gèrent les comptes enfants
- `claim_referral_bonus` gère le bonus de parrainage

---

## Résumé de l'architecture

- L'application est séparée en couches : UI, état, service, données.
- La logique métier critique est implémentée côté base de données via Supabase RPC.
- Les données sont sécurisées par RLS et la structure SQL.
- Riverpod pilote l'accès aux données et la synchronisation UI.

---

## Utilisation

- Ouvrir `ARCHITECTURE.md` pour la documentation architecturale.
- Render le diagramme Mermaid dans un visualiseur Markdown compatible.
- Mettre à jour les sections si tu ajoutes de nouveaux écrans ou RPC.
