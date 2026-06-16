# 📋 Checklist Simple : Étapes Restantes

## ✅ Déjà fait (Phase 1-2 : Nettoyage UI et Supabase)
- [x] Supprimer les mock data
- [x] Créer les pages (profil, paiement, etc.)
- [x] Intégrer Supabase authentication
- [x] Créer les providers Riverpod
- [x] Interface "Liquid Glass"

---

## 🚀 À faire maintenant (Phase 3 : Lightning Network)

### Étape 1 : Infrastructure (1 jour)
- [ ] Créer un compte Voltage.cloud
- [ ] Créer un nœud Lightning **en testnet**
- [ ] Récupérer: `LND_HOST`, `LND_MACAROON`, `LND_CERT`
- [ ] Tester la connexion au nœud

### Étape 2 : Secrets Supabase (30 min)
- [ ] Aller sur Dashboard Supabase
- [ ] Settings > Secrets
- [ ] Ajouter `LND_HOST`
- [ ] Ajouter `LND_MACAROON`
- [ ] Ajouter `LND_CERT`

### Étape 3 : Implémenter le pont (2-3 jours)
- [ ] Remplir `supabase/functions/lnd-integration/index.ts`
- [ ] Implémenter `action: create_invoice` (créer facture)
- [ ] Implémenter `action: send_payment` (envoyer paiement)
- [ ] Gérer les erreurs
- [ ] Déployer sur Supabase

### Étape 4 : Tester (1 jour)
- [ ] Tester "Recevoir" → génère facture Lightning
- [ ] Scanner le code QR
- [ ] Tester "Envoyer" → envoie un paiement
- [ ] Vérifier les logs Supabase
- [ ] Déboguer les erreurs

### Étape 5 : Configurer le prix (1 jour)
- [ ] Implémenter `supabase/functions/price-oracle/index.ts`
- [ ] Programmer pour s'exécuter toutes les 10 minutes
- [ ] Vérifier que le prix se met à jour dans la base

### Étape 6 : KYC et Storage (1 jour)
- [ ] Créer un bucket Supabase `kyc-documents`
- [ ] Tester l'upload de fichiers
- [ ] Ajouter les règles de sécurité

### Étape 7 : Notifications (2 jours)
- [ ] Créer un projet Firebase
- [ ] Ajouter FCM à l'app Flutter
- [ ] Implémenter les notifications de réception de paiement

### Étape 8 : Passer à Mainnet (optionnel, risqué)
- [ ] ⚠️ Ne fais ça QUE si tout fonctionne en testnet
- [ ] Créer un nœud Lightning en mainnet
- [ ] Ajouter des Bitcoins réels (petits montants)
- [ ] Changer les secrets Supabase
- [ ] Tester avec peu de Bitcoin

---

## 📊 Estimé de temps

| Phase | Durée | Difficulté |
|-------|-------|-----------|
| 1-2 : Infrastructure + Secrets | 1-2 jours | Facile |
| 3 : Implémenter le pont | 2-3 jours | Moyen |
| 4 : Tester | 1 jour | Facile |
| 5 : Prix | 1 jour | Facile |
| 6 : KYC | 1 jour | Moyen |
| 7 : Notifications | 2 jours | Difficile |
| **Total** | **8-10 jours** | — |

---

## 🆘 Si tu es bloqué

Lis `GUIDE_COMPLET_LIGHTNING.md` pour des explications détaillées.

Les problèmes courants:
- **"Connection refused"** → le nœud LND n'est pas accessible
- **"Unauthorized"** → macaroon invalide
- **"No transactions showing"** → base de données pas correctement liée

---

## 💬 Pour la team meeting

"On a déployé l'UI et les maquettes. Maintenant on doit:
1. **Configurer** un nœud Lightning (2-3 jours)
2. **Implémenter** le pont Supabase vers Lightning (3-4 jours)
3. **Tester** en testnet avant mainnet (1-2 jours)

On commence par le testnet (gratuit, pas de vrai Bitcoin). Après on ira en mainnet avec de petits montants."
