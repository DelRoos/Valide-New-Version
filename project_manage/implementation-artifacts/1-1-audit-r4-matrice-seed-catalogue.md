---
story_id: 1.1
title: Audit R4 matrice MINESEC/GCE + seed catalogue local
epic: 1
phase: P1
status: ready-for-dev
created: 2026-06-05
branch: feature/1.1-audit-r4-matrice-seed-catalogue
estimation: S (~3-4h, plus temps d'attente si audit externe)
risk: R4 — matrice profil → matières/examens marquée 🟡 squelette à compléter en P1
dependencies: []
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.1
  - project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-2
  - doc/partage/DONNEES-REFERENCE.md (matrice à compléter et marquer 🟢)
  - doc/partage/BASE-DE-DONNEES.md § users (`derivedSubjects`, `examTargets`)
  - doc/partage/ALGORITHMES.md § 1 (Dérivation profil → matières + examens)
---

# Story 1.1 — Audit R4 matrice MINESEC/GCE + seed catalogue local

Status: **ready-for-dev**

## Objectif

Compléter la matrice **(sous-système, filière, niveau, série) → (matières, examens visés)** dans `doc/partage/DONNEES-REFERENCE.md` (passer de 🟡 à 🟢 pour le périmètre MVP), puis l'embarquer comme **seed JSON local** dans `mobile_app/assets/onboarding/catalogue_subjects.json` consommable au runtime via un helper pur `derive()`.

**Pourquoi** : la matrice 🟡 est risque **R4**. Stories 1.3 (flow profil 3 étapes) et 1.9 (dashboard filtré) en dépendent pour dériver les matières d'un élève sans Cloud Function backend. Sans cette story, on ne peut pas démarrer le code Epic 1.

**Critère de fin** : `derive('francophone','generale','Terminale','D')` → `[Maths, PCT, SVT, Français, Anglais, LV2, Philo, Hist-Géo, EPS] + [exam_bac_francophone_d]` et `derive('anglophone','generale','Upper Sixth','S2')` → `[Chemistry, Physics, Biology] + [exam_gce_a_level_anglophone_s2]`, vérifiés par tests automatisés.

## Story

**As a** product owner Valide,
**I want** la matrice profil → matières/examens validée par sources autoritaires + un seed catalogue local + un helper `derive()` testé,
**so that** Stories 1.3 et 1.9 puissent dériver les matières sans dépendre d'une Cloud Function backend, et que R4 soit retiré du registre des risques.

## Acceptance Criteria

### AC1 — Audit matrice exécuté et tracé (DONNEES-REFERENCE.md → 🟢)

**Given** la matrice 🟡 squelette de `doc/partage/DONNEES-REFERENCE.md`
**When** un audit est mené par sources publiques (MINESEC + Cameroon GCE Board, déjà listées en haut du doc § Sources autoritaires)
**Then** le tableau de dérivation § ligne 271 est complété pour le **périmètre MVP suggéré § ligne 312** :
- **Francophone général** : 6ᵉ → 3ᵉ + BEPC ; Seconde → Terminale séries **A, C, D** + Probatoire + BAC
- **Francophone technique** : Première + Terminale séries **F1, F2, F3, F4** + Probatoire + BAC ; **G1, G2, G3** + BAC
- **Anglophone** : Form 1 → Form 5 + O Level ; Lower Sixth + Upper Sixth **toutes séries S1-S8 et A1-A5**

**And** chaque série a sa liste exacte de matières documentée (suivre les sources MINESEC + GCE Board citées)
**And** la mention « 🟡 squelette à compléter » est remplacée par « 🟢 validé pour périmètre MVP » dans § « Tableau de dérivation »
**And** l'historique en bas du fichier reçoit une nouvelle entrée datée 2026-06-XX avec auteur + description

### AC2 — Seed JSON local créé et structuré

**Given** la matrice validée AC1
**When** on génère `mobile_app/assets/onboarding/catalogue_subjects.json`
**Then** le fichier respecte la structure suivante (clés racine) :

```json
{
  "version": "1.0.0",
  "generatedAt": "2026-06-XX",
  "filieres": [
    {"id": "generale", "name": {"fr": "Générale", "en": "General"}},
    {"id": "technique", "name": {"fr": "Technique", "en": "Technical"}}
  ],
  "niveaux": [
    {"id": "6e",            "subSystem": "francophone", "name": {"fr": "6ᵉ", "en": "6e"},            "filieres": ["generale"]},
    {"id": "form_1",        "subSystem": "anglophone",  "name": {"fr": "Form 1", "en": "Form 1"},   "filieres": ["generale"]},
    {"id": "upper_sixth",   "subSystem": "anglophone",  "name": {"fr": "Upper Sixth", "en": "Upper Sixth"}, "filieres": ["generale"]}
  ],
  "series": [
    {"id": "d", "subSystem": "francophone", "niveau": "terminale", "filiere": "generale", "name": {"fr": "D", "en": "D"}},
    {"id": "s2", "subSystem": "anglophone", "niveau": "upper_sixth", "filiere": "generale", "name": {"fr": "S2", "en": "S2"}}
  ],
  "subjects": [
    {"id": "francophone_math", "subSystem": "francophone", "name": {"fr": "Mathématiques", "en": "Mathematics"}, "icon": "function-square"},
    {"id": "anglophone_chemistry", "subSystem": "anglophone", "name": {"fr": "Chimie", "en": "Chemistry"}, "icon": "flask-conical"}
  ],
  "examTargets": [
    {"id": "exam_bac_francophone_d", "subSystem": "francophone", "name": {"fr": "BAC D", "en": "BAC D"}},
    {"id": "exam_gce_a_level_anglophone_s2", "subSystem": "anglophone", "name": {"fr": "GCE A Level (Sciences S2)", "en": "GCE A Level (Sciences S2)"}}
  ],
  "derivationRules": [
    {
      "match": {"subSystem": "francophone", "filiere": "generale", "niveau": "terminale", "serie": "d"},
      "subjects": ["francophone_math", "francophone_pct", "francophone_svt", "francophone_fr", "francophone_en", "francophone_lv2", "francophone_philo", "francophone_hg", "francophone_eps"],
      "examTargets": ["exam_bac_francophone_d"],
      "canOptOut": false
    }
  ]
}
```

**And** les conventions de nommage IDs respectent `DONNEES-REFERENCE.md` § « Convention de nommage » lignes 216-252 :
- `subjects`: `{subSystem}_{shortCode}` en snake_case (ex. `francophone_pct`, `anglophone_pure_maths`)
- `examTargets`: `exam_{niveau}_{subSystem}[_{serie}]` (ex. `exam_bepc_francophone`, `exam_bac_francophone_d`)
- `niveaux`/`series`: kebab-case (ex. `lower_sixth`, `terminale`, `s2`, `f1`)

**And** chaque `subject.icon` est un nom Lucide valide (pack `lucide_icons_flutter` ^3.1.14 déjà dans pubspec ligne 49) — utiliser <https://lucide.dev/icons/> pour vérifier

**And** le fichier inclut le périmètre MVP complet (cf. AC1 — pas de raccourcis pour MVP)

### AC3 — Seed déclaré dans pubspec et chargeable au runtime

**Given** `mobile_app/pubspec.yaml`
**When** on inspecte la section `flutter:` `assets:` lignes 120-128
**Then** une nouvelle entrée `- assets/onboarding/` est ajoutée
**And** la PR contient un test unitaire `mobile_app/test/core/onboarding_catalogue/catalogue_loader_test.dart` qui :
- Charge le JSON via `rootBundle.loadString('assets/onboarding/catalogue_subjects.json')`
- Parse en `Map<String, dynamic>`
- Vérifie présence des 8 exemples figés cités dans `DONNEES-REFERENCE.md` ligne 271 : `(francophone,generale,3e,—)`, `(francophone,generale,Première,C)`, `(francophone,generale,Terminale,D)`, `(francophone,technique,Terminale,F1)`, `(francophone,technique,Terminale,G2)`, `(anglophone,generale,Form 5,—)`, `(anglophone,generale,Upper Sixth,S2)`, `(anglophone,generale,Upper Sixth,A3)`
- Vérifie `version == "1.0.0"`

**And** `flutter test test/core/onboarding_catalogue/` passe sans erreur

### AC4 — Helper `derive()` + tests cas PRD

**Given** le seed chargé et un helper `OnboardingCatalogue` instancié
**When** on appelle `catalogue.derive(subSystem: 'francophone', filiere: 'generale', niveau: 'terminale', serie: 'd')`
**Then** la sortie est `Right(DerivedProfile(subjects: [9 ids dont francophone_math, francophone_pct, francophone_svt, francophone_fr, francophone_en, francophone_lv2, francophone_philo, francophone_hg, francophone_eps], examTargets: ['exam_bac_francophone_d'], canOptOut: false))`

**When** on appelle `catalogue.derive(subSystem: 'anglophone', filiere: 'generale', niveau: 'upper_sixth', serie: 's2')`
**Then** la sortie est `Right(DerivedProfile(subjects: ['anglophone_chemistry', 'anglophone_physics', 'anglophone_biology'], examTargets: ['exam_gce_a_level_anglophone_s2'], canOptOut: true))`

**When** on appelle `catalogue.derive(subSystem: 'francophone', filiere: 'generale', niveau: 'terminale', serie: 'inexistante')`
**Then** la sortie est `Left(CatalogueFailure.noMatchingRule(...))`

**And** ces 3 cas sont des tests automatisés dans `mobile_app/test/core/onboarding_catalogue/catalogue_derivation_test.dart`
**And** `flutter test` (tous tests projet) reste vert

### AC5 — `flutter analyze` 0 issue + DoD

**Given** la PR Story 1.1
**When** on exécute `flutter analyze`
**Then** 0 issue est retourné
**And** la PR fait ≤ 600 lignes diff hors JSON seed (le JSON peut être volumineux mais c'est de la data — 1500 lignes JSON acceptable)

## Tasks / Subtasks

- [ ] **T1 — Audit matrice par sources publiques (AC1)**
  - [ ] T1.1 — Consulter MINESEC francophone : <https://www.minesec.gov.cm/web/index.php/fr/systeme-educatif/offre-de-formation/sous-systeme-francophone>
  - [ ] T1.2 — Consulter MINESEC anglophone + GCE Board : <https://camgceb.org/> pour O Level et A Level subjects
  - [ ] T1.3 — Consulter Office du Baccalauréat pour BAC technique : <https://officedubac.cm/nomenclature-des-examens/>
  - [ ] T1.4 — Compléter le § « Tableau de dérivation » de `doc/partage/DONNEES-REFERENCE.md` pour le périmètre MVP
  - [ ] T1.5 — Remplacer 🟡 par 🟢 dans le § Tableau de dérivation et le statut global du document
  - [ ] T1.6 — Ajouter une ligne datée 2026-06-XX dans § Historique avec description « R4 — Matrice MVP complétée et validée par sources MINESEC + GCE Board (audit story 1.1) »

- [ ] **T2 — Créer seed JSON (AC2)**
  - [ ] T2.1 — Créer `mobile_app/assets/onboarding/catalogue_subjects.json` avec structure documentée AC2
  - [ ] T2.2 — Renseigner `filieres`, `niveaux`, `series` selon DONNEES-REFERENCE.md (périmètre MVP)
  - [ ] T2.3 — Renseigner `subjects` avec id snake_case + bilingue + icon Lucide vérifié sur <https://lucide.dev/icons/>
  - [ ] T2.4 — Renseigner `examTargets` selon convention `exam_{niveau}_{subSystem}[_{serie}]`
  - [ ] T2.5 — Renseigner `derivationRules` couvrant le périmètre MVP (chaque rule a `match`, `subjects[]`, `examTargets[]`, `canOptOut`)
  - [ ] T2.6 — Vérifier les 8 cas figés du § « Tableau de dérivation » présents (audit interne)
  - [ ] T2.7 — Valider JSON syntaxique avec `python -m json.tool` ou équivalent

- [ ] **T3 — Déclarer asset dans pubspec (AC3)**
  - [ ] T3.1 — Ajouter `- assets/onboarding/` dans `mobile_app/pubspec.yaml` section `flutter: assets:` après les autres assets existants (audio/, dev/, sentinel/)
  - [ ] T3.2 — Exécuter `flutter pub get` dans `mobile_app/`
  - [ ] T3.3 — Vérifier que `mobile_app/.dart_tool/flutter_build/.dart_tool/flutter_gen/` régénère bien (pas d'action manuelle, automatique au prochain build)

- [ ] **T4 — Helper `derive()` + modèles (AC4)**
  - [ ] T4.1 — Créer `mobile_app/lib/core/onboarding_catalogue/onboarding_catalogue.dart` avec modèles immutables (utiliser `equatable: ^2.0.8` déjà au pubspec ligne 47) : `Subject`, `ExamTarget`, `DerivationRule`, `DerivedProfile`
  - [ ] T4.2 — Implémenter `class OnboardingCatalogue { static Future<OnboardingCatalogue> load({AssetBundle? bundle}) async {...} }` qui lit `assets/onboarding/catalogue_subjects.json` via `rootBundle.loadString` (ou bundle injecté pour tests)
  - [ ] T4.3 — Implémenter `Either<CatalogueFailure, DerivedProfile> derive({required String subSystem, required String filiere, required String niveau, required String serie})` qui matche la première rule `derivationRules` dont `match` correspond
  - [ ] T4.4 — Définir `class CatalogueFailure extends Failure` avec sous-classe `.noMatchingRule(profile)` — utiliser le pattern Either<Failure, T> de Story 0.4 (`lib/core/error/failures.dart`)
  - [ ] T4.5 — Aucune dépendance Flutter dans le fichier modèle (sauf `rootBundle` pour le loader — acceptable car ce fichier est core mais non-domain)

- [ ] **T5 — Tests (AC3 + AC4)**
  - [ ] T5.1 — Créer `mobile_app/test/core/onboarding_catalogue/catalogue_loader_test.dart` :
    - 1 test : `loads catalogue from rootBundle without error`
    - 1 test : `version is "1.0.0"`
    - 1 test : `contains 8 canonical derivation cases from DONNEES-REFERENCE.md` (assert chaque cas trouve une rule)
  - [ ] T5.2 — Créer `mobile_app/test/core/onboarding_catalogue/catalogue_derivation_test.dart` :
    - Test 1 : « Fatou Tle D francophone → 9 matières + BAC D »
    - Test 2 : « James Upper Sixth S2 anglophone → Chemistry/Physics/Biology + GCE A Level S2 »
    - Test 3 : « série inexistante → Left(CatalogueFailure.noMatchingRule) »
  - [ ] T5.3 — Lancer `flutter test test/core/onboarding_catalogue/` localement → vert
  - [ ] T5.4 — Lancer `flutter test` global → vert (pas de régression sur les 9 tests Story 0.21)

- [ ] **T6 — Documentation et finalisation (AC5)**
  - [ ] T6.1 — `cd mobile_app && flutter analyze` → 0 issue
  - [ ] T6.2 — `cd mobile_app && flutter test` → tous verts (existants + 6 nouveaux ≥ 15/15)
  - [ ] T6.3 — Vérifier PR ≤ 600 lignes diff hors JSON
  - [ ] T6.4 — Commit `docs(partage): valider matrice MINESEC/GCE R4 + seed catalogue local`
  - [ ] T6.5 — Mettre à jour `project_manage/implementation-artifacts/sprint-status.yaml` : `1-1-audit-r4-matrice-seed-catalogue: done`

## Dev Notes

### Architecture compliance (ADR-001 clean arch)

- **`lib/core/onboarding_catalogue/`** : namespace `core` (transversal neutre) car consommé par `features/onboarding/` (Story 1.3) **et** `features/home/` (Story 1.9 pour filtrage). Pas un feature folder.
- **Pure helper** : `derive()` est une fonction **pure** (entrée → sortie, pas d'effet de bord). Tests faciles, déterministes.
- **Pas de Firebase, pas de Dio** : Story 1.1 ne touche AUCUN backend. C'est de la data locale embarquée.
- **Either<Failure, T>** : `derive()` retourne `Either<CatalogueFailure, DerivedProfile>` per NFR-7 (aucune exception ne remonte à l'UI). Réutiliser `Failure` de Story 0.4 (`lib/core/error/failures.dart`).
- **Modèles immutables** : utiliser `equatable` (déjà pubspec) pour `==` et `hashCode`. Pas de `freezed` (non au pubspec, ne pas ajouter).
- **AppLogger** : pas d'usage attendu ici (data pure, pas de side effects ni réseau). Si `load()` échoue (JSON malformé), throw `StateError` (tests doivent passer donc JSON est correct par construction).

### Pattern réutilisable des stories précédentes (Story 0.21 + 0.19.2)

- **assets/sentinel/** Story 0.21 a embarqué du markdown via `rootBundle.loadString`. Même pattern ici pour JSON :

```dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle, AssetBundle;

class OnboardingCatalogue {
  final Map<String, dynamic> _raw;
  OnboardingCatalogue._(this._raw);

  static Future<OnboardingCatalogue> load({AssetBundle? bundle}) async {
    final source = await (bundle ?? rootBundle)
        .loadString('assets/onboarding/catalogue_subjects.json');
    return OnboardingCatalogue._(jsonDecode(source) as Map<String, dynamic>);
  }
  // ...
}
```

- **Tests** : utiliser `setUp` pour charger le catalogue une fois par groupe, pas par test (perf).
- **Assets non Markdown** : pas besoin de gpt_markdown ici. JSON pur.

### Conventions IDs (DONNEES-REFERENCE.md lignes 216-252)

- `subjects` : `{subSystem}_{shortCode}` snake_case. Exemples valides : `francophone_math`, `francophone_pct`, `francophone_svt`, `francophone_fr`, `francophone_en`, `francophone_lv2`, `francophone_philo`, `francophone_hg`, `francophone_eps`, `anglophone_pure_maths`, `anglophone_further_maths`, `anglophone_english_lit`, `anglophone_french`, `anglophone_geo`, `anglophone_chemistry`, `anglophone_physics`, `anglophone_biology`.
- `examTargets` : `exam_{niveau}_{subSystem}[_{serie}]`. Exemples : `exam_bepc_francophone`, `exam_probatoire_francophone_c`, `exam_bac_francophone_d`, `exam_bac_technique_f1`, `exam_gce_o_level_anglophone`, `exam_gce_a_level_anglophone_s2`, `exam_gce_a_level_anglophone_a3`.
- `niveaux` / `series` : kebab-case avec préfixe pour disambiguation. Exemples : `6e`, `5e`, `4e`, `3e`, `seconde`, `premiere`, `terminale`, `form_1`, `form_5`, `lower_sixth`, `upper_sixth`, `a`, `c`, `d`, `e`, `f1`, `g2`, `s1`...`s8`, `a1`...`a5`.

### File List (à créer)

| Fichier | Type | LOC estimé |
|---|---|---|
| `doc/partage/DONNEES-REFERENCE.md` | UPDATE | +50 (compléter matrice + 🟢) |
| `mobile_app/assets/onboarding/catalogue_subjects.json` | NEW | ~800-1200 (data, n'entre pas dans le compteur PR) |
| `mobile_app/lib/core/onboarding_catalogue/onboarding_catalogue.dart` | NEW | ~150 (modèles + loader + derive) |
| `mobile_app/test/core/onboarding_catalogue/catalogue_loader_test.dart` | NEW | ~50 |
| `mobile_app/test/core/onboarding_catalogue/catalogue_derivation_test.dart` | NEW | ~60 |
| `mobile_app/pubspec.yaml` | UPDATE | +1 (ajouter `- assets/onboarding/`) |

**Total PR diff hors JSON** : ~310 lignes — sous le seuil 400 lignes (CLAUDE.md règle Git #3) et sous AC5 600 lignes.

### Project Structure Notes

- **Alignement** : `lib/core/onboarding_catalogue/` est cohérent avec `lib/core/error/`, `lib/core/firebase/`, `lib/core/logging/` existants (un dossier par responsabilité transversale).
- **Conflit potentiel** : aucun. Pas d'autre code dans `lib/features/onboarding/` (Story 1.3 le créera).
- **Tests location** : miroir du `lib/` dans `test/` : `test/core/onboarding_catalogue/`. Convention déjà appliquée Story 0.4 (`test/core/error/`) et Story 0.21 (`test/widget_test.dart` à la racine pour widget).

### Previous Story Intelligence (Story 0.21 — Sentinelle E0)

**Patterns établis** :
- Markdown chargé depuis `assets/sentinel/` via `rootBundle.loadString` → pattern identique pour JSON catalogue
- Tests responsive via `tester.binding.setSurfaceSize(...)` → pas applicable ici (pas de widget)
- `flutter analyze` doit retourner 0 issue (Story 0.21 a maintenu cette discipline)
- Commit conventional commit FR à l'impératif (cf. CLAUDE.md)

**Pièges à éviter** :
- L10n + caractères spéciaux : Story 0.21 a découvert que `gen-l10n` parse `$$` et `{}` comme placeholders ICU → markdown sorti des arb files. **Pas applicable ici** (on est dans assets/, pas arb), mais éviter d'inclure des caractères qui pourraient casser un parsing JSON (échapper `"` et `\\` dans les noms).
- MIUI Redmi A7 Pro bloque ADB installs → pas d'impact Story 1.1 (pas de build device).
- Mermaid SVG vs PNG (Story 0.19.2) → pas applicable ici.

### Recent commits intelligence (5 derniers)

```
e1c5700 docs(planning): décomposer Epic 1 onboarding en 10 stories     (Epic 1 décomposition)
0a94708 docs(core): cloture Epic 0 + statut deferred 4 stories         (Epic 0 closed)
e887951 Merge pull request #26 from DelRoos/feature/0.21-...           (Story 0.21 sentinelle E0)
d67ccec feat(app): page Hello Valide bilingue responsive sentinelle E0 (Story 0.21 commit)
4b6b62d Merge pull request #25 from DelRoos/feature/0.19.2-...         (Story 0.19.2 styling)
```

**Insights pour Story 1.1** :
- L'Epic 1 vient juste d'être décomposé → contexte frais, suivre la décomposition à la lettre (cf. epic-1-onboarding.md § Story 1.1 lignes 70-141).
- Epic 0 est clos avec 4 stories deferred (0.4bis-iOS, 0.8 App Check, 0.17 CI, 0.20 R3 latence) — pas d'impact Story 1.1.
- Pas de PR en cours hors 1.1.

### Library / framework requirements

**Aucune nouvelle dépendance à ajouter au pubspec** :
- `dart:convert` (stdlib) pour `jsonDecode`
- `flutter/services.dart` `rootBundle` (déjà utilisé Story 0.21)
- `equatable: ^2.0.8` (déjà pubspec ligne 47) pour modèles `==`/`hashCode`
- `fpdart: ^1.2.0` (déjà pubspec ligne 46) pour `Either<Failure, T>`
- `flutter_test` (dev_dependency) pour les tests

**SDK constraints** :
- Dart `^3.11.5` (pubspec ligne 22) → supporte sealed classes et pattern matching (utiles pour `CatalogueFailure` sous-classes)

### Testing requirements

- **Framework** : `flutter_test` (dev_dependency, déjà en place)
- **Pattern** : `testWidgets` non requis (pas de widget). Utiliser `test()` de package:test (transitive via flutter_test).
- **Asset bundle dans tests** : utiliser `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger` + override `AssetBundle`, OU plus simple : injecter un `AssetBundle` mockée dans `OnboardingCatalogue.load({AssetBundle? bundle})`.
- **Pattern de mock simple** :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

class _FakeBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final file = File('assets/onboarding/catalogue_subjects.json');
    return ByteData.view(Uint8List.fromList(await file.readAsBytes()).buffer);
  }
}
```

  → alternative plus simple : utiliser `rootBundle` directement dans les tests Flutter (fonctionne en `flutter test` car le bundle est auto-disponible quand l'asset est déclaré dans pubspec).

- **Coverage attendue** : 6 tests passent (3 loader + 3 derive). Pas d'objectif % coverage formel V1.

## References

- [Source: project_manage/planning-artifacts/epics/epic-1-onboarding.md § Story 1.1 lignes 70-141] — Décomposition complète + AC + DoD original
- [Source: project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md § FR-2 lignes 122-132] — Consequences testable : Tle D et Upper Sixth S2 exemples figés
- [Source: project_manage/planning-artifacts/architecture/adrs/ADR-001-flutter-clean-architecture.md] — Règle d'or `presentation → domain ← data` ; `core/` neutre
- [Source: project_manage/planning-artifacts/architecture/adrs/ADR-006-subsystem-fixed-at-signup.md] — `subSystem` immutable, dérive `language`
- [Source: doc/partage/DONNEES-REFERENCE.md § Tableau de dérivation ligne 271, § Périmètre MVP ligne 312, § Conventions IDs lignes 216-252]
- [Source: doc/partage/BASE-DE-DONNEES.md § users lignes 56-75] — Schéma `UserDoc.derivedSubjects[]` et `examTargets[]`
- [Source: doc/partage/ALGORITHMES.md § 1 lignes 39-77] — Algorithme dérivation côté Cloud Function (Story 1.1 livre la version locale équivalente)
- [Source: CLAUDE.md § Architecture mobile, § Sécurité, § Workflow Git, § Code & qualité] — Règles non négociables
- [Source: mobile_app/pubspec.yaml] — Inventaire dépendances actuel

## Definition of Done

- [ ] `doc/partage/DONNEES-REFERENCE.md` matrice MVP complète et marquée 🟢 § Tableau de dérivation
- [ ] `doc/partage/DONNEES-REFERENCE.md` § Historique : ligne 2026-06-XX ajoutée
- [ ] `mobile_app/assets/onboarding/catalogue_subjects.json` créé + JSON valide + version « 1.0.0 »
- [ ] `mobile_app/pubspec.yaml` : `- assets/onboarding/` ajouté
- [ ] `mobile_app/lib/core/onboarding_catalogue/onboarding_catalogue.dart` créé avec modèles + loader + `derive()`
- [ ] 6 tests verts dans `mobile_app/test/core/onboarding_catalogue/` (3 loader + 3 derive)
- [ ] `flutter analyze` 0 issue
- [ ] `flutter test` tous verts (existants + 6 nouveaux)
- [ ] PR ≤ 400 lignes diff hors JSON (AC5 600 max)
- [ ] Commit conventional `docs(partage): valider matrice MINESEC/GCE R4 + seed catalogue local`
- [ ] `sprint-status.yaml` : `1-1-audit-r4-matrice-seed-catalogue: done`

## Notes pour Amelia (dev agent)

### Anti-patterns à éviter (LLM disaster prevention)

- ❌ **NE PAS** coder la dérivation en branches `if/else` Dart en mode « if filiere == 'generale' && niveau == 'Terminale' && serie == 'D' ». **Utiliser exclusivement la lookup table `derivationRules` du JSON consommée par `derive()`**.
- ❌ **NE PAS** créer un fichier `features/onboarding/...` — c'est Story 1.3. Story 1.1 reste dans `core/`.
- ❌ **NE PAS** ajouter de dépendance pubspec (pas de `freezed`, pas de `json_serializable`, pas de `dartz`). On a déjà `equatable` + `fpdart` + `dart:convert`.
- ❌ **NE PAS** parser le JSON en `.then(...)` au boot de l'app. C'est lazy : `OnboardingCatalogue.load()` est appelé par `Story 1.3` quand le profil flow démarre.
- ❌ **NE PAS** logger le contenu complet du JSON en debug — c'est ~1000 lignes. Si besoin de debug, log juste `version` et nombre de rules.
- ❌ **NE PAS** modifier `lib/main.dart` pour cette story (pas de lazy-load ici, pas de provider Riverpod global du catalogue — Story 1.3 le fera).
- ❌ **NE PAS** étendre les règles Firestore. Story 1.1 ne touche pas Firestore.
- ❌ **NE PAS** committer le JSON avec timestamps inconsistants — utiliser `generatedAt: "2026-06-XX"` cohérent avec la date du commit.

### Patterns à suivre (best practice projet)

- ✅ **Identifiers en anglais, doc et commentaires en français** (CLAUDE.md § Workflow Git).
- ✅ **Conventional commits** : `docs(partage): valider matrice MINESEC/GCE R4 + seed catalogue local` (le commit touche un doc/partage donc scope `partage` per CLAUDE.md).
- ✅ **Either<Failure, T>** pour toute fonction qui peut échouer (NFR-7).
- ✅ **Pas de magic numbers** : utiliser des constantes nommées si besoin (`_kCatalogueVersion = '1.0.0'`).
- ✅ **Tests verts avant commit** : `flutter analyze` + `flutter test`.
- ✅ **PR ≤ 400 lignes diff** hors JSON data (CLAUDE.md règle).

### Décisions techniques figées (ne pas re-discuter)

- **Seed local vs Firestore** : seed local décidé en story planning (epic-1-onboarding.md § Story 1.1 lignes 86-88). Backend Firestore viendra post-MVP.
- **`derive()` côté client** : décidé en story planning (epic § lignes 84-88). La Cloud Function backend de ALGORITHMES.md § 1 est out of scope mobile V1.
- **Périmètre MVP** : décidé en DONNEES-REFERENCE.md § « Périmètre MVP suggéré » ligne 312. Ne pas étendre, ne pas restreindre.
- **Format JSON imposé** : structure exacte définie en AC2 (n'inventer aucune clé, ne pas changer les noms).
- **Bilinguisme** : `name.fr` et `name.en` pour TOUS les objets (filiere, niveau, serie, subject, examTarget). Pas de fallback.
- **Icônes Lucide** : pack `lucide_icons_flutter ^3.1.14` déjà au pubspec. Vérifier chaque icône sur <https://lucide.dev/icons/>. Si une icône manque pour une matière, utiliser un fallback générique (ex. `book-open`).

### Cas tests obligatoires (Definition of Acceptance)

Ces 8 cas du § Tableau de dérivation DONNEES-REFERENCE.md ligne 271 **DOIVENT** trouver une rule matchante dans le JSON (vérification par test) :

| sous-sys | filière | niveau | série | examens visés |
|---|---|---|---|---|
| francophone | generale | 3e | — | exam_bepc_francophone |
| francophone | generale | premiere | c | exam_probatoire_francophone_c |
| francophone | generale | terminale | d | exam_bac_francophone_d |
| francophone | technique | terminale | f1 | exam_bac_technique_f1 |
| francophone | technique | terminale | g2 | exam_bac_technique_g2 |
| anglophone | generale | form_5 | — | exam_gce_o_level_anglophone |
| anglophone | generale | upper_sixth | s2 | exam_gce_a_level_anglophone_s2 |
| anglophone | generale | upper_sixth | a3 | exam_gce_a_level_anglophone_a3 |

Pour les niveaux sans série (3ᵉ, Form 5), utiliser `serie: '-'` ou `serie: null` dans les `derivationRules.match` — choisir une convention et la documenter dans le header du JSON.

### Workflow git

1. Branche : `feature/1.1-audit-r4-matrice-seed-catalogue` (déjà créée si tu lances `/bmad-dev-story` depuis cette story)
2. Commits intermédiaires OK (squash final au merge)
3. PR ciblant `main` (pas d'autre branche cible)
4. Pas de `--no-verify` (CLAUDE.md interdiction)
5. Co-Authored-By Claude Opus 4.7 dans le commit

### Si Amelia a un doute

- Sur la matrice (matières d'une série) : **consulter sources MINESEC + GCE Board citées dans DONNEES-REFERENCE.md § Sources autoritaires**. Si encore incertain, marquer la série 🟡 dans le commentaire JSON et le signaler dans la PR.
- Sur la structure JSON : **suivre AC2 à la lettre**. Pas d'innovation.
- Sur la convention IDs : **DONNEES-REFERENCE.md lignes 216-252**. Pas d'invention.
- Sur le placement de fichier : `lib/core/onboarding_catalogue/` confirmé § Dev Notes.

### Si Amelia veut aller plus vite (optimisations autorisées)

- ✅ Utiliser `String.toLowerCase()` dans `derive()` pour matching case-insensitive (tolérant aux variations).
- ✅ Memoization du parsing JSON (charger une seule fois par instance `OnboardingCatalogue`).
- ✅ Lazy parsing : on peut différer le parsing des `subjects` et `examTargets` jusqu'au premier `derive()` si le JSON est volumineux.

### Questions ouvertes à signaler dans la PR (pas bloquantes)

- 🟡 **Série E francophone** : marquée 🔴 dans DONNEES-REFERENCE.md ligne 82 (« présence dans certains lycées techniques, à confirmer »). Décision : couvrir A/C/D dans le périmètre MVP par défaut, E uniquement si trouvée dans MINESEC. Sinon documenter le report en V2.
- 🟡 **Sections optionnelles A Level** : « optionnelles transversales » ligne 201 (Computer Science, ICT, Religious Studies, Commerce). Décision : les inclure comme matières mais sans les rendre obligatoires dans les rules (elles enrichissent mais ne définissent pas la série).
- 🟡 **Format `name.fr` pour Mathematics anglophone** : « Mathematics » est le terme anglais, en français on dit « Mathématiques ». Décision : `name.fr` pour anglophone reflète le nom officiel anglophone (« Mathematics ») car l'élève anglophone voit l'app en EN. Le `name.fr` est utile pour l'admin / le moteur de recherche, pas pour le rendu mobile.

## Dev Agent Record

### Agent Model Used

(à remplir lors de l'implémentation)

### Debug Log References

(à remplir lors de l'implémentation)

### Completion Notes List

(à remplir lors de l'implémentation)

### File List

(à remplir lors de l'implémentation)

---

**Ultimate context engine analysis completed — comprehensive developer guide created.**

Cette story est `ready-for-dev`. Amelia (via `/bmad-dev-story`) a tout pour implémenter sans ambiguïté : architecture, structure de fichiers, conventions IDs, cas tests obligatoires, anti-patterns à éviter, sources autoritaires à consulter, exemples figés à respecter.
