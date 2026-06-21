---
baseline_commit: da44d90
---

# Story 2.1 : Schéma Firestore contenu pédagogique + seed Python démo

Status: done

## Story

En tant qu'équipe de développement,
je veux définir le schéma Firestore des collections de contenu pédagogique (`chapters`, `lessons`, `notions`) et seeder 2 matières de démonstration (Mathématiques Tle D francophone + Physics Upper Sixth anglophone),
afin que les stories 2.2 et 2.3 (UI navigation + lecteur) puissent fonctionner avec de vraies données Firebase et que le lecteur `PedagogicalContent` soit validé sur du contenu réel (LaTeX + Mermaid).

## Acceptance Criteria

1. **AC1 — Schéma documenté** : `doc/partage/BASE-DE-DONNEES.md` contient les schémas TypeScript complets et à jour pour `ChapterDoc`, `LessonDoc`, `NotionDoc`. Les statuts passent de 🟡 à 🟢 après seed. La section Historique est mise à jour.

2. **AC2 — Indexes Firestore déclarés** : `firestore.indexes.json` (racine du repo) contient les 3 index composites requis :
   - `chapters` : `(subjectId ASC, order ASC)`
   - `lessons` : `(chapterId ASC, order ASC)`
   - `notions` : `(lessonId ASC, order ASC)`
   Et sont déployés sur `valide-edu` via `firebase deploy --only firestore:indexes`.

3. **AC3 — Règles Firestore étendues** : `firestore.rules` (racine) couvre les 3 nouvelles collections :
   - `chapters`, `lessons`, `notions` : `read` si `request.auth != null` ; `write` = `false` (admin uniquement)
   - Déployé sur `valide-edu`.
   - `npm test` (test/rules/) = 0 régression + ≥ 3 nouveaux tests (read auth OK, read unauth KO, write KO).

4. **AC4 — Script seed créé** : `scripts/firebase_seed/seed_content.py` respecte le pattern seed_catalogue.py (argparse `--project` / `--dry-run` / `--data` / `--credentials`, `set(merge=True)` idempotent, validation référentielle cross-collection, log timing).

5. **AC5 — Données démo versionées** : `scripts/firebase_seed/data/content_demo.json` contient ≥ 2 matières × ≥ 2 chapitres × ≥ 2 leçons × ≥ 2 notions. Le `content.fr` d'au moins une leçon contient : un titre H2, un paragraphe, une formule LaTeX bloc (`$$...$$`), une formule inline (`$...$`), et un diagramme Mermaid. Idem en `content.en`.

6. **AC6 — Seed exécuté sur valide-edu** : Seed réel exécuté et vérifié dans Firebase Console (`chapters/`, `lessons/`, `notions/` peuplés, ≥ 8 chapters, ≥ 16 lessons, ≥ 32 notions). L'idempotence est confirmée (2ème run = 0 erreur, 0 doublon).

7. **AC7 — Tests pytest** : `pytest scripts/firebase_seed/tests/test_seed_content.py` = vert, ≥ 6 tests (validation structure JSON, validation champs requis, idempotence mock, dry-run, cross-ref subjectId, ordre séquentiel).

8. **AC8 — README mis à jour** : `scripts/firebase_seed/README.md` inclut une section `seed_content.py` avec commande de lancement et description du jeu de données démo.

## Tasks / Subtasks

- [x] **T1 — Finaliser et documenter les schémas Firestore** (AC1)
  - [x] T1.1 Vérifier les schémas `ChapterDoc` / `LessonDoc` / `NotionDoc` dans `BASE-DE-DONNEES.md` — corriger si besoin (champs, types, nullable)
  - [x] T1.2 Mettre à jour les statuts 🟡 → 🟢 pour chapters/lessons/notions dans `BASE-DE-DONNEES.md`
  - [x] T1.3 Ajouter section Historique `2026-06-21 — Story 2.1` dans `BASE-DE-DONNEES.md`

- [x] **T2 — Indexes Firestore** (AC2)
  - [x] T2.1 Ajouter les 3 index composites dans `firestore.indexes.json` (racine)
  - [x] T2.2 Déployer : `firebase deploy --only firestore:indexes --project valide-edu`
  - [x] T2.3 Vérifier dans Firebase Console que les 3 indexes sont ENABLED

