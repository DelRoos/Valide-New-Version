---
story_id: 1.13
title: DerivedProfile v2 + PickerMode extension + refactor catalogue snapshots -> get (audit règle 10.g)
epic: 1
phase: P1 extension v2 (sprint change 2026-06-09)
status: ready-for-dev
created: 2026-06-09
baseline_commit: 162497c  # merge PR #69 (CLAUDE.md règle 10 + BASE-DE-DONNEES.md update rules)
estimation: M (~5-7h) — S originale 3h + 2-4h refactor catalogue dette technique audit règle 10.g
sprint_change: sprint-change-proposal-2026-06-09.md + audit règle 10 BASE-DE-DONNEES.md 2026-06-09
dependencies:
  - 1.1a — done (schema v1 + 6 collections)
  - 1.1c — done (CatalogueRepository mobile en place — sera étendu)
  - 1.11a — done (contrat schema v2 figé : 6 nouveaux champs Firestore + ADR-016)
  - 1.12 — done (matrice.json v2 + reseed valide-edu, 369 docs avec pickerMode + obligatorySubjectIds + minSubjects/maxSubjects présents sur Firestore)
blocks:
  - 1.14 — sous-séries Tle franco SerieChoicePage (a besoin du modèle Serie enrichi pour grouper par famille)
  - 1.15 — refactor SubjectsOptOutPage → SubjectsPickerPage polymorphe (a besoin du DerivedProfile.pickerMode pour switcher entre les 5 modes)
  - 1.16 — A-Level transversales (a besoin du DerivedProfile.optionalSubjects + maxSubjects)
  - 1.17 — TVEE Eyong ELET (a besoin du DerivedProfile.pickerMode='tve_picker' + professionalSubjectIds via Serie)
sourceArtifacts:
  - project_manage/implementation-artifacts/1-11a-audit-matrice-v2-adr016.md § AC2 + AC4 (contrat schema v2 + ALGORITHMES amendé)
  - project_manage/planning-artifacts/architecture/adrs/ADR-016-catalogue-v2-sous-series-panier-tvee.md § Décisions 3 + 4
  - doc/partage/BASE-DE-DONNEES.md § Catalogue scolaire v2 (SerieDoc, DerivationRuleDoc, PickerMode enum 5 valeurs) + § Règles d'optimisation lecture/écriture (audit 2026-06-09 non-conformité 10.g)
  - doc/partage/ALGORITHMES.md § 1 (algo derive v2 enrichi + Modes panier table 5 modes)
  - CLAUDE.md § Architecture mobile règle 10 (modélisation Firestore optimisée — lecture, latence, coût)
  - mobile_app/lib/core/catalogue/domain/models.dart (Serie + DerivationRule + DerivedProfile à étendre, ~313 lignes)
  - mobile_app/lib/core/catalogue/domain/catalogue_repository.dart (interface à amender — watchXxx → fetchXxx)
  - mobile_app/lib/core/catalogue/data/catalogue_repository_firestore_impl.dart (impl à étendre + refactor snapshots → get, ~253 lignes)
  - mobile_app/lib/core/catalogue/data/firestore_mappers.dart (à étendre pour lire les 6+2 nouveaux champs, ~130 lignes)
  - mobile_app/lib/core/catalogue/providers.dart (catalogueProvider StreamProvider → FutureProvider)
  - mobile_app/lib/features/onboarding/providers.dart (derivedProfileProvider consomme derive() — pas de changement attendu)
  - mobile_app/test/core/catalogue/ (5+ tests existants à adapter : models, mappers, repository, providers, widget)
action_porteur_post_merge: aucune (purement mobile + tests)
---

# Story 1.13 — `DerivedProfile` v2 + `PickerMode` extension + refactor catalogue snapshots → get

Status: **ready-for-dev**

## Objectif

