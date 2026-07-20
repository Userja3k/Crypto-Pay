# TODO - Fix build Windows (Flutter)

## Problème observé
Erreur MSVC: `C1041: impossible d'ouvrir la base de données ... .pdb` pour `permission_handler_windows_plugin`.

## Correctifs possibles (ordre recommandé)
1. Forcer MSVC à utiliser `/FS` pour partager l'accès aux PDB.
2. Désactiver la compilation parallèle (réduire les chances de conflits PDB).
3. Nettoyer build (flutter clean + suppression build/windows).

## Commandes / actions
- Fermer tous les processus qui pourraient locker les PDB (antivirus/IDE).
- Lancer `flutter doctor -v` pour vérifier les toolchains.

## Notes
Cette erreur est un classique lorsque plusieurs `cl.exe` écrivent dans le même `.pdb`. Le fix le plus direct est `/FS`.