- [x] **T3 — Règles Firestore** (AC3)
  - [x] T3.1 Ajouter les 3 blocs `match /chapters/{id}`, `match /lessons/{id}`, `match /notions/{id}` dans `firestore.rules`
  - [x] T3.2 Écrire ≥ 3 tests dans `test/rules/` (read auth ✅, read unauth ❌, write ❌)
  - [x] T3.3 `npm test` dans `test/rules/` = vert (0 régression)
  - [x] T3.4 Déployer : `firebase deploy --only firestore:rules --project valide-edu`

- [x] **T4 — Données démo JSON** (AC5)
  - [x] T4.1 Créer `scripts/firebase_seed/data/content_demo.json` avec structure hiérarchique (voir Dev Notes pour le schéma JSON)
  - [x] T4.2 Seed Mathématiques Tle D : 4 chapitres × 2 leçons × 2 notions (content FR + EN avec LaTeX + Mermaid dans ≥ 1 leçon)
  - [x] T4.3 Seed Physics Upper Sixth : 4 chapitres × 2 leçons × 2 notions (content FR + EN)
  - [x] T4.4 Valider manuellement le JSON (syntaxe + cross-refs subjectId existants en Firestore)

- [x] **T5 — Script `seed_content.py`** (AC4)
  - [x] T5.1 Créer `scripts/firebase_seed/seed_content.py` sur le modèle de `seed_catalogue.py`
  - [x] T5.2 Ordre de seed : chapters → lessons → notions (respect des dépendances)
  - [x] T5.3 Validation référentielle : `chapter.subjectId` doit exister dans collection `subjects` Firestore
  - [x] T5.4 Dry-run : `python seed_content.py --project valide-edu --dry-run` affiche ce qui serait écrit
  - [x] T5.5 Vérifier que le script n'écrit jamais dans les collections catalogue (filieres, niveaux, etc.)

- [x] **T6 — Tests pytest** (AC7)
  - [x] T6.1 Créer `scripts/firebase_seed/tests/test_seed_content.py`
  - [x] T6.2 Tests : structure JSON valide, champs requis présents, cross-ref subjectId, ordre ascendant, dry-run aucune écriture, idempotence (mock Firestore)
  - [x] T6.3 `pytest tests/test_seed_content.py` = 10/10 vert

- [x] **T7 — Seed réel sur valide-edu** (AC6)
  - [x] T7.1 `python seed_content.py --project valide-edu` (avec ADC)
  - [x] T7.2 Vérifier dans Firebase Console : collections chapters/lessons/notions peuplées
  - [x] T7.3 Run seed 2ème fois — confirmer idempotence (0 erreur)
  - [x] T7.4 Logger le timing du seed dans Completion Notes

- [x] **T8 — Documentation** (AC8)
  - [x] T8.1 Ajouter section `seed_content.py` dans `scripts/firebase_seed/README.md`
  - [x] T8.2 Ajouter section `data/content_demo.json` dans `scripts/firebase_seed/data/README.md`

## Dev Notes

### Contexte Epic 2 — Workflow UI-first

Cette story est 100% **docs + data** : aucun code Flutter. Elle débloque :
- **Story 2.2** (navigation UI) qui pourra afficher les vrais chapters/lessons/notions une fois l'intégration faite
- **Story 2.3** (lecteur) qui testera `PedagogicalContent` avec du vrai contenu LaTeX + Mermaid

**Règle UI-first (porteur produit, 2026-06-21)** : Les stories 2.2 et 2.3 démarreront avec données hardcodées. Après validation UI par le porteur, l'intégration Firestore (Story 2.4) remplacera TOUT le code hardcodé. Le seed produit ici servira directement à Story 2.4.

---

### Schéma Firestore cible

**Source autoritaire** : `doc/partage/BASE-DE-DONNEES.md` (déjà documenté 🟡, à passer 🟢 après seed).