Étendre les modèles domain `Serie`, `DerivationRule` et `DerivedProfile` côté mobile pour exposer les champs v2 figés par Story 1.11a (et déjà seedés sur `valide-edu` par Story 1.12). Refactor en parallèle le pattern de lecture du catalogue de `.snapshots()` vers `.get()` pour respecter la **règle 10.g de CLAUDE.md** (dette technique identifiée par l'audit 2026-06-09 dans `BASE-DE-DONNEES.md`).

**2 axes complémentaires dans la même PR** :

1. **Schema v2 mobile (non-breaking)** :
   - `Serie` : +6 champs nullable (`pickerMode`, `minSubjects`, `maxSubjects`, `professionalSubjectIds`, `relatedProfessionalSubjectIds`, `otherSubjectIds`)
   - `DerivationRule` : +2 champs nullable (`obligatorySubjectIds`, `optionalSubjectIds`)
   - `DerivedProfile` : +5 champs (`pickerMode` non-null avec default `derived`, `obligatorySubjects`, `optionalSubjects`, `minSubjects?`, `maxSubjects?`)
   - Nouvel enum `PickerMode` (5 valeurs : `derived`, `opt_out`, `free_with_obligatory`, `series_plus_optional`, `tve_picker`)
   - `firestore_mappers.dart` : lire les nouveaux champs avec defaults safe
   - `CatalogueRepository.derive()` : récupérer la série post-match pour exposer `pickerMode` + `min/max` + résoudre `obligatorySubjects` + `optionalSubjects`

2. **Refactor catalogue snapshots → get (dette technique règle 10.g)** :
   - `CatalogueRepository.watchXxx()` (6 méthodes) → `fetchXxx()` retournant `Future<List<...>>`
   - `catalogue_repository_firestore_impl.dart` : `.snapshots()` → `.get()` + cache offline natif
   - `catalogueProvider` : `StreamProvider<CatalogueSnapshot>` → `FutureProvider<CatalogueSnapshot>` (charge une seule fois au boot puis sert depuis le cache Riverpod jusqu'au reload)
   - Refresh manuel : exposer une méthode `refreshCatalogue()` dans le provider pour invalider si admin Console active une nouvelle série pendant la session (cas marginal)
   - Adapter les 5+ tests existants

**Pourquoi maintenant** : Stories 1.14 (12 cards Tle franco groupées par famille) et 1.15 (refactor SubjectsPickerPage polymorphe `pickerMode`-aware) ne peuvent pas démarrer sans `DerivedProfile.pickerMode` exposé. L'audit règle 10.g a aussi flagué le pattern `snapshots()` comme dette technique à payer Story 1.13 cible (cf. BASE-DE-DONNEES.md historique 2026-06-09).

**Critère de fin** : `flutter test mobile_app/test/` reste 100 % vert (~196 tests baseline) + 10-15 nouveaux tests sur `PickerMode` + `DerivedProfile` v2 + non-régression Fatou Tle D (11 matières v2 + pickerMode `derived`) + James Upper Sixth S2 (3 matières + pickerMode `opt_out` + canOptOut: true préservé). Smoke device Fatou + James + Mariam Form 5 + Eyong TVE AL (préview validation Story 1.14-1.17). Build APK release OK. `flutter analyze` 0 issue.

## Story

**As a** développeur mobile Valide,
**I want** un `DerivedProfile` enrichi avec `pickerMode` + `obligatorySubjects` + `optionalSubjects` + `min/max` ET un catalogue lu via `.get()` au lieu de `.snapshots()` (économie reads),
**so that** Stories 1.14 / 1.15 / 1.16 / 1.17 puissent démarrer leur UI polymorphe panier sans patcher la couche data, et que le coût Firestore stagnant 369 docs catalogue × 6 streams listeners actifs (~600k reads/mois à 10k users) descende à 1 lecture initiale par session (~369k reads/mois × 0.3 sessions/jour = ~110k reads/mois — économie ~80 %).

## Acceptance Criteria

### AC1 — Modèles domain enrichis v2 (non-breaking via defaults safe)

**Given** [`mobile_app/lib/core/catalogue/domain/models.dart`](../../mobile_app/lib/core/catalogue/domain/models.dart) v1 (7 classes Equatable)
**When** l'extension v2 est appliquée
**Then** les modifications suivantes sont effectuées :

**Nouvel enum `PickerMode`** (5 valeurs) :

```dart
/// Mode de sélection des matières — Story 1.11a (ADR-016 Décision 3).
enum PickerMode {
  /// Default — matières dérivées non modifiables (Tle franco).
  derived,
  /// Story 1.4 legacy — retrait simple (Anglo Lower/Upper Sixth avant 1.16).
  optOut,
  /// O-Level Form 3-5 — sélection libre 6-11 + obligatoires EN+FR+Math.
  freeWithObligatory,
  /// A-Level Lower/Upper Sixth — Series fixe + transversales optionnelles.
  seriesPlusOptional,
  /// TVEE — Professional + Related obligatoires + Other libres.
  tvePicker;

  /// Parse string Firestore en enum. Fallback `derived` si valeur inconnue.
  static PickerMode fromString(String? raw) {
    return switch (raw) {
      'derived' => PickerMode.derived,
      'opt_out' => PickerMode.optOut,
      'free_with_obligatory' => PickerMode.freeWithObligatory,
      'series_plus_optional' => PickerMode.seriesPlusOptional,
      'tve_picker' => PickerMode.tvePicker,
      _ => PickerMode.derived,
    };
  }
}
```

**`Serie` étendue (+6 champs nullable)** :

```dart
class Serie extends Equatable {
  const Serie({
    required this.serieId,
    required this.subSystem,
    required this.niveauId,
    required this.filiereId,
    required this.name,
    required this.canOptOut,
    required this.isActive,
    required this.sortOrder,
    // NEW v2 — Story 1.13 (lus depuis Firestore via firestore_mappers).
    this.pickerMode = PickerMode.derived,  // default safe v1
    this.minSubjects,
    this.maxSubjects,
    this.professionalSubjectIds = const [],
    this.relatedProfessionalSubjectIds = const [],
    this.otherSubjectIds = const [],
  });
  // ... fields ...
  final PickerMode pickerMode;
  final int? minSubjects;
  final int? maxSubjects;
  final List<String> professionalSubjectIds;
  final List<String> relatedProfessionalSubjectIds;
  final List<String> otherSubjectIds;
}
```

**`DerivationRule` étendue (+2 champs nullable)** :

```dart
class DerivationRule extends Equatable {
  const DerivationRule({
    required this.ruleId,
    required this.matchSubSystem,
    required this.matchFiliere,
    required this.matchNiveau,
    required this.matchSerie,
    required this.subjectIds,
    required this.examTargetIds,
    required this.canOptOut,
    required this.isActive,
    // NEW v2 — Story 1.13.
    this.obligatorySubjectIds = const [],
    this.optionalSubjectIds = const [],
  });
  // ...
  final List<String> obligatorySubjectIds;
  final List<String> optionalSubjectIds;
}
```

**`DerivedProfile` étendu (+5 champs)** :

```dart
class DerivedProfile extends Equatable {
  const DerivedProfile({
    required this.subjects,
    required this.examTargets,
    required this.canOptOut,
    // NEW v2 — Story 1.13.
    this.pickerMode = PickerMode.derived,
    this.obligatorySubjects = const [],
    this.optionalSubjects = const [],
    this.minSubjects,
    this.maxSubjects,
  });
  // ...
  final PickerMode pickerMode;
  final List<Subject> obligatorySubjects;
  final List<Subject> optionalSubjects;
  final int? minSubjects;
  final int? maxSubjects;
}
```

**And** la classe `Equatable.props` est étendue avec les nouveaux champs pour les 3 modèles.

**And** la méthode `toJson()` n'est PAS étendue (`toJson` sert uniquement aux tests + debug — pas critique). Optionnel : ajouter les nouveaux champs en `toJson` pour faciliter le debug. Décision : ajouter pour cohérence.

**And** les modèles sont **strictement non-breaking** : tout code v1 qui crée une `Serie` ou `DerivedProfile` sans les nouveaux champs continue à fonctionner (defaults safe).

### AC2 — `firestore_mappers.dart` lit les nouveaux champs

**Given** [`mobile_app/lib/core/catalogue/data/firestore_mappers.dart`](../../mobile_app/lib/core/catalogue/data/firestore_mappers.dart) v1
**When** les factories sont mises à jour
**Then** :

```dart
Serie serieFromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
  final data = snap.data();
  if (data == null) throw StateError('serie doc ${snap.id} has no data');
  return Serie(
    // v1 ...
    serieId: snap.id,
    subSystem: data['subSystem'] as String,
    niveauId: data['niveauId'] as String,
    filiereId: data['filiereId'] as String,
    name: _readBilingualName(data['name']),
    canOptOut: (data['canOptOut'] as bool?) ?? false,
    isActive: (data['isActive'] as bool?) ?? false,
    sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    // NEW v2 — Story 1.13
    pickerMode: PickerMode.fromString(data['pickerMode'] as String?),
    minSubjects: (data['minSubjects'] as num?)?.toInt(),
    maxSubjects: (data['maxSubjects'] as num?)?.toInt(),
    professionalSubjectIds: _readStringList(data['professionalSubjectIds']),
    relatedProfessionalSubjectIds: _readStringList(data['relatedProfessionalSubjectIds']),
    otherSubjectIds: _readStringList(data['otherSubjectIds']),
  );
}

DerivationRule derivationRuleFromFirestore(snap) {
  return DerivationRule(
    // v1 ...
    // NEW v2 — Story 1.13
    obligatorySubjectIds: _readStringList(data['obligatorySubjectIds']),
    optionalSubjectIds: _readStringList(data['optionalSubjectIds']),
  );
}
```

**And** les autres factories (filiere, niveau, subject, exam_target) **ne sont pas modifiées** (pas de nouveau champ).

**And** les defaults safe : `pickerMode` → `PickerMode.derived` si absent (v1 compat), `min/maxSubjects` → `null` si absent, listes vides si absentes. Aucune exception levée si un doc v1 (sans ces champs) est lu.

### AC3 — `CatalogueRepository.derive()` v2 retourne `DerivedProfile` enrichi

**Given** [`catalogue_repository_firestore_impl.dart`](../../mobile_app/lib/core/catalogue/data/catalogue_repository_firestore_impl.dart) `derive()` v1 (lignes 128-224)
**When** l'algorithme est étendu selon ALGORITHMES.md § 1 v2 (cf. Story 1.11a AC4)
**Then** la méthode :

1. Match la première `derivation_rule` active compatible (inchangé v1)
2. Récupère la `Serie` correspondante (nouvelle étape — via `_firestore.collection('series').doc(serieId).get()` si `serie != null`, sinon `null` pour les niveaux sans série)
3. Résout en parallèle : `subjects`, `examTargets`, `obligatorySubjects`, `optionalSubjects` (4 reads parallélisés via `Future.wait`)
4. Construit `DerivedProfile` avec :
   - `subjects` (v1)
   - `examTargets` (v1)
   - `canOptOut` (depuis `rule.canOptOut` ou `serie?.canOptOut` — préférer la série si présente)
   - **NEW** `pickerMode` = `serie?.pickerMode ?? PickerMode.derived`
   - **NEW** `obligatorySubjects` = résolus depuis `rule.obligatorySubjectIds`
   - **NEW** `optionalSubjects` = résolus depuis `rule.optionalSubjectIds`
   - **NEW** `minSubjects` = `serie?.minSubjects`
   - **NEW** `maxSubjects` = `serie?.maxSubjects`

**Pseudo-code** :

```dart
Future<Either<CatalogueFailure, DerivedProfile>> derive({
  required String subSystem,
  required String filiere,
  required String niveau,
  String? serie,
}) async {
  try {
    // 1. Match rule (inchangé v1)
    final rulesSnap = await _firestore.collection(_kDerivationRules)
        .where('matchSubSystem', isEqualTo: subSystem)
        .where('matchNiveau', isEqualTo: niveau)
        .where('isActive', isEqualTo: true)
        .get();

    final candidates = rulesSnap.docs.map(derivationRuleFromFirestore)
        .where((r) => r.matchFiliere == '*' || r.matchFiliere == filiere)
        .where((r) => r.matchSerie == null || r.matchSerie == serie)
        .toList(growable: false);

    if (candidates.isEmpty) {
      return Left(CatalogueFailure.noMatchingRule(...));
    }
    final rule = candidates.first;

    // 2. NEW v2 — fetch série si présente
    final serieDocFuture = serie != null
        ? _firestore.collection(_kSeries).doc(serie).get()
            .then((snap) => snap.exists ? serieFromFirestore(snap) : null)
        : Future.value(null);

    // 3. Résolution parallèle (4 futures) — whereIn limite 30, OK
    final subjectsFuture = _fetchSubjectsByIds(rule.subjectIds);
    final examTargetsFuture = _fetchExamTargetsByIds(rule.examTargetIds);
    final obligatorySubjectsFuture = _fetchSubjectsByIds(rule.obligatorySubjectIds);
    final optionalSubjectsFuture = _fetchSubjectsByIds(rule.optionalSubjectIds);

    final results = await Future.wait([
      serieDocFuture,
      subjectsFuture,
      examTargetsFuture,
      obligatorySubjectsFuture,
      optionalSubjectsFuture,
    ]);

    final Serie? serieDoc = results[0] as Serie?;
    final subjects = results[1] as List<Subject>;
    final examTargets = results[2] as List<ExamTarget>;
    final obligatorySubjects = results[3] as List<Subject>;
    final optionalSubjects = results[4] as List<Subject>;

    return Right(DerivedProfile(
      subjects: subjects,
      examTargets: examTargets,
      canOptOut: serieDoc?.canOptOut ?? rule.canOptOut,
      pickerMode: serieDoc?.pickerMode ?? PickerMode.derived,
      obligatorySubjects: obligatorySubjects,
      optionalSubjects: optionalSubjects,
      minSubjects: serieDoc?.minSubjects,
      maxSubjects: serieDoc?.maxSubjects,
    ));
  } on FirebaseException catch (e) { /* ... */ }
}
```

**And** helper privé `_fetchSubjectsByIds(List<String> ids)` extrait pour éviter la duplication (logique `whereIn` + `where('isActive')` + map factories — utilisée 3× : subjects, obligatorySubjects, optionalSubjects).

**And** logging : `derive() OK: profile=(...) subjects=N obligatory=M optional=K pickerMode=X` (sans logger les IDs sensibles côté utilisateur).

**And** comportement **strictement non-breaking** : Fatou (Tle D) qui a déjà été dérivée sans pickedSubjects côté users/{uid} continue à fonctionner. James (Upper Sixth S2) avec `canOptOut: true` legacy continue à fonctionner.

### AC4 — Refactor catalogue snapshots → get (audit règle 10.g)

**Given** [`catalogue_repository.dart`](../../mobile_app/lib/core/catalogue/domain/catalogue_repository.dart) interface v1 + [`catalogue_repository_firestore_impl.dart`](../../mobile_app/lib/core/catalogue/data/catalogue_repository_firestore_impl.dart) v1 + [`providers.dart`](../../mobile_app/lib/core/catalogue/providers.dart) v1
**When** le refactor est appliqué selon l'audit règle 10.g de BASE-DE-DONNEES.md
**Then** :

**Interface domain** :

```dart
abstract interface class CatalogueRepository {
  // RENAMED : watchXxx -> fetchXxx (Stream -> Future)
  Future<List<Filiere>> fetchFilieres();
  Future<List<Niveau>> fetchNiveaux({String? subSystem, String? filiereId});
  Future<List<Serie>> fetchSeries({String? subSystem, String? niveauId, String? filiereId});
  Future<List<Subject>> fetchSubjects({String? subSystem});
  Future<List<ExamTarget>> fetchExamTargets({String? subSystem});
  Future<List<DerivationRule>> fetchDerivationRules({String? subSystem});

  // inchangé v1
  Future<Either<CatalogueFailure, DerivedProfile>> derive({...});
  Future<bool> hasNonEmptyCatalogue();
}
```

**Impl Firestore** : remplacer `.snapshots().map(...)` par `.get().then(...)` dans les 6 méthodes. Le cache offline natif Firestore garantit que les lectures suivantes sont instantanées sur les docs déjà chargés (NFR-5, ADR-010).

**Provider Riverpod** : `catalogueProvider` `StreamProvider` → `FutureProvider`.

```dart
final catalogueProvider = FutureProvider<CatalogueSnapshot>((ref) async {
  final repo = ref.watch(catalogueRepositoryProvider);
  // Charge les 6 collections en parallèle (1 read initial par doc, puis cache)
  final results = await Future.wait([
    repo.fetchFilieres(),
    repo.fetchNiveaux(),
    repo.fetchSeries(),
    repo.fetchSubjects(),
    repo.fetchExamTargets(),
    repo.fetchDerivationRules(),
  ]);
  return CatalogueSnapshot(
    filieres: results[0] as List<Filiere>,
    niveaux: results[1] as List<Niveau>,
    series: results[2] as List<Serie>,
    subjects: results[3] as List<Subject>,
    examTargets: results[4] as List<ExamTarget>,
    derivationRules: results[5] as List<DerivationRule>,
  );
});
```

**And** la méthode `appStartupCatalogueCheckProvider` (FutureProvider) reste inchangée — utilise déjà `.get()` en interne (`hasNonEmptyCatalogue()`).

**And** invalidation pour refresh runtime : exposer un helper Riverpod standard `ref.invalidate(catalogueProvider)` à appeler depuis l'admin quand on veut forcer un refresh (ex. après activation d'une nouvelle série Console). En V1, pas de bouton refresh UI explicite — le redémarrage app suffira.

**And** **STORYTELLING IMPORTANT** : le `catalogueProvider` était utilisé par Story 1.3 dans `derivedProfileProvider` ? **NON** — vérification : `derivedProfileProvider` appelle directement `repo.derive()` qui fait ses propres `.get()` (cf. catalogue_repository_firestore_impl.dart lignes 140-145). Donc le refactor n'impacte pas le flow onboarding. Le `catalogueProvider` (agrégé) est utilisé uniquement pour les listes dans SubSystemChoicePage / NiveauChoicePage / SerieChoicePage / SubjectsOptOutPage qui consomment via `ref.watch(catalogueProvider).whenData(...)`.

**Impact attendu sur ces 4 pages** : `AsyncValue<CatalogueSnapshot>` reste compatible (FutureProvider ET StreamProvider exposent tous deux `AsyncValue`). Aucun changement UI nécessaire — le widget se reconstruit une seule fois quand le Future résout (au lieu de re-build à chaque émission stream — gain perf bonus).

**Économie estimée** : 6 streams listeners actifs × 369 docs ≈ 600k reads/mois à 10k users → 1 read initial × 369 docs × 0.3 sessions/jour ≈ 110k reads/mois. **Économie ~80 %**.

### AC5 — Tests : 10-15 nouveaux + adaptation tests existants

**Given** la suite de tests `mobile_app/test/` baseline 196 tests verts (post-1.12)
**When** la story est livrée
**Then** :

**Nouveaux tests** (10-15 cas) :

1. `test/core/catalogue/domain/picker_mode_test.dart` (NEW) — `PickerMode.fromString` 5 cas valides + 1 cas fallback `'unknown' → derived`. (6 tests)
2. `test/core/catalogue/domain/models_v2_test.dart` (NEW) — `Serie` + `DerivationRule` + `DerivedProfile` props inclus `pickerMode` + nouveaux champs. (~5 tests)
3. `test/core/catalogue/data/firestore_mappers_v2_test.dart` (UPDATE existant) — `serieFromFirestore` avec `pickerMode='tve_picker'` + `minSubjects: 5` + `maxSubjects: 11` + listes Pro/Related/Other. Idem `derivationRuleFromFirestore` avec `obligatorySubjectIds` + `optionalSubjectIds`. (~4 tests)
4. `test/core/catalogue/data/catalogue_repository_derive_v2_test.dart` (UPDATE existant ou NEW) — `derive()` retourne DerivedProfile enrichi. Cas testés :
   - Fatou Tle D v2 : `pickerMode == derived`, `obligatorySubjects.isEmpty`, `optionalSubjects.isEmpty`, `min/max == null`, 11 subjects + 1 examTarget
   - James Upper Sixth S2 : `pickerMode == optOut`, `canOptOut: true` préservé, 3 subjects + 1 examTarget
   - Mariam Form 5 anglo : `pickerMode == derived` côté rule (pas de série Form 5 v1 mais on lit le `pickerMode` du rule via la série si elle existe — si null, fallback `derived` qui est correct pour V1, le mode `freeWithObligatory` Form 5 sera implémenté Story 1.15 via une autre voie)
   - Eyong TVE AL ELET : `pickerMode == tvePicker`, `minSubjects == 6`, `maxSubjects == 8`
   (~5 tests)

**Adaptation tests existants** (5+) :

5. Renommer les tests qui appellent `repo.watchXxx()` → `repo.fetchXxx()`. Ces tests utilisent `fake_cloud_firestore` qui supporte `.get()` ET `.snapshots()` — adaptation triviale.

**Validation** :
- `cd mobile_app && flutter test test/core/catalogue/` → 100 % vert (~25 tests baseline catalogue + 15 nouveaux = ~40 verts)
- `flutter test` → 100 % vert (~211 tests total post-1.13)
- `flutter analyze` → 0 issue

### AC6 — Smoke tests device non-régression Fatou + James + Mariam + Eyong (préview)

**Given** un build APK release sur Pixel 4a OU émulateur Android post-merge Story 1.13
**When** un porteur fait un parcours manuel
**Then** :

1. **Fatou Tle D francophone** (parcours nominal v2) :
   - Onboarding → recap affiche **11 matières v2** (Math, Physique, Chimie, SVT, Environnement, FR, EN, Philo, HG, Informatique, EPS)
   - `derivedProfileProvider.value.fold(...)` retourne `DerivedProfile(pickerMode: PickerMode.derived, obligatorySubjects: [], optionalSubjects: [], min/max: null)`
   - Dashboard : 11 cards matières + examLabel "BAC D"
   - Lien "Modifier" : invisible (canOptOut: false)

2. **James Upper Sixth S2** (non-régression Story 1.4) :
   - Onboarding → recap affiche 3 matières (Chemistry, Physics, Biology)
   - `derive()` retourne `DerivedProfile(pickerMode: PickerMode.optOut, canOptOut: true)` (lit la série post-1.12 avec pickerMode 'opt_out')
   - Lien "Modifier" : visible → SubjectsOptOutPage v1 s'ouvre (UI inchangée — pas de refactor Story 1.15 ici)
   - Tap toggle Biology → recap 2 matières + `optedOutSubjects: ['anglophone_biology']` persisté
   - **Comportement Story 1.4 strictement préservé** (validation non-régression critique)

3. **Mariam Form 5 anglophone** (préview Story 1.15) :
   - Onboarding → recap affiche 10 matières dérivées (Form 5 v1 list) + `pickerMode: PickerMode.derived` (pas de série pour Form 5)
   - Note : le mode `freeWithObligatory` sera activé Story 1.15 via une décision UI (rule-level pickerMode ou série virtuelle). Cette story n'expose pas encore le picker O-Level.

4. **Eyong TVE AL Electrotechnique** (préview Story 1.17) :
   - Activer manuellement `series/anglophone_tve_al_elet.isActive = true` dans Firebase Console + `derivation_rules/rule_anglophone_technique_tve_al_elet.isActive = true`
   - Onboarding → recap affiche 0 matières dérivées (subjectIds: [] squelette) + `pickerMode: PickerMode.tvePicker` + `minSubjects: 6` + `maxSubjects: 8`
   - Lien "Modifier" : visible (canOptOut: false mais picker mode actif — UI à implémenter Story 1.17)

**Documentation** : screenshots Fatou + James OK (sans PII) en Completion Notes. Mariam + Eyong reports textuels (préview Story 1.15 + 1.17, pas d'UI à implémenter).

### AC7 — Aucune modification doc/partage, firestore.rules, firestore.indexes.json, mobile_app/lib widgets

**Given** la PR Story 1.13
**When** on inspecte le diff
**Then** :
- **Aucune modification** `doc/partage/*` (déjà fait Story 1.11a)
- **Aucune modification** `firestore.rules` (pickedSubjectsValid defere Story 1.15)
- **Aucune modification** `firestore.indexes.json` (CLAUDE.md règle 9 — l'audit a confirmé 0 nouvel index requis pour les nouveaux champs)
- **Aucune modification widgets** (`features/onboarding/presentation/*.dart`, `features/dashboard/*.dart`) — UI v1 préservée. Stories 1.14-1.17 modifieront les widgets.
- **Aucune modification matrice.json** (déjà fait Story 1.12)
- **Aucune modification** `seed_catalogue.py`

**Modif autorisées scope** :
- `mobile_app/lib/core/catalogue/domain/models.dart` (UPDATE — enum + 3 modèles étendus)
- `mobile_app/lib/core/catalogue/domain/catalogue_repository.dart` (UPDATE — interface watchXxx → fetchXxx)
- `mobile_app/lib/core/catalogue/data/firestore_mappers.dart` (UPDATE — lecture 6+2 nouveaux champs)
- `mobile_app/lib/core/catalogue/data/catalogue_repository_firestore_impl.dart` (UPDATE — derive() v2 + refactor snapshots → get)
- `mobile_app/lib/core/catalogue/providers.dart` (UPDATE — catalogueProvider StreamProvider → FutureProvider)
- `mobile_app/test/core/catalogue/*` (UPDATE + NEW tests)

**Diff cible** : PR ≤ 600 lignes hors tests (les tests peuvent ajouter ~300 lignes additionnelles).

## Tasks / Subtasks

- [ ] **T1 — Enrichir modèles domain v2 + enum `PickerMode`** (AC1)
  - [ ] T1.1 Créer enum `PickerMode` (5 valeurs + `fromString`) dans `models.dart` ou nouveau fichier `picker_mode.dart`
  - [ ] T1.2 Étendre `Serie` avec +6 champs nullable + defaults safe
  - [ ] T1.3 Étendre `DerivationRule` avec +2 champs nullable
  - [ ] T1.4 Étendre `DerivedProfile` avec +5 champs
  - [ ] T1.5 Mettre à jour `Equatable.props` pour les 3 modèles
  - [ ] T1.6 Mettre à jour `toJson` pour cohérence debug (optionnel mais recommandé)

- [ ] **T2 — `firestore_mappers.dart` lit les nouveaux champs** (AC2)
  - [ ] T2.1 `serieFromFirestore` : ajouter 6 lignes pour les nouveaux champs avec defaults safe
  - [ ] T2.2 `derivationRuleFromFirestore` : ajouter 2 lignes pour `obligatorySubjectIds` + `optionalSubjectIds`
  - [ ] T2.3 Vérifier que les autres factories (`filiere`, `niveau`, `subject`, `exam_target`) ne sont pas impactées

- [ ] **T3 — `CatalogueRepository.derive()` v2** (AC3)
  - [ ] T3.1 Extraire helper privé `_fetchSubjectsByIds(List<String> ids)` (factorisation 3× réutilisation : subjects, obligatorySubjects, optionalSubjects)
  - [ ] T3.2 Récupérer la série en parallèle avec subjects/examTargets (nouvelle étape via `_firestore.collection(_kSeries).doc(serieId).get()`)
  - [ ] T3.3 Résoudre `obligatorySubjects` + `optionalSubjects` en parallèle (4 futures via `Future.wait`)
  - [ ] T3.4 Construire `DerivedProfile` enrichi avec `pickerMode` (depuis série ou fallback `derived`) + min/max + listes
  - [ ] T3.5 `canOptOut` : préférer `serie?.canOptOut` à `rule.canOptOut` (source de vérité v2 = série)
  - [ ] T3.6 Logging mis à jour : ajouter `pickerMode` + `obligatory` + `optional` counts en log info (jamais d'IDs sensibles)

- [ ] **T4 — Refactor catalogue snapshots → get (dette technique audit règle 10.g)** (AC4)
  - [ ] T4.1 Renommer interface `CatalogueRepository.watchXxx()` → `fetchXxx()` (6 méthodes : filieres, niveaux, series, subjects, examTargets, derivationRules)
  - [ ] T4.2 Changer signatures de `Stream<List<...>>` → `Future<List<...>>` dans interface + impl
  - [ ] T4.3 Remplacer `.snapshots().map(...)` par `.get().then(...)` dans les 6 méthodes (impl Firestore)
  - [ ] T4.4 `catalogueProvider` : `StreamProvider<CatalogueSnapshot>` → `FutureProvider<CatalogueSnapshot>`
  - [ ] T4.5 Logique du provider : `Future.wait` sur 6 fetchXxx() au lieu de combiner 6 streams via StreamController
  - [ ] T4.6 Supprimer le code de gestion des 6 subscriptions + StreamController + onDispose (plus nécessaire avec FutureProvider)
  - [ ] T4.7 Documenter dans le commentaire en tête de fichier : "Refactor Story 1.13 — snapshots → get, économie ~80 % reads, cohérent CLAUDE.md règle 10.g"

- [ ] **T5 — Adaptation tests existants** (AC5)
  - [ ] T5.1 Identifier les tests qui appellent `watchXxx()` → renommer en `fetchXxx()`
  - [ ] T5.2 Adapter les tests `fake_cloud_firestore` (passer de `.snapshots()` à `.get()` — `fake_cloud_firestore` supporte les deux nativement)
  - [ ] T5.3 Adapter les tests qui font des `expect(stream, emits(...))` → `expect(await future, equals(...))`

- [ ] **T6 — Nouveaux tests v2** (AC5)
  - [ ] T6.1 `picker_mode_test.dart` : 6 cas `fromString` (5 valides + 1 fallback)
  - [ ] T6.2 `models_v2_test.dart` : props inclusion pour 3 modèles enrichis (5 tests)
  - [ ] T6.3 `firestore_mappers_v2_test.dart` : mappers lisent les nouveaux champs avec defaults safe (4 tests : serie complète, serie sans champs v2 → defaults, rule complète, rule sans champs v2 → defaults)
  - [ ] T6.4 `catalogue_repository_derive_v2_test.dart` : `derive()` Fatou Tle D + James Upper Sixth S2 + Eyong TVE AL + Mariam Form 5 (4-5 tests cas BDD)

- [ ] **T7 — Validation finale** (AC6, AC7)
  - [ ] T7.1 `cd mobile_app && flutter analyze` → 0 issue
  - [ ] T7.2 `cd mobile_app && flutter test` → ~211 tests verts (vs baseline 196 = +15)
  - [ ] T7.3 `cd mobile_app && flutter test test/core/catalogue/` → 100 % vert
  - [ ] T7.4 Build APK release : `cd mobile_app && flutter build apk --release` OK
  - [ ] T7.5 Smoke test device Fatou Tle D : 11 matières + pickerMode derived
  - [ ] T7.6 Smoke test device James Upper Sixth S2 : 3 matières + canOptOut: true + opt-out fonctionne (Story 1.4 préservée)
  - [ ] T7.7 Préview test Mariam Form 5 + Eyong TVE AL (texte descriptif Completion Notes)
  - [ ] T7.8 Vérifier `git status` propre + diff ≤ 600 lignes hors tests
  - [ ] T7.9 Story frontmatter `status: review` + Dev Agent Record rempli + Change Log
  - [ ] T7.10 Commit `feat(catalogue): DerivedProfile v2 PickerMode + refactor catalogue snapshots -> get (Story 1.13)` + Co-Authored-By Claude Opus 4.7

- [ ] **T8 — Push branche + PR**
  - [ ] T8.1 Push `feat/1.13-derivedprofile-pickermode-extension`
  - [ ] T8.2 PR description : référence Story 1.11a + 1.12 + audit règle 10.g (BASE-DE-DONNEES.md historique 2026-06-09) + scope amendment combine 2 axes + estimation économie ~80 % reads Firestore

## Dev Notes

### Architecture compliance (CLAUDE.md règles)

- **Règle d'or des dépendances (1)** : `domain → presentation ← data`. Les modèles enrichis restent dans `domain/`. L'enum `PickerMode` reste dans `domain/`. Le mapper Firestore reste dans `data/`. AUCUNE rétro-dépendance.
- **Cache offline Firestore natif (5)** : préservé. Le refactor `.snapshots()` → `.get()` ne casse pas le cache — au contraire, l'exploite mieux (1 read initial puis cache).
- **Règle 9 Firestore indexes** : aucun nouvel index requis (audit BASE-DE-DONNEES.md 2026-06-09 confirme).
- **Règle 10 modélisation Firestore optimisée** : refactor aligne le code avec la règle 10.g (snapshots() sur catalogue = anti-pattern). Audit conformité passera de "1 non-conforme" à "0 non-conforme" post-1.13.
- **CLAUDE.md § doc/partage** : aucune modification (déjà fait Story 1.11a).
- **CLAUDE.md § Sécurité** : aucune nouvelle source de fuite. Le logging dans `derive()` reste sur des compteurs (counts), jamais des IDs ou contenus utilisateur.

### Stratégie de refactor snapshots → get

**Pourquoi en même temps que DerivedProfile v2** : les 2 axes touchent les mêmes 3 fichiers (`catalogue_repository.dart`, `catalogue_repository_firestore_impl.dart`, `providers.dart`). Combiner = 1 seule PR, 1 cycle de review, 1 cycle de tests. Séparer = 2 PRs avec adaptations tests dupliquées.

**Comportement utilisateur** : invisible. Le cache offline natif Firestore garantit que les lectures suivantes sont instantanées. L'activation runtime d'une nouvelle série (admin Console) ne sera visible qu'au prochain reload de l'app (vs immédiat avec snapshots) — trade-off accepté (admin agit rarement, utilisateur peut killer/relancer pour voir changement).

**Trade-off perdu** : changements live du catalogue. **Gain** : économie ~80 % reads + simplification code (suppression StreamController + 6 subscriptions). Sweet spot pour ~50k users.

### Decisions techniques figées (ne pas re-discuter)

- **`PickerMode` enum 5 valeurs** : `derived`, `optOut` (camelCase Dart), `freeWithObligatory`, `seriesPlusOptional`, `tvePicker`. Convention Dart enum `lowerCamelCase` (différent du Firestore snake_case).
- **`fromString` parse Firestore string** : `derived`/`opt_out`/`free_with_obligatory`/`series_plus_optional`/`tve_picker` → enum. Fallback sur valeur inconnue = `derived` (safe v1).
- **Defaults safe sur tous les nouveaux champs** : `pickerMode: PickerMode.derived` (Serie + DerivedProfile), listes vides pour obligatorySubjectIds/optionalSubjectIds/professionalSubjectIds/etc. Profils v1 continuent à fonctionner.
- **`canOptOut` source de vérité** : la **série** post-1.12 (qui a `pickerMode` + `canOptOut` cohérents). Fallback sur la rule si série absente.
- **`derive()` parallélise 5 futures** (série + subjects + examTargets + obligatorySubjects + optionalSubjects). `Future.wait` réduit latence cumulée à max(5 reads) au lieu de sum(5 reads).
- **`_fetchSubjectsByIds(List<String> ids)` helper privé** : extrait pour éviter duplication 3×. Limite Firestore `whereIn` = 30. Story 1.11a a confirmé que toutes les rules v2 ont ≤ 11 subjects (max Tle D) — OK.
- **Refactor `watchXxx → fetchXxx`** : nom Dart-idiomatique pour Future (vs Stream). Migration tests = renaming + `await`.
- **`catalogueProvider` reste `AsyncValue<CatalogueSnapshot>` côté consumer** — pas de change UI nécessaire (FutureProvider et StreamProvider exposent tous deux `AsyncValue`).

### Anti-patterns à éviter (LLM disaster prevention)

- ❌ **NE PAS supprimer les anciens noms `watchXxx`** sans grep pour vérifier qu'aucun consumer ne les appelle (autre que tests à adapter)
- ❌ **NE PAS oublier les defaults safe** sur les nouveaux champs (sinon profil v1 crash au mapper)
- ❌ **NE PAS oublier de renommer les TESTS** qui appellent `watchXxx` (`fake_cloud_firestore` supporte les deux mais l'API change)
- ❌ **NE PAS faire un Stream `Stream.fromFuture(get())`** (anti-pattern qui simule un stream avec 1 émission — pire que les 2 patterns)
- ❌ **NE PAS oublier `Future.wait` sur les 4 nouvelles futures dans `derive()`** (sinon latence cumulée 4× → 2-3s sur 3G Cameroun vs 600ms parallélisé)
- ❌ **NE PAS introduire `Source.cache` ou `Source.server` explicite** (laisser le défaut `serverAndCache` qui est le bon, cf. règle 10.h)
- ❌ **NE PAS modifier les widgets v1** (`subjects_opt_out_page.dart`, `profile_recap_page.dart`, `dashboard_page.dart`) — Stories 1.14-1.17 sont en charge de l'UI polymorphe
- ❌ **NE PAS modifier `subSystem_choice_page.dart` + `niveau_choice_page.dart` + `serie_choice_page.dart`** — le widget consume `AsyncValue<CatalogueSnapshot>` qui reste compatible
- ❌ **NE PAS oublier de logger `pickerMode`** dans le `derive() OK` log (utile pour debug Stories 1.14-1.17)
- ❌ **NE PAS ajouter le champ `pickerMode` à `toJson()`** sans en faire `String` (pas `PickerMode` enum, car le JSON debug doit rester sérialisable)
- ❌ **NE PAS introduire de dépendance nouvelle** (pas de freezed, json_serializable etc. — equatable suffit)

### Patterns à suivre (best practice projet)

- ✅ **Equatable.props** : étendu pour inclure les nouveaux champs (sinon `==` ne détecte pas les différences sur les nouveaux champs)
- ✅ **Defaults safe** : `pickerMode: PickerMode.derived`, listes vides, nullables explicites
- ✅ **`Future.wait` pour parallélisation** dans `derive()` (5 futures simultanées)
- ✅ **Helper privé `_fetchSubjectsByIds`** pour factoriser
- ✅ **`fake_cloud_firestore` pour tests** (déjà au pubspec via Stories antérieures)
- ✅ **Tests BDD style** : `test('Fatou Tle D — pickerMode derived + 11 subjects', () { ... })`
- ✅ **Logging counts uniquement** dans derive() (jamais d'IDs)
- ✅ **Convention commit FR impératif** : `feat(catalogue): DerivedProfile v2 PickerMode + refactor catalogue snapshots -> get (Story 1.13)`

### Library / framework requirements

- **Pas de nouvelle dépendance** (equatable + fpdart + cloud_firestore + flutter_riverpod déjà au pubspec)
- **Pas de changement de version** Flutter / Dart
- **fake_cloud_firestore** déjà au dev_dependencies (Stories antérieures)
- **flutter_test** standard

### Testing requirements

- **Coverage** : viser ~211 tests verts post-1.13 (vs 196 baseline post-1.12). +15 tests nets minimum.
- **Tests Fatou + James obligatoires** (non-régression critique)
- **Tests Mariam + Eyong en préview** (validation contrat Stories 1.15 + 1.17)
- **Pas de smoke device automatisé** (préview manuel post-merge porteur)

### Previous Story Intelligence

**Story 1.12 (mergée 2026-06-09 PR #67 commit 7f3628d)** :
- matrice.json v2 seedée sur valide-edu (369 docs incluant `pickerMode`, `obligatorySubjectIds`, `optionalSubjectIds`, `min/maxSubjects`, `professional/related/otherSubjectIds`)
- Les Tle franco sub-séries A1-A5/ABI/SH/AC/TI sont seedées avec `pickerMode: 'derived'` + isActive selon priorité
- Les Lower/Upper Sixth Sxx/Axx ont `pickerMode: 'opt_out'` + `minSubjects: 3` + `maxSubjects: 5` (préserve Story 1.4 legacy)
- Les TVEE 26 séries ont `pickerMode: 'tve_picker'` + `minSubjects/maxSubjects` selon TVE IL/AL + listes Pro/Related/Other vides squelette
- Tests pytest 6/6 verts post-1.12

**À respecter** : les noms exacts des champs Firestore (camelCase strict) doivent matcher avec `firestore_mappers.dart` — sinon lecture mobile silencieusement vide.

**Story 1.4 (mergée 2026-06-08 PR #48 commit 839d2c9)** — non-régression critique :
- `SubjectsOptOutPage` consomme `canOptOut: true` côté UI
- Lien "Modifier" affiché si `canOptOut: true`
- Persistance `users/{uid}.optedOutSubjects` via `userProfileRepository.updateOptedOutSubjects()`
- Tests rule 14 verts

**À respecter** : `derive()` v2 doit retourner `canOptOut: true` pour Upper Sixth S2 (lu depuis la série v2 qui a `pickerMode: 'opt_out'` + `canOptOut: true`). Faute de quoi le lien "Modifier" disparaît et Story 1.4 est cassée.

**CLAUDE.md règle 10 (mergée 2026-06-09 PR #69 commit 162497c)** :
- Section "Règles d'optimisation lecture / écriture (V1)" dans BASE-DE-DONNEES.md
- Audit 2026-06-09 : 7 OK + 1 non-conforme catalogue snapshots + 1 partiel
- Story 1.13 résout la non-conformité catalogue snapshots

### Git intelligence (5 derniers commits)

```text
162497c Merge pull request #69 from DelRoos/docs/claude-md-firestore-optimization-rule
ffa4dd2 docs(partage): BASE-DE-DONNEES.md +section Regles d'optimisation lecture/ecriture (V1)
6542660 Merge pull request #68 from DelRoos/docs/claude-md-firestore-optimization-rule
38b434c docs(core): ajoute regle 10 CLAUDE.md modelisation Firestore optimisee (lecture, latence, cout)
7f3628d Merge pull request #67 from DelRoos/feat/1.12-update-matrice-reseed-firestore
```

**Insights pour Story 1.13** :
- Branch baseline : `main` à `162497c` (avec règle 10 + BASE-DE-DONNEES.md update rules + Story 1.12 catalogue v2 seedé). Créer `feat/1.13-derivedprofile-pickermode-extension` depuis là.
- PRs récentes : tous merges propres. Pas de conflit attendu.
- Convention commit FR impératif cohérente.

### Project Structure Notes

- **Fichiers à modifier** : 5 fichiers `mobile_app/lib/core/catalogue/` (domain/models.dart, domain/catalogue_repository.dart, data/firestore_mappers.dart, data/catalogue_repository_firestore_impl.dart, providers.dart)
- **Fichiers à créer (tests)** : 4 fichiers `mobile_app/test/core/catalogue/` (picker_mode_test, models_v2_test, firestore_mappers_v2_test, catalogue_repository_derive_v2_test)
- **Fichiers à adapter (tests existants)** : ~5 tests qui utilisent `watchXxx()` (rename + await)
- **Aucune nouvelle entrée pubspec.yaml**
- **Aucune nouvelle clé ARB i18n**
- **Aucune modification widget Flutter**

### References

- [Source: project_manage/implementation-artifacts/1-11a-audit-matrice-v2-adr016.md § AC2 + AC4] — contrat schema v2 + ALGORITHMES amendé
- [Source: project_manage/planning-artifacts/architecture/adrs/ADR-016-catalogue-v2-sous-series-panier-tvee.md § Décision 3] — panier polymorphe via pickerMode enum
- [Source: doc/partage/BASE-DE-DONNEES.md § Catalogue scolaire v2] — schema TypeScript des nouveaux champs
- [Source: doc/partage/BASE-DE-DONNEES.md § Règles d'optimisation lecture/écriture § Audit conformité 2026-06-09] — dette technique catalogue snapshots
- [Source: doc/partage/ALGORITHMES.md § 1 algo derive() v2 enrichi + § Modes panier (PickerMode) v2] — pseudo-code de référence
- [Source: CLAUDE.md § Architecture mobile règle 10.g] — anti-pattern snapshots() sur catalogue
- [Source: mobile_app/lib/core/catalogue/domain/models.dart] — état actuel à étendre
- [Source: mobile_app/lib/core/catalogue/data/catalogue_repository_firestore_impl.dart] — état actuel à refactorer
- [Source: scripts/firebase_seed/data/matrice.json post-1.12] — contrat seed v2 sur valide-edu

## Notes pour Amelia (dev agent)

### Décisions techniques figées (récap rapide)

- **`PickerMode` enum 5 valeurs Dart `lowerCamelCase`** + `fromString` parse Firestore `snake_case`
- **Defaults safe partout** (pickerMode: derived, listes vides, nullables explicites)
- **`derive()` v2 parallélise 5 futures** via `Future.wait`
- **Helper privé `_fetchSubjectsByIds`** factorisé 3×
- **`watchXxx → fetchXxx`** rename + Stream → Future
- **`catalogueProvider` StreamProvider → FutureProvider** (suppression StreamController + subscriptions)
- **`canOptOut` source = série v2** (avec fallback rule)
- **Pas de modification widget Flutter** (UI v1 préservée)
- **Pas de nouvelle dépendance**

### Smoke tests obligatoires

1. **Fatou Tle D francophone** : 11 matières + `pickerMode: derived` + recap OK + dashboard OK
2. **James Upper Sixth S2 anglo** : 3 matières + `pickerMode: optOut` + `canOptOut: true` + Story 1.4 SubjectsOptOutPage continue à fonctionner

## Dev Agent Record

### Implementation Plan
<!-- À remplir par le dev agent -->

### Completion Notes List
<!-- À remplir par le dev agent -->

### File List
<!-- À remplir par le dev agent -->

### Change Log
<!-- À remplir par le dev agent -->

## Definition of Done

- [ ] **AC1-AC7 tous satisfaits**
- [ ] `flutter analyze` : 0 issue
- [ ] `flutter test` : ~211 tests verts (vs baseline 196 = +15)
- [ ] `flutter build apk --release` : OK
- [ ] Smoke test device Fatou Tle D : 11 matières + `pickerMode: derived`
- [ ] Smoke test device James Upper Sixth S2 : 3 matières + `pickerMode: optOut` + Story 1.4 préservée
- [ ] Préview test Mariam Form 5 + Eyong TVE AL (Completion Notes)
- [ ] Aucune modif `doc/partage/*`, `firestore.rules`, `firestore.indexes.json`, widgets `features/*/presentation/`, `matrice.json`, `seed_catalogue.py`
- [ ] PR diff ≤ 600 lignes hors tests
- [ ] Audit conformité règle 10.g : passe de "1 non-conforme" à "0 non-conforme"
- [ ] Commit Conventional FR + Co-Authored-By Claude
- [ ] PR ouverte avec description claire (référence Stories 1.11a + 1.12 + audit règle 10.g)
- [ ] Story file frontmatter `status: review` + Dev Agent Record rempli
- [ ] sprint-status.yaml : `1-13-derivedprofile-pickermode-extension: review`
