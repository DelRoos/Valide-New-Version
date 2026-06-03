# Valide — Application mobile

> Application EdTech mobile bilingue (FR/EN) pour les élèves du secondaire camerounais — préparation aux examens BEPC, Probatoire, BAC, GCE O/A-Level.

**Ce dépôt contient l'app mobile Flutter uniquement.** Le backend (Cloud Functions), la console admin et la landing page vivent dans des dépôts séparés.

---

## Démarrage rapide

**Prérequis** : Flutter 3.41.x stable, Dart 3.11.x, Android SDK + un device/émulateur.

```bash
git clone https://github.com/DelRoos/Valide-New-Version.git valide
cd valide/mobile_app
flutter pub get
flutter run
```

> Toutes les commandes `flutter` se lancent depuis `mobile_app/`. La structure du dépôt est décrite dans [CLAUDE.md § Structure du dépôt](CLAUDE.md#structure-du-dépôt).

Lis ensuite le [guide de contribution](doc/tools/CONTRIBUTING.md) — workflow, conventions, revue.

---

## Où trouver quoi

| Tu cherches… | Va voir |
|---|---|
| Comment contribuer (workflow, conventions, revue) | [doc/tools/CONTRIBUTING.md](doc/tools/CONTRIBUTING.md) |
| La méthode de pilotage (BMAD v6.8.0) | [doc/tools/BMAD_METHOD_GUIDE.md](doc/tools/BMAD_METHOD_GUIDE.md) |
| Le périmètre du MVP en 6 phases | [doc/metier/Valide Decoupage MVP.md](doc/metier/Valide%20Decoupage%20MVP.md) |
| L'architecture de l'app mobile | [doc/tech/Valide School App Architecture.md](doc/tech/Valide%20School%20App%20Architecture.md) |
| Les packages Flutter utilisés | [doc/tech/Valide School Package Architecture.md](doc/tech/Valide%20School%20Package%20Architecture.md) |
| Le Design System | [doc/tech/Valide - Design System.html](doc/tech/Valide%20-%20Design%20System.html) |
| Les maquettes d'écrans par module | [doc/tech/Valide - Design.html](doc/tech/Valide%20-%20Design.html) |
| **La surface partagée avec backend / admin / landing** | **[doc/partage/](doc/partage/)** |

---

## Statut

🟢 **Phase de développement P0** — bootstrap Flutter en cours (Epic 0 Foundation). Voir [`project_manage/implementation-artifacts/sprint-status.yaml`](project_manage/implementation-artifacts/sprint-status.yaml) pour le suivi des stories.

---

## Stack

| Domaine | Choix |
|---|---|
| Framework | Flutter (Android V1 ; iOS post-MVP) |
| State | Riverpod |
| Navigation | go_router |
| Backend client | Firebase (Auth, Firestore, Storage, Functions, Messaging, Analytics, Crashlytics, Remote Config, App Check) |
| Réseau | dio |
| Contenu pédagogique | flutter_smooth_markdown (Markdown + LaTeX + Mermaid + streaming) |
| Logging | logger (wrappé dans `AppLogger`) |
| Tailles dynamiques | flutter_screenutil |

Détails complets : [Mobile Package Architecture](doc/tech/Valide%20School%20Package%20Architecture.md).

---

## Contraintes marché (non négociables)

- **Téléphones modestes** — perf et taille de l'app comptent
- **Data limitée et coûteuse** — compresser, ne rien recharger inutilement
- **Connectivité instable** — retry, cache, robustesse réseau
