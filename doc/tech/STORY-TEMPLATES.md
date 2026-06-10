# Templates de story BMAD — Valide School

> **Pourquoi** : industrialiser les sections critiques d'une story (Dev Notes, cost-benefit Firestore, stratégie responsive) pour éviter qu'elles soient sautées ou bâclées. Templates issus des apprentissages rétro Epic 1 v2 (Challenges 5 et 6 + Action Items A4 et A9).

> **Comment utiliser** : copier le bloc concerné dans le fichier story `*-*-*.md` lors de l'étape contexte (`bmad-create-story`) et le compléter avec les valeurs réelles avant push.

---

## Sommaire

- [1. Template Dev Notes condensé (A4)](#1-template-dev-notes-condensé-a4)
- [2. Template cost-benefit Firestore (A9, opérationnalise CLAUDE.md règle 10m)](#2-template-cost-benefit-firestore-a9-opérationnalise-claudemd-règle-10m)
- [3. Template stratégie responsive (durcissement règles 3/5)](#3-template-stratégie-responsive-durcissement-règles-35)
- [4. Template composants réutilisables (règle 11)](#4-template-composants-réutilisables-règle-11)

---

## 1. Template Dev Notes condensé (A4)

**Avant** : ~250 lignes par story (verbosity Stories 1.13 → 1.17).
**Cible** : ≤ 80 lignes structurées, focus sur le « pourquoi » et les décisions, pas le « quoi ».

### Bloc à copier dans la story file

````markdown
## Dev Notes

### Contexte et motivation
<2-4 phrases : pourquoi cette story maintenant, quel persona/critère métier sert-elle, sur quoi elle s'appuie (story précédente, ADR, SCP).>

### Décisions techniques clés
- **Décision 1** : <choix> — **raison** : <pourquoi> — **alternative écartée** : <option B + raison du refus>
- **Décision 2** : <idem>
- (Maximum 5 décisions. Au-delà, c'est un signe que la story est trop large — découper.)

### Modèle de données / API impactés
- Fichiers `domain/*.dart` : <ajout/modif schématique>
- Fichiers `data/*_repository_impl.dart` : <ajout/modif schématique>
- Schéma Firestore : <renvoi à BASE-DE-DONNEES.md si modif>
- Contrats Cloud Function : <renvoi à CONTRATS-API.md si modif>

### Cost-benefit Firestore
<Voir Template 2 ci-dessous — REQUIS si la story introduit une collection, un index composite, un snapshots() ou une dénormalisation, sinon "N/A pour cette story".>

### Stratégie responsive
<Voir Template 3 ci-dessous — REQUIS si la story ajoute/modifie un écran, sinon "N/A pour cette story".>

### Composants réutilisables
<Voir Template 4 ci-dessous — REQUIS si la story ajoute un widget, sinon "N/A pour cette story".>

### Tests à écrire
- Unit : <liste 3-5 cas (succès + ≥ 1 échec)>
- Widget : <liste 1-3 widget tests + ≥ 1 golden test breakpoint tablet si écran ajouté>
- Integration (si applicable) : <liste>

### Anti-patterns à éviter
- <Lessons learned issues des rétros / stories précédentes pertinentes pour ce périmètre>
- <Pièges identifiés par Architect / UX lors du cadrage>

### Références
- [Story d'origine en cas d'extension] : `<X.Y>`
- [Doc tech] : `<path>`
- [Doc partage] : `<path>` (si Firestore / contrat impacté)
````

### Anti-patterns Dev Notes (à éviter)

- ❌ Recopier les Acceptance Criteria dans Dev Notes (déjà au-dessus)
- ❌ Lister tous les imports nécessaires (un dev compétent les déduit du code)
- ❌ Décrire l'algorithme ligne par ligne (le code documente le code)
- ❌ Inclure un Mermaid de l'architecture entière à chaque story (1× max par epic, dans `doc/tech/`)
- ❌ Citer un commit antérieur sans hash explicite (utiliser des permalinks GitHub si vraiment nécessaire)

---

## 2. Template cost-benefit Firestore (A9, opérationnalise CLAUDE.md règle 10m)

**Quand** : OBLIGATOIRE si la story introduit (a) une nouvelle collection, (b) un nouvel index composite, (c) un nouveau `snapshots()`, (d) une dénormalisation, (e) une requête `collectionGroup`. Sinon : « N/A pour cette story ».

### Bloc à copier dans la story file (section « Cost-benefit Firestore » du Template 1)

````markdown
### Cost-benefit Firestore

**Type d'impact** : <collection nouvelle / index composite nouveau / snapshots() nouveau / dénormalisation / collectionGroup>

**Reads / écriture par session utilisateur moyenne** :
- Lecture : <nombre> reads par session (détail : <quelles requêtes>)
- Écriture : <nombre> writes par session (détail : <quels champs touchés>)
- Latence cible : <X ms> sur réseau 3G dégradé (cf. NFR-X du PRD si applicable)

**Volumétrie estimée à 10 000 utilisateurs** :
- Documents totaux dans la collection après 10k users : <estimation>
- Reads/jour pour la fonctionnalité : <estimation>
- Coût mensuel estimé Firestore : <calcul rapide à partir du pricing>

**Trade-off accepté vs alternative écartée** :
- **Alternative A (écartée)** : <description> — **raison du refus** : <pourquoi>
- **Choix retenu** : <description> — **bénéfice principal** : <pourquoi c'est mieux>

**Check CLAUDE.md règle 10 sous-règles** :
- [ ] (a) Modélisé par requête (1-3 reads par écran cible)
- [ ] (b) Dénormalisation préférée à jointure si applicable
- [ ] (c) `limit(N)` explicite sur toute requête `collection().get()`
- [ ] (d) Préfiltré côté serveur via `.where(...)`
- [ ] (e) `arrayContains` si liste < 10 éléments
- [ ] (g) `snapshots()` justifié (data mutable pendant session) ou `.get()` (data statique avec cache offline)
- [ ] (i) `count()` server-side si compteur
- [ ] (k) Lecture par ID préférée si possible
- [ ] (l) `update()` / `set(merge: true)` pour modifs partielles

**Anti-patterns évités** (cocher les anti-patterns réellement évités) :
- [ ] Pas de lecture collection sans `limit()`
- [ ] Pas de `snapshots()` sur catalogue statique
- [ ] Pas de filtrage côté Dart de ce qui peut être filtré Firestore
- [ ] Pas de N+1 reads
- [ ] Pas de réécriture doc entier pour modifier 1 champ
- [ ] Pas d'`offset()` pour pagination
- [ ] Pas de blob > 10 KB dans doc listé en grille
````

### Exemple concret (Story 1.13)

````markdown
### Cost-benefit Firestore

**Type d'impact** : extension `derive()` de 5 à 7 futures Future.wait (lectures `subjects/{subjectId}` supplémentaires pour Pro/Related/Other TVE)

**Reads / écriture par session utilisateur moyenne** :
- Lecture : +2-6 reads `subjects/{id}` pendant onboarding (one-shot, varie selon série choisie)
- Écriture : 0 (pas de mutation Firestore)
- Latence cible : < 800 ms total derive() sur 3G dégradé (1 RTT serieFuture + 1 RTT Future.wait 7)

**Volumétrie estimée à 10 000 utilisateurs** :
- 10k onboardings × ~5 reads = 50k reads ponctuels au total (one-shot)
- Coût mensuel : négligeable (cache offline pour reconnexions)

**Trade-off accepté vs alternative écartée** :
- **Alternative A (écartée)** : 1 seul Future.wait 8 futures avec serieFuture inclus — **raison du refus** : on a besoin du résultat serieDoc pour construire les 3 nouvelles futures Pro/Related/Other (chaînage)
- **Choix retenu** : await serieFuture standalone puis Future.wait 7 — **bénéfice** : simplicité + cohérence avec les autres derive() précédents

(Check sous-règles + anti-patterns évités cochés ici)
````

---

## 3. Template stratégie responsive (durcissement règles 3/5)

**Quand** : OBLIGATOIRE si la story ajoute ou modifie un écran (un fichier dans `lib/features/**/presentation/*_page.dart` ou un widget plein-écran dans `lib/core/widgets/`). Sinon : « N/A pour cette story ».

### Bloc à copier dans la story file (section « Stratégie responsive » du Template 1)

````markdown
### Stratégie responsive

**Form factors cibles** :
- Phone portrait (< 600 dp) : OUI — comportement : <description>
- Phone landscape (600-840 dp) : <OUI / OPTIONNEL / NON (justification)>
- Tablet portrait & landscape (≥ 840 dp) : OUI — comportement : <description : 2 colonnes, side panel, etc.>

**Breakpoints à utiliser** :
- `LayoutBuilder` sur `<widget root>` avec seuil à 600 dp et 840 dp
- OU `MediaQuery.sizeOf(context).width` comparé aux constantes `kBreakpointPhone` (600), `kBreakpointTablet` (840) — à définir dans `core/theme/tokens.dart` si pas déjà fait

**Layout strategy par form factor** :
- Phone < 600 dp : <colonne unique scrollable / liste verticale>
- Phone landscape 600-840 dp : <colonne unique avec padding latéral / split layout si pertinent>
- Tablet ≥ 840 dp : <2 colonnes / side panel + content / grid si liste>

**Golden tests à inclure** (≥ 1 viewport ≥ 840 dp obligatoire — règle 5) :
- [ ] Golden test phone portrait (375×812)
- [ ] Golden test tablet portrait (768×1024) — minimum pour Story conforme règle 5
- [ ] (Optionnel) Golden test tablet landscape (1024×768)
- [ ] (Optionnel) Golden test phone landscape (812×375)

**Acceptance Criteria responsive à ajouter à la story** :
- « Le widget X s'affiche correctement en tablette portrait sans gaspillage d'espace horizontal — vérifié par golden test au breakpoint 840 dp. »
````

### Anti-patterns à éviter

- ❌ Colonne unique pleine largeur sur tablette (gaspillage espace horizontal)
- ❌ Dimensions en pixels en dur (utiliser `.w` / `.h` / `.sp` de `flutter_screenutil` ou des `MediaQuery` ratios)
- ❌ Golden test uniquement phone (Story livrée sans test tablet = renvoyée)
- ❌ `Platform.isAndroid` / `Platform.isIOS` dans la couche `presentation` (CLAUDE.md règle 1 Cross-platform)

---

## 4. Template composants réutilisables (règle 11)

**Quand** : OBLIGATOIRE si la story ajoute un widget. Sinon : « N/A pour cette story ».

### Bloc à copier dans la story file (section « Composants réutilisables » du Template 1)

````markdown
### Composants réutilisables

**Catalogue consulté** : [doc/tech/COMPOSANTS-REUTILISABLES.md](../../doc/tech/COMPOSANTS-REUTILISABLES.md)

**Composants existants réutilisés** :
- `ComponentNameA` (path `lib/core/widgets/.../component_a.dart`) — usage : <où dans la story>
- `ComponentNameB` (path `lib/core/widgets/.../component_b.dart`) — usage : <où dans la story>
- (Si aucun composant réutilisé, écrire « Aucun composant existant ne couvre ce besoin »)

**Composants existants adaptés (paramètre optionnel ajouté)** :
- `ComponentNameA` reçoit nouveau paramètre `optionalProp: Type?` — raison : <justification>
- (Si aucune adaptation, écrire « Aucune »)

**Nouveaux composants créés et ajoutés au catalogue** :
- `NewComponentName` (path `lib/core/widgets/.../new_component.dart`) — entrée catalogue ajoutée dans la même PR
- (Si aucun nouveau composant, écrire « Aucun »)

**Vérification anti-duplication** :
- [ ] Aucune classe privée `_XxxBody` reproduisant un composant existant
- [ ] Si adaptation mineure : paramètre optionnel ajouté au composant existant (pas duplication)
- [ ] Si nouveau composant : entrée catalogue présente dans la PR
````

### Exemple concret (Story 1.18 — refactor extractif)

````markdown
### Composants réutilisables

**Catalogue consulté** : [doc/tech/COMPOSANTS-REUTILISABLES.md](../../doc/tech/COMPOSANTS-REUTILISABLES.md) — section « À extraire — dette Epic 1 v2 »

**Composants existants réutilisés** :
- Aucun (story de création des composants partagés)

**Composants existants adaptés** :
- Aucun

**Nouveaux composants créés et ajoutés au catalogue** :
- `PickerSectionCard` (path `lib/core/widgets/picker/picker_section_card.dart`)
- `ObligatorySubjectChipList` (path `lib/core/widgets/picker/obligatory_subject_chip_list.dart`)
- `OptionalSubjectChipGrid` (path `lib/core/widgets/picker/optional_subject_chip_grid.dart`)
- `PickerValidateBar` (path `lib/core/widgets/picker/picker_validate_bar.dart`)
- `PickerToastFeedback` (path `lib/core/widgets/feedback/picker_toast_feedback.dart`)

**Vérification anti-duplication** :
- [x] Anciens `_LegacyOptOutBody` / `_FreeWithObligatoryBody` / `_SeriesPlusOptionalBody` / `_TvePickerBody` supprimés de `subjects_picker_page.dart`
- [x] Entrée catalogue ajoutée pour chaque composant extrait
````

---

## Maintenance des templates

Quand un template évolue (nouveau pattern post-rétro), incrémenter la version implicite via section « Historique » et linker la PR.

| Date | Évolution | PR | Auteur |
|---|---|---|---|
| 2026-06-10 | Création initiale (A4 Dev Notes condensé + A9 cost-benefit Firestore + responsive + composants) | PR discipline-composants-responsive | Amelia |
