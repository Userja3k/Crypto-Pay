# TODO - Correction build Windows/Android

## Étape 1 — Analyse & compilation
- [x] Identifier les fichiers responsables des erreurs de compilation (listées dans le log).
- [ ] Vérifier/adapter les APIs incompatibles (flutter_blue_plus, nfc_manager, mobile_scanner, riverpod).

## Étape 2 — Corrections services
- [ ] Corriger `lib/services/bluetooth_service.dart` (types qualifiés `fbp.*`, imports, signatures).
- [ ] Corriger `lib/services/nfc_service.dart` (API compatible avec la version `nfc_manager` + imports manquants).
- [ ] Corriger `lib/services/payment_service.dart` (conflit import Bluetooth + cohérence `PaymentStatus`).

## Étape 3 — Corrections providers
- [ ] Corriger `lib/providers/payment_provider.dart` (erreurs `const`/factory, `PaymentStatus`).

## Étape 4 — Corrections UI/screens
- [ ] Corriger `lib/screens/qr_scanner_screen.dart` (suppression `await` dans le widget tree).
- [ ] Corriger `lib/screens/profile_screen.dart` (usage de `ref`).
- [ ] Corriger callback types dans `bluetooth_payment_screen.dart` + `nfc_payment_screen.dart` (Future<void> vs void).

## Étape 5 — Build & test
- [ ] `flutter clean` + `flutter pub get`
- [ ] `flutter run -d windows`
- [ ] `flutter run -d android`
- [ ] Rejouer `flutter analyze` si besoin

