# Valide — Application mobile

> Application EdTech mobile bilingue (FR/EN) pour les élèves du secondaire camerounais — préparation aux examens BEPC, Probatoire, BAC, GCE O/A-Level.

**Ce dépôt contient l'app mobile Flutter uniquement.** Le backend (Cloud Functions), la console admin et la landing page vivent dans des dépôts séparés.

---

## Démarrage rapide

1. Lis le [guide de contribution](doc/tools/CONTRIBUTING.md) avant tout — il décrit le workflow, les conventions, et l'onboarding.
2. Suis le setup pas à pas dans la section 15 du guide.
3. Lance l'app : `flutter run`.

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

🟡 **Phase de documentation** — le code mobile n'a pas encore démarré. Les spécifications produit, l'architecture et la surface partagée sont posées.

---

## Stack

| Domaine | Choix |
|---|---|
| Framework | Flutter (iOS + Android, base unique) |
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
