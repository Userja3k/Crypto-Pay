# Crypto-Pay - Documentation Technique

## Architecture

Le projet est basé sur une architecture moderne utilisant :
- **Frontend** : Flutter avec Riverpod pour la gestion d'état et le design system "Liquid Glass".
- **Backend** : Supabase pour l'authentification et la base de données.
- **Logique Métier** : 100% basée sur des procédures stockées PostgreSQL (RPC) pour garantir sécurité et performance.

## Installation

1.  **Supabase** :
    - Créez un projet sur Supabase.
    - Exécutez le script SQL situé dans `supabase/migrations/20240601000000_initial_schema.sql` dans l'éditeur SQL de votre dashboard Supabase.
2.  **Flutter** :
    - Mettez à jour les placeholders `url` et `anonKey` dans `lib/main.dart` avec vos identifiants Supabase.
    - Lancez `flutter pub get`.
    - Lancez l'application avec `flutter run`.

## Sécurité

- Les PIN utilisateurs sont hashés en SHA-256 côté client avant d'être envoyés au backend.
- La sécurité des données est assurée par des politiques Row Level Security (RLS) sur PostgreSQL.

## Fonctionnalités Implémentées (MVP)

- [x] Inscription et Connexion (RPC).
- [x] Affichage du solde en temps réel.
- [x] Recherche universelle d'utilisateurs.
- [x] Envoi de paiements internes (Instantané et gratuit).
- [x] Interface "Liquid Glass" premium.
- [x] Structure pour la gestion KYC, Famille et Parrainage.