```typescript
// chapters/{chapterId}
interface ChapterDoc {
  chapterId: string;          // = doc ID, ex. "franco_math_ch01"
  subjectId: string;          // ref subjects/{id} — doit exister
  order: number;              // 1, 2, 3... (tri ascendant)
  title: { fr: string; en: string };
  description: { fr: string; en: string } | null;
}

// lessons/{lessonId}
interface LessonDoc {
  lessonId: string;           // ex. "franco_math_ch01_l01"
  chapterId: string;          // ref chapters/{id}
  order: number;
  title: { fr: string; en: string };
  content: { fr: string; en: string };  // Markdown + LaTeX + Mermaid
}

// notions/{notionId}
interface NotionDoc {
  notionId: string;           // ex. "franco_math_ch01_l01_n01"
  lessonId: string;           // ref lessons/{id}
  order: number;
  title: { fr: string; en: string };
}
```

**Pas de champ `isActive`** sur chapters/lessons/notions (contrairement aux subjects du catalogue). Le contenu est activé par le simple fait d'être seedé. Décision : simplicité MVP, l'admin supprime via Console si besoin de cacher.

---

### Structure JSON du fichier `content_demo.json`

```json
{
  "subjects": [
    {
      "subjectId": "<id existant en Firestore — vérifier>",
      "chapters": [
        {
          "chapterId": "franco_math_ch01",
          "order": 1,
          "title": { "fr": "Limites et continuité", "en": "Limits and Continuity" },
          "description": { "fr": "...", "en": "..." },
          "lessons": [
            {
              "lessonId": "franco_math_ch01_l01",
              "order": 1,
              "title": { "fr": "Définition d'une limite", "en": "Definition of a Limit" },
              "content": {
                "fr": "## Définition\n\nOn dit que $f(x)$ admet pour **limite** $L$ en $a$ si :\n\n$$\\lim_{x \\to a} f(x) = L$$\n\n### Exemple\n\nPour $f(x) = x^2$, calculons $\\lim_{x \\to 2} f(x)$ :\n\n$$\\lim_{x \\to 2} x^2 = 4$$\n\n### Représentation\n\n```mermaid\ngraph LR\n  A[x approche a] --> B{f(x) approche L?}\n  B -->|Oui| C[Limite L existe]\n  B -->|Non| D[Limite n'existe pas]\n```",
                "en": "## Definition\n\nWe say $f(x)$ has **limit** $L$ at $a$ if:\n\n$$\\lim_{x \\to a} f(x) = L$$\n\n### Example\n\nFor $f(x) = x^2$, compute $\\lim_{x \\to 2} f(x)$:\n\n$$\\lim_{x \\to 2} x^2 = 4$$\n\n### Diagram\n\n```mermaid\ngraph LR\n  A[x approaches a] --> B{f(x) approaches L?}\n  B -->|Yes| C[Limit L exists]\n  B -->|No| D[Limit does not exist]\n```"
              },
              "notions": [
                {
                  "notionId": "franco_math_ch01_l01_n01",
                  "order": 1,
                  "title": { "fr": "Limite finie en un point", "en": "Finite Limit at a Point" }
                },
                {
                  "notionId": "franco_math_ch01_l01_n02",
                  "order": 2,
                  "title": { "fr": "Limite à l'infini", "en": "Limit at Infinity" }
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

**Conventions d'IDs** : `{subSystem_abbrev}_{subject_abbrev}_ch{NN}` pour chapters, `_l{NN}` pour lessons, `_n{NN}` pour notions. Tout en minuscules, underscores. Ex. `franco_math_ch01_l02_n01`.

**⚠️ Action porteur avant T4** : vérifier les vrais `subjectId` disponibles dans `subjects/` sur Firebase Console valide-edu (le seed catalogue Story 1.1b a créé ces IDs — les utiliser tels quels dans `content_demo.json`).

---

### Indexes Firestore à ajouter dans `firestore.indexes.json`

```json
{
  "collectionGroup": "chapters",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "subjectId", "order": "ASCENDING" },
    { "fieldPath": "order", "order": "ASCENDING" }
  ]
},
{
  "collectionGroup": "lessons",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "chapterId", "order": "ASCENDING" },
    { "fieldPath": "order", "order": "ASCENDING" }
  ]
},
{
  "collectionGroup": "notions",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "lessonId", "order": "ASCENDING" },
    { "fieldPath": "order", "order": "ASCENDING" }
  ]
}
```

Ces 3 indexes couvrent les requêtes `.where('subjectId', isEqualTo: id).orderBy('order')` que ContentRepository utilisera en Story 2.4.

---

### Règles Firestore à ajouter dans `firestore.rules`

```firestore
match /chapters/{chapterId} {
  allow read: if request.auth != null;
  allow write: if false;
}
match /lessons/{lessonId} {
  allow read: if request.auth != null;
  allow write: if false;
}
match /notions/{notionId} {
  allow read: if request.auth != null;
  allow write: if false;
}
```

**Pas de vérification `profileComplete`** sur le contenu pour l'instant — le profil complet est géré côté Flutter (guard du router Story 1.5). Simplification MVP : tout user authentifié peut lire (y compris visiteur anonyme).

---

### Pattern `seed_content.py` — Points clés

Calquer `seed_catalogue.py` (Story 1.1b) :
- `DEFAULT_DATA_PATH = Path(__file__).resolve().parent / "data" / "content_demo.json"`
- Ordre de seed obligatoire : **chapters d'abord**, puis **lessons**, puis **notions** (dépendances référentielles)
- Validation cross-collection avant écriture : vérifier que `chapter.subjectId` existe dans la liste des `subjectId` de la collection `subjects` Firestore (GET collection subjects + cache local)
- `set(payload, merge=True)` sur chaque document (idempotence)
- `SERVER_TIMESTAMP` sur `createdAt` (préservé par `merge=True` si doc existe déjà)
- Le script ne touche PAS aux collections du catalogue (filieres, niveaux, series, subjects, derivation_rules) — scope strict

```python
def _seed_content(db, data: dict, dry_run: bool) -> None:
    for subject_entry in data["subjects"]:
        subject_id = subject_entry["subjectId"]
        for chapter in subject_entry.get("chapters", []):
            chapter_id = chapter["chapterId"]
            chapter_payload = {
                "subjectId": subject_id,
                "order": chapter["order"],
                "title": chapter["title"],
                "description": chapter.get("description"),
                "createdAt": SERVER_TIMESTAMP,
            }
            if not dry_run:
                db.collection("chapters").document(chapter_id).set(chapter_payload, merge=True)
            for lesson in chapter.get("lessons", []):
                # ... (même pattern)
                for notion in lesson.get("notions", []):
                    # ... (même pattern)
```

---

### Données démo recommandées

**Matière 1 — Mathématiques Tle D (francophone)**
- Ch01 : Limites et continuité → L01 : Définition d'une limite → N01 : Limite finie / N02 : Limite à l'infini
- Ch01 → L02 : Théorèmes sur les limites → N01 : Théorème des gendarmes / N02 : Opérations sur les limites
- Ch02 : Dérivation → L01 : Nombre dérivé → N01 : Définition / N02 : Interprétation géométrique
- Ch02 → L02 : Dérivées usuelles → N01 : Tableau des dérivées / N02 : Règles de dérivation

**Matière 2 — Physics Upper Sixth (anglophone)**
- Ch01 : Mechanics → L01 : Newton's Laws → N01 : First Law (Inertia) / N02 : Second Law (F=ma)
- Ch01 → L02 : Energy → N01 : Kinetic Energy / N02 : Conservation of Energy
- Ch02 : Waves → L01 : Wave Properties → N01 : Frequency and Period / N02 : Wave Equation
- Ch02 → L02 : Interference → N01 : Constructive Interference / N02 : Destructive Interference

Total : 8 chapters, 16 lessons, 32 notions. Au moins 1 leçon par matière contient LaTeX + Mermaid.

---

### Références

- [Source: doc/partage/BASE-DE-DONNEES.md — Collections chapters/lessons/notions]
- [Source: doc/partage/BASE-DE-DONNEES.md — Firestore Indexes 🔴 à compléter]
- [Source: scripts/firebase_seed/seed_catalogue.py — Pattern réutilisé]
- [Source: scripts/firebase_seed/seed_schools.py — Pattern réutilisé]
- [Source: project_manage/planning-artifacts/epics.md — Epic 2, FR-9/FR-11/FR-14/FR-15]
- [Source: project_manage/planning-artifacts/prds/prd-valide-mvp-2026-06-03/prd.md — §4.2 FR-9 à FR-15]
- [Source: CLAUDE.md — Règle 9 indexes Firestore + Règle 10 modélisation Firestore]

### Cost-benefit Firestore (CLAUDE.md règle 10m)

- **Reads par session** : ~1 read chapters par matière ouverte + ~1 read lessons par chapitre + ~1 read notions par leçon. Navigation 2 niveaux profonds = ~3 reads. Tous mis en cache offline après premier chargement.
- **Volumétrie @10 000 users** : si 1000 sessions/jour × 3 reads moyens = 3000 reads/jour. Avec cache offline (NFR-5), <10% de ces sessions refont un GET réseau. Coût réel : ~300 reads réseau/jour pour 1000 sessions.
- **Trade-off** : Structure 3 collections séparées (vs tout dans `subjects`) → requêtes ciblées `where('subjectId')` + cache granulaire par leçon. Alternative tout-en-un (champs imbriqués dans `subjects`) violait la règle 10j (blobs lourds dans doc listé en grille).

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (2026-06-21)

### Debug Log References

- Firestore rules: 1ère tentative d'edit `firestore.rules` a échoué (accents `école` vs ASCII `ecole`) — résolu en lisant l'exact texte ligne 170-172 avant l'edit.
- npm tests (a),(c),(d) failing avant déploiement rules : les reads content étaient bloqués par la règle deny-all. Résolu en déployant rules d'abord (`firebase deploy --only firestore:rules`), puis re-run npm test → 6/6 pass.
- 4 tests npm pre-existants en échec (non liés à Story 2.1) : `schools.test.mjs (b)`, `users.test.mjs (e)(k)(m)`. Non introduits par cette story — zéro régression.

### Completion Notes List

- T4 : données démo étendues à 4 chapitres/matière (vs 2 prévu) pour atteindre AC6 ≥ 8 chapters total.
- T6 : 10 tests (vs ≥ 6 requis par AC7) — couvre en plus test bilingue non vide et _validate_bilingual_field.
- T7 : Seed run 1 = 11.25 s, run 2 (idempotence) = 15.52 s. 56 docs total (8 chapters + 16 lessons + 32 notions). Validation cross-collection réussie : 2 subjectId vérifiés en Firestore.
- Règles Firestore : `read: if request.auth != null` (pas de guard `profileComplete` côté Firestore — guard géré côté Flutter router Story 1.5 pour simplifier MVP et éviter permission-denied au prefetch boot).
- Pas de champ `isActive` sur chapters/lessons/notions (contrairement au catalogue) — MVP, admin supprime via Console si besoin.

### File List

**Créés :**
- `scripts/firebase_seed/seed_content.py`
- `scripts/firebase_seed/data/content_demo.json`
- `scripts/firebase_seed/tests/test_seed_content.py`
- `test/rules/content.test.mjs`

**Modifiés :**

- `doc/partage/BASE-DE-DONNEES.md` (schémas 🟡→🟢 + indexes 🟢 + règles de sécurité table + Historique)
- `firestore.indexes.json` (3 nouveaux indexes composites)
- `firestore.rules` (3 nouveaux blocs chapters/lessons/notions)
- `scripts/firebase_seed/README.md` (section seed_content.py + structure dossier mise à jour)
- `scripts/firebase_seed/data/README.md` (table fichiers + section content_demo.json)
- `project_manage/implementation-artifacts/sprint-status.yaml` (in-progress → review)

**Aucun fichier Flutter (`mobile_app/`) modifié.**

### Change Log

| Date | Auteur | Description |
| --- | --- | --- |
| 2026-06-21 | DelRoos / Claude (Amelia) | Story 2.1 complète — schéma 🟢, 3 indexes déployés, rules déployées, seed_content.py, content_demo.json 8ch/16le/32no, 10 tests pytest verts, 6 tests rules verts, seed exécuté + idempotence confirmée sur valide-edu |
