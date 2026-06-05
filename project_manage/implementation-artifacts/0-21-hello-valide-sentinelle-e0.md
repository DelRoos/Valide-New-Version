---
story_id: 0.21
title: Page Hello Valide bilingue + smoke test E0 (sentinelle clôture Epic 0)
epic: 0
phase: P0
status: in-progress
created: 2026-06-05
branch: feature/0.21-hello-valide-sentinelle-e0
estimation: M (~4-5h)
dependencies:
  - 0.3   # AppLogger
  - 0.6   # Firebase
  - 0.7   # cache Firestore
  - 0.9   # règles _smoketest
  - 0.10  # design tokens
  - 0.13  # AppButton
  - 0.14  # composants feedback
  - 0.15  # PedagogicalContent
  - 0.16  # i18n FR/EN
  - 0.19  # gpt_markdown pivot
  - 0.19.2  # styling avancé + Mermaid
sourceArtifacts:
  - project_manage/planning-artifacts/epics/epic-0-foundation.md § Story 0.21
---

# Story 0.21 — Sentinelle E0

## Objectif

Page `/hello` qui intègre TOUS les blocs P0 (i18n + tokens + PedagogicalContent + AppButton + responsive) + smoke test Firestore au boot. Si une PR critique casse l'un des blocs, cette page le révèle visuellement et via tests widget. Reste utile post-MVP comme smoke test régression.

## Fichiers livrés

### Code mobile

- `lib/features/hello/presentation/hello_page.dart` — refactor : `ConsumerStatefulWidget` qui charge markdown depuis assets, affiche titre i18n, sélecteur langue runtime (`SegmentedButton<Locale>`), `PedagogicalContent` (Markdown + LaTeX + Mermaid), 2 `AppButton` (primary/secondary). Layout responsive max 600 dp.
- `lib/main.dart` — ajout `_e0SmokeTest()` après bootstrap Firebase : `signInAnonymously()` + `set('_smoketest/launch', {ts, buildVersion, uid})` + `get()` + log `AppLogger.i('E0 smoke test: write+read OK in Xms')`. Non bloquant : si Anonymous Auth pas activée ou Firestore indispo, log `AppLogger.w` et l'app continue.
- `assets/sentinel/hello_sentinel_fr.md` + `hello_sentinel_en.md` — markdown sentinelle bilingue (intégrale LaTeX + Mermaid flowchart 5 étapes).
- `pubspec.yaml` — déclaration assets `assets/sentinel/`.

### i18n

- `lib/l10n/app_fr.arb` + `app_en.arb` — clés ajoutées : `helloLanguageLabel`, `helloLanguageFr`, `helloLanguageEn`.

**Note technique** : le markdown sentinelle est dans des **assets** et pas dans les arb files. Tentative initiale d'embarquer le markdown comme valeur ARB a échoué — `gen-l10n` interprète les `$$` (LaTeX display) et `{...}` (Mermaid decision nodes) comme placeholders ICU. Assets externes = séparation propre i18n vs contenu pédagogique.

### Tests

- `test/widget_test.dart` — 3 tests responsive ajoutés (AC5) :
  - Phone 375×812 : titre + sélecteur langue + 2 boutons présents
  - Tablet 1024×1366 : idem
  - Phone landscape 812×375 : idem

5 widget tests passent (2 existants FR/EN + 3 responsive).

## Acceptance Criteria

| AC | Status | Notes |
| --- | --- | --- |
| AC1 — Page bilingue rendue (titre + langue switcher + PedagogicalContent + 2 boutons) | ✅ | Validé device : LaTeX `∫₀¹ x² dx = 1/3` rendu nickel, Mermaid flowchart avec labels lisibles, switch FR↔EN runtime sans rebuild |
| AC2 — Smoke test Firestore au boot | ✅ code, ⏳ Console | Code implémenté avec Anonymous Auth + write/read `_smoketest/launch`. Comportement réel dépend de l'activation Anonymous Auth dans Firebase Console (action porteur). Failure non bloquante (AppLogger.w) |
| AC3 — Crashlytics actif + `/_crash` | ✅ | Route `/_crash` existe depuis Story 0.6 ; test à valider en Console après merge |
| AC4 — Deploy Play Internal + TestFlight | ❌ déféré | Dépend Story 0.17 (CI/CD GitHub Actions) qui a été skippée |
| AC5 — Sentinelle régression dans CI | ⚠️ partiel | Tests widget 3 tailles codés et passent localement. Intégration CI dépend Story 0.17 |
| AC6 — Responsive 4 cibles | ⚠️ Android OK, iOS déféré | Validé device Redmi A7 Pro (phone 360 dp). Android tablet + iOS phone/tablet déférés (pas de Mac, pas de tablet sous la main) |

## Definition of Done

- [x] HelloPage refactor : i18n + PedagogicalContent + AppButton + responsive
- [x] Smoke test Firestore implémenté dans main.dart
- [x] Tests widget 3 tailles d'écran passent
- [x] flutter analyze 0 issue
- [x] Validation device Android (Redmi A7 Pro) : screenshots FR + EN
- [ ] Activation Anonymous Auth dans Firebase Console (porteur, post-merge)
- [ ] Validation `_smoketest/launch` créé dans Firestore Console (porteur, post-merge)
- [ ] Validation iOS (Mac requis, à reporter en session Mac)
- [ ] PR ≤ 250 lignes diff
- [ ] Commit `feat(app): page Hello Valide bilingue responsive sentinelle E0`

## Cadrage des ACs déférés

Les ACs 4, 5 (CI) et la moitié d'AC6 (iOS) dépendent de :
- **Story 0.17 (CI/CD)** — explicitement skippée par décision utilisateur dans le sprint
- **Mac iOS dev** — pas de session Mac dans le sprint courant

Ces ACs seront couverts dans une **clôture E0 bis** quand l'environnement le permettra. La sentinelle code-side est livrée et validée Android.

## Phase porteur (post-merge)

1. **Firebase Console > Auth > Sign-in methods** : activer **Anonymous**
2. **Réinstaller l'APK release** sur le device : `adb install -r build/app/outputs/flutter-apk/app-release.apk`
3. **Lancer l'app** : vérifier dans Firestore Console que `_smoketest/launch` est créé avec `{ts, buildVersion: '1.0.0+1', uid: 'anonymous-uid'}`
4. **Tester crash** : naviguer `/_crash` → tap bouton → vérifier Crashlytics Console < 5 min
5. **Quand CI 0.17 sera fait** : intégrer les widget tests responsive dans le workflow PR

## Notes

- La route `/_crash` doit être **conservée** jusqu'à ce que Story 0.21 soit fully validated. Suppression dans une PR de suivi (chore).
- Le markdown sentinelle est dans `assets/sentinel/` et **pas retiré à la clôture E0** : il sert de smoke test régression continu.
- Les routes debug `/_test_courses`, `/_ai_smoke` peuvent être supprimées en chore post-E0 (Story 0.19.x était terrain, plus utile maintenant).
