# ADR-016 — Catalogue v2 : sous-séries flat francophone + TVEE filière technique anglophone + panier polymorphe

**Date** : 2026-06-09
**Statut** : 🟢 Accepté
**Lié à** : [sprint-change-proposal-2026-06-09.md](../../sprint-change-proposal-2026-06-09.md), [ADR-015](./ADR-015-catalogue-firestore-runtime-activation.md)

## Contexte

Audit comparatif (2026-06-09) entre le catalogue Firestore v1 livré par Stories 1.1a/1.1b/1.1c et la **nomenclature officielle camerounaise** (Office du Baccalauréat francophone — [officedubac.cm](https://officedubac.cm/) + Cameroon GCE Board anglophone — [camgceb.org](https://camgceb.org/)) révèle 4 catégories de gaps critiques :

1. **Matières manquantes** : 4 matières premier cycle francophone (Langues et Cultures Nationales, Informatique collège, Éducation Artistique, Travail Manuel), 4 matières O-Level anglophone (0546 Special Bilingual French, 0555 Geology, 0565 Human Biology, 0590 Logic) + 0505 Accounting, 6 matières A-Level anglophone (0746 Bilingual French, 0790 Philosophy, 0796 ICT, 0765 Pure Maths Mechanics, 0770 Pure Maths Stats, 0740 Food Science Nutrition), erreurs de composition séries C/D francophones (LV2 erronée, PCT à séparer en Physique+Chimie, Informatique absente, Environnement absente sur D).

2. **Sous-séries Tle francophone absentes** : la nomenclature officielle distingue **A1, A2, A3, A4, A5, ABI, SH, AC, TI** (en plus de C, D, E). Le catalogue v1 ne modélise que A (générique), C, D, E.

3. **Règles de choix anglophone non implémentées** :
   - **O-Level** : règle officielle = « min 6 matières, max 11 avec Religious Studies (10 sinon), avec English Language + French + Mathematics obligatoires ». Catalogue v1 traite l'élève Form 5 comme dérivé non modifiable.
   - **A-Level** : règle officielle = « max 5 matières, Series = combinaison de 3-4 fixes, matières transversales optionnelles ajoutables (Computer Science, ICT, Religious Studies, Commerce) ». Catalogue v1 fige la combinaison Series sans flexibilité.

4. **Sous-système ESTP anglophone (TVEE) totalement absent** : la nomenclature officielle GCE Board liste **TVE Intermediate Level** (équivalent O-Level technique, fin Form 5) + **TVE Advanced Level** (équivalent A-Level technique, fin Upper Sixth) avec 13+ spécialités (ELEQ Electrical Equipment, ELNI Electronics, ELME Electromechanical, ELET Electrotechnique, AC Air Conditioning, ME Mechanical Engineering, CE Civil Engineering, Carpentry, Accounting, Commerce, Office Practice, Food & Nutrition, Clothing & Textiles). Le catalogue v1 ne couvre aucun parcours technique anglophone.

PO Delano Roosvelt confirme le 2026-06-09 (AskUserQuestion /bmad-correct-course) : aligner les 4 axes. Décisions architecturales à acter.

**Citations evidence verbatim** (sprint-change-proposal-2026-06-09.md § 1) :

> « Le dashboard skeletton met un bouton pour effacer le cache nettoyer le firestore et supprimer le compte on vas maintenant faire un test de parcour ca dois etre facile de pouvoir recommencer on va faire un audit complet sur le parcour plusieurs fois aussi voici la description de comment fonctionne lecole et les choix on souhaite que l'application soit aligner analyse et dis moi si c'est le cas et complete aussi les matiere »

**Source authoritaire de la décision** : doc utilisateur 2026-06-09 « Orientation et matières au secondaire camerounais » — synthèse complète des sources officielles MINESEC + Office du Bac + Cameroon GCE Board.

## Décisions

### Décision 1 — Sous-séries Tle francophone modélisées **flat** (pas hiérarchique)

Les sous-séries A1, A2, A3, A4, A5, ABI, SH, AC, TI sont modélisées comme **séries de plein droit** dans `series/` Firestore (ex. `francophone_terminale_a1`, `francophone_terminale_abi`, `francophone_terminale_ti`). Pas de hiérarchie parent-enfant entre une série A regroupant A1-A5 et ses enfants.

**Conséquence UX** : Tle Franco générale = 12 cards à plat sur SerieChoicePage (A1, A2, A3, A4, A5, ABI, SH, AC, C, D, E, TI) avec **groupement visuel par famille** (Lettres : A1-A5, ABI / Sciences humaines : SH, AC / Sciences : C, D / Sciences techniques : E, TI). Pas d'étape supplémentaire dans le flow profil 3 étapes existant. Décision livrée par Story 1.14.

**Rétrocompat** : la série `francophone_terminale_a` existante (catalogue v1) est conservée annotée DEPRECATED + `isActive: false` post-seed v2 (Story 1.12). Les profils déjà créés (`users/{uid}.serieId == "francophone_terminale_a"`) continuent à fonctionner.

**Alternative rejetée** : hiérarchique (groupe A puis sous-série A1-A5 dans une 4ᵉ étape conditionnelle). Refusée par PO (overhead UX, étape conditionnelle supplémentaire alourdit le flow 3 étapes existant, gain pédagogique marginal — l'élève sait directement quelle sous-série il prépare).

### Décision 2 — TVEE modélisé en filière `technique` dans subSystem `anglophone`

Le sous-système ESTP anglophone (TVEE) est modélisé en ajoutant la filière `technique` à `anglophone` (existante uniquement en `francophone` v1), avec 2 niveaux dédiés `anglophone_tve_il` (TVE Intermediate Level) et `anglophone_tve_al` (TVE Advanced Level), et 13 spécialités modélisées comme `series/`.

**Cohérence** : pattern identique au sous-système `francophone/technique` déjà modélisé v1 (F1-F5, G1-G3). Le sous-système reste le découpage linguistique fondamental, pas technique. Le profil `(subSystem='anglophone', filiere='technique', niveau='anglophone_tve_il', serie='anglophone_tve_il_elet')` est cohérent avec le profil francophone équivalent `(subSystem='francophone', filiere='technique', niveau='francophone_terminale', serie='francophone_terminale_f3')`.

**Activation initiale** : les 13 spécialités × 2 niveaux = 26 nouvelles `derivation_rules` TVEE seedées `isActive: false` initialement (Story 1.12). Activation runtime par l'admin pédagogique via Firebase Console après validation par enseignant TVEE camerophone (action porteur post-merge 1.17).

**Alternative rejetée** : nouveau subSystem `anglophone_technique`. Refusée car incohérente avec `francophone/technique` (le subSystem reste le découpage linguistique, pas technique vs général).

### Décision 3 — Panier polymorphe via champ `series.pickerMode` enum (5 valeurs)

Un nouveau champ `series.pickerMode: PickerMode` pilote le comportement de la page de sélection matières (`SubjectsPickerPage` après refactor Story 1.15). Les 5 valeurs :

- `derived` (default) : matières dérivées non modifiables — comportement v1 (Tle Franco A/C/D/E)
- `opt_out` (legacy Story 1.4) : retrait simple sur sous-ensemble dérivé — Lower/Upper Sixth A-Level avant 1.16
- `free_with_obligatory` (Story 1.15) : sélection libre min/max avec obligatoires non décochables — O-Level Form 3-5
- `series_plus_optional` (Story 1.16) : Series fixe + transversales optionnelles ajoutables — A-Level Lower/Upper Sixth après extension
- `tve_picker` (Story 1.17) : Professional + Related obligatoires + Other Subjects libres — TVEE IL/AL

**Default safe** : `pickerMode == 'derived'` si le champ est absent (rétrocompat v1). Les profils créés v1 (Fatou Tle D en mode dérivé, James Upper Sixth S2 en mode opt-out) continuent à fonctionner sans migration de données.

**Alternative rejetée** : panier mono-mode (un seul mode standard pour tous les profils). Refusée — impossibilité de couvrir simultanément O-Level (free + obligatoires), A-Level (Series + optionnelles), opt-out simple legacy, TVEE (Professional + Related + Other Subjects) avec un seul mode.

### Décision 4 — Validation panier **côté client (UI live)** + **côté Firestore rules**

Pour chaque mode panier, la validation (min/max + obligatoires présents + appartenance au set autorisé) est **dupliquée client + serveur** :

- **Client** : UI live (toast erreur sur tap décocher obligatoire, disable bouton Save sous min, blocage tap au-delà de max). UX rapide, pas de round-trip réseau pour l'erreur basique.
- **Serveur** : Firestore rule `pickedSubjectsValid()` rejette les updates `users/{uid}` invalides — garantie d'intégrité même si client bypass (ex. ancienne version mobile, outil externe).

```javascript
// firestore.rules — extrait Story 1.15
function pickedSubjectsValid(data) {
  let picked = data.get('pickedSubjects', []).toSet();
  let derived = data.derivedSubjects.toSet();
  let obligatory = data.get('obligatorySubjectIds', []).toSet();
  let optional = data.get('optionalSubjectIds', []).toSet();
  return picked.difference(derived.union(optional)).size() == 0  // ⊂ allowed
      && obligatory.difference(picked).size() == 0;               // obligatoires présents
}
```

**Alternative rejetée** : validation serveur uniquement. Refusée — UX dégradée (toast erreur après round-trip réseau Cameroun 3G ~ 500-1500ms), coût Firestore writes inutile pour erreurs détectables côté client.

## Conséquences

**Positives**

- **Alignement nomenclature officielle Cameroon** → MVP crédible auprès enseignants et établissements (validation enseignant qui voit son programme officiel reflété).
- **+20-25% du marché cible adressable** : parcours TVEE (Nord-Ouest/Sud-Ouest anglophones techniques) + parcours littéraires francophones complets (élèves Tle A1-A5 spécifiques au lieu de A générique).
- **Scaling progressif via flag `isActive`** (cf. [ADR-015](./ADR-015-catalogue-firestore-runtime-activation.md)) : TVEE + sous-séries ABI/SH/AC/TI activables post-validation enseignant sans cycle de release mobile.
- **Pattern Firestore-driven préservé** : aucune nouvelle source de vérité runtime, cohérent ADR-015.
- **Non-breaking pour profils v1 existants** : defaults safe `pickerMode: 'derived'` + série A conservée `isActive: false` + nouveaux champs optionnels. Fatou (Tle D) et James (Upper Sixth S2) continuent à fonctionner sans intervention.
- **Pattern uniforme `pickerMode`** facilite l'ajout futur de nouveaux modes (ex. mode `weighted_picker` pour BAC avec coefficients) sans casser l'existant.

**Négatives**

- **SerieChoicePage charge mentale +200% en Tle Franco** : 12 cards vs 4 cards v1. Mitigation : groupement visuel famille (Story 1.14) + scroll vertical attendu sur Pixel 4a, tablet 2 colonnes. À surveiller en test utilisateur Aïssatou.
- **matrice.json +60% volumétrie** : ~130 documents v2 vs 79 v1 (sous-séries + matières manquantes + TVEE complet). Acceptable (script Python idempotent, run en quelques secondes).
- **Cumul Epic 1 +31-36h effort** (cf. sprint-change-proposal-2026-06-09.md) : 8 nouvelles stories sur ~3 semaines calendaires post-1.10.
- **Tests +30-40 nouveaux cas** : validation panier, parsing nouvelles règles, widgets pickers polymorphes, TVEE flow. Cumul baseline 205 → cible Epic 1 v2 ~245-250.
- **Dépendance soft validation enseignant TVEE** : pour activer runtime les 13 spécialités TVEE après seed initial `isActive: false`. Acceptable (l'app reste utilisable sans TVEE actif, l'élève technique anglo voit "filière non disponible" jusqu'à activation).
- **Champ `users/{uid}.pickedSubjects` optionnel ambigu** : profils v1 n'ont pas ce champ. Story 1.15 doit gérer le cas absent (pas de panier = `derivedSubjects \ optedOutSubjects` legacy).

## Out of scope ADR-016 (post-MVP)

Les nomenclatures officielles documentent aussi (cf. doc utilisateur 2026-06-09 § 7) :

- **Franco technique étendu** : F6/F7/F8 (Génie Chimique BIPE/COPH/MIPE, Sciences Biologiques Biolo/Bioch, Sciences Sanitaires F8), AF1/AF2/AF3 (Artistiques : Céramique, Peinture, Sculpture)
- **Franco BT/BP/BEP** : Brevet de Technicien, Brevet Professionnel, Brevet d'Études Professionnelles — 30+ spécialités (Hôtellerie HO-HE/HO-RB/HO-CU, Tourisme TO-AAT/TO-AV, Économie Sociale ESF, Bijouterie BIJO, Géomètre topographe GT, etc.)
- **Franco STT raffiné** : ACA / CG / ACC / FIG / SES (le mapping v1 actuel G1/G2/G3 est approximatif vs la nomenclature officielle Office du Bac)
- **TVE Professional Certificate Examination (PCE)** : examen pro additionnel anglophone non couvert

**Décision PO 2026-06-09** : **out of scope MVP**. Peuvent être ajoutés progressivement post-MVP via re-run script seed avec matrice étendue, **sans cycle de release mobile** (cohérent avec ADR-015). Les filières STT francophone G1/G2/G3 actuelles sont conservées telles quelles pour MVP — refactor ACA/CG/ACC potentiel en post-MVP.

## Décisions liées

- [ADR-015](./ADR-015-catalogue-firestore-runtime-activation.md) — Catalogue Firestore + activation runtime. ADR-016 étend cette base sans la remettre en cause.
- [ADR-003](./ADR-003-firebase-full-backend.md) — Firebase full backend. Le panier polymorphe consomme exclusivement Firestore, aucun nouveau stack.
- [ADR-006](./ADR-006-subsystem-fixed-at-signup.md) — Sous-système figé à l'inscription. ADR-016 respecte : un élève anglophone qui choisit la filière technique TVEE reste anglophone.
- [ADR-001](./ADR-001-flutter-clean-architecture.md) — Clean Architecture. `SubjectsPickerPage` polymorphe (Story 1.15) suit le pattern : domain (`PickerMode` enum) → data (mapping Firestore) → presentation (widget body switch).
- [sprint-change-proposal-2026-06-09.md](../../sprint-change-proposal-2026-06-09.md) — décision PO motivante de cette ADR.

## Sources autoritaires

- [Office du Baccalauréat camerounais](https://officedubac.cm/) — Nomenclature des examens ESG + ESTP francophone (séries A1-A5/ABI/SH/AC/TI + F1-F8 + AF + G1-G3 + BT/BP/BEP)
- [Cameroon GCE Board](https://camgceb.org/) — Syllabus O-Level (21 codes 0505-0595) + A-Level (20 codes 0705-0796) + TVEE (TVE IL + TVE AL + spécialités)
- [Cameroon GCE Revision — Lower Sixth Series Arts & Science](https://cameroongcerevision.com/lower-sixth-series-arts-and-science/) — Combinaisons A-Level Series officielles
- Doc utilisateur 2026-06-09 « Orientation et matières au secondaire camerounais » — Synthèse complète sources officielles

## Acteurs

- **PO** : Delano Roosvelt (décisions sprint change 2026-06-09 via AskUserQuestion)
- **Architecte / PM agent** : Claude Opus 4.7 (via `/bmad-correct-course` puis `/bmad-create-story` puis `/bmad-dev-story`)
- **Backend** : à approuver async sur PR Story 1.11a (CLAUDE.md règle § doc/partage) — 6 nouveaux champs Firestore catalogue + 1 champ `users/{uid}`
- **Enseignant TVEE** : Mr Eboa Joseph (Lycée Technique Bonabéri) — à consulter post-merge Story 1.17 pour valider matières exactes par spécialité TVE IL/AL avant activation `isActive: true` runtime

## Détail d'implémentation

Voir :
- [BASE-DE-DONNEES.md § Catalogue scolaire v2 — Story 1.11a](../../../../doc/partage/BASE-DE-DONNEES.md#catalogue-scolaire-6-collections--story-11a) — schéma TypeScript v2 (6 nouveaux champs catalogue + 1 champ `users/{uid}`)
- [DONNEES-REFERENCE.md v2 — Story 1.11a](../../../../doc/partage/DONNEES-REFERENCE.md) — matrice exhaustive v2 (sous-séries + matières manquantes + TVEE)
- [ALGORITHMES.md § 1 v2 — Story 1.11a](../../../../doc/partage/ALGORITHMES.md#1-d%C3%A9rivation-profil--mati%C3%A8res--examens) — algo `derive()` enrichi (DerivedProfile v2)
- Story 1.12 — matrice.json + re-seed Firestore valide-edu
- Story 1.13 — DerivedProfile v2 pickerMode (non-breaking via defaults safe)
- Story 1.14 — Sous-séries Tle franco flat (SerieChoicePage 12 cards + groupement)
- Story 1.15 — Refactor SubjectsPickerPage polymorphe + mode `free_with_obligatory` O-Level
- Story 1.16 — Mode `series_plus_optional` A-Level transversales
- Story 1.17 — Sous-système ESTP TVEE anglophone (filière technique + niveaux + 13 spécialités)
