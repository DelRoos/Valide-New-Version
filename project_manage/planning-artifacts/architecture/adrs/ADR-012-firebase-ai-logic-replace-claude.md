# ADR-012 — Remplacer Claude (via Cloud Functions + Anthropic SDK) par Firebase AI Logic (Gemini)

**Date** : 2026-06-04
**Statut** : 🟢 Accepté
**Supersede partiel** :

- ADR-003 § « Modèle IA via Anthropic SDK côté serveur » (à mettre à jour pour Firebase AI Logic)
- PRD NFR-12 (clé Claude API → plus de clé serveur à protéger pour l'IA)
- Doc backend (`doc/tech/Valide Cloud Function Architecture.md`) : Cloud Functions IA `askTutor`, `chatMessage`, `correctMode1` → supprimées ou refondues
- Doc partagée (`doc/partage/CONTRATS-API.md`) : 3 contrats IA à retirer
- Epic 0 Story 0.5 (Dio + retry + connectivity_plus) → **RETIRÉE**

## Contexte

La décision initiale (2026-06-03, ADR-003 + Cloud Function Architecture) actait :

- **Claude** (Anthropic) comme modèle IA pour : Mode 1 (correction photo), Mode 3 (tuteur), Chat IA M6, et toute génération pédagogique.
- **`@anthropic-ai/sdk`** appelé côté serveur uniquement, dans des Cloud Functions 2nd gen TypeScript.
- **Clé Anthropic API** stockée dans Secret Manager côté backend (NFR-12).
- Le client mobile appelait les Cloud Functions via le SDK `cloud_functions` Firebase (pour les fonctions `onCall` non-streaming) et via Dio (pour le streaming, car `onCall` Flutter ne supporte pas le streaming des réponses).

Cela impliquait :

1. **Une Cloud Function par appel IA** (askTutor streaming, chatMessage streaming, correctMode1).
2. **Une couche Dio côté client** pour consommer le streaming HTTP de l'IA (Story 0.5 Epic 0).
3. **Maintenance de la clé Anthropic** (rotation, Secret Manager, monitoring).
4. **Latence supplémentaire** : Mobile → Cloud Function → Anthropic → réponse → Mobile.

En cours de Foundation, le porteur produit a tranché :

> *« Dans le projet supprime claude on utiliseras pas claude pour l'application juste firebase ai logic »* (2026-06-04)

## Décision

**Adopter Firebase AI Logic (avec modèle Gemini) à la place de Claude (via Cloud Functions + SDK Anthropic).**

Implications structurelles :

1. **Modèle IA** : Gemini (via Gemini Developer API pour la V1) au lieu de Claude.
2. **Appels IA = client-side** : le client mobile appelle Firebase AI Logic directement via le package `firebase_ai`, qui gère pour nous l'authentification (Firebase Auth) et la sécurité (App Check). **Plus de Cloud Function intermédiaire** pour les appels IA bruts.
3. **Streaming natif** : `firebase_ai.generateContentStream()` permet le streaming des réponses Gemini directement vers l'app, sans serveur intermédiaire.
4. **Plus de Dio HTTP client custom** : aucun streaming HTTP non-Firebase prévu — Story 0.5 (Dio) est retirée de l'Epic 0.
5. **Sécurité simplifiée** : pas de clé API à stocker côté backend pour l'IA — Firebase AI Logic gère la sécurité via App Check + Auth.
6. **Vérification crédits / quota / premium** : reste serveur-side via Cloud Functions séparées (`consumeCredits`, `checkPremiumAccess`). Le client doit appeler ces functions **AVANT** un appel `firebase_ai` significatif (Mode 1 photo, génération coûteuse) — pattern à figer en E3 / E6.

## Conséquences

### Conséquences positives

- **Architecture plus simple** : moins de Cloud Functions à écrire, déployer, maintenir, monitorer.
- **Moins de latence** : un saut réseau de moins (pas de proxying serveur).
- **Streaming natif** : effet UX « typing » sans coder de SSE serveur custom.
- **Sécurité simplifiée** : pas de clé Anthropic à protéger, pas de Secret Manager IA à gérer.
- **Pas de Dio à maintenir** (Story 0.5 retirée, 502 lignes en moins en P0).
- **Coût modèle souvent inférieur** : Gemini Flash est généralement moins cher que Claude pour des volumes équivalents — favorable au modèle freemium ciblant le marché camerounais.
- **Multimodal natif** : Gemini gère text + image dans le même appel, simplifiant Mode 1 (correction photo) qui pourra envoyer image + énoncé en un seul appel.
- **App Check protège l'IA** : on capitalise sur Story 0.8 (App Check enforce) pour protéger TOUTES les surfaces IA, pas seulement les Cloud Functions custom.

### Conséquences négatives

- **Perte de Claude** : Claude a une posture pédagogique « ne pas donner la réponse » assez fine — il faudra cadrer Gemini par **system prompts** robustes pour reproduire ce comportement. Risque d'inégalité qualité à mesurer en E3 / E6.
- **Verrouillage Google** : on lie plus fortement le projet à l'écosystème Google. Migrer ailleurs (Anthropic direct, OpenAI, etc.) impliquerait une refonte du chemin IA. Acceptable vu le choix Firebase déjà fait (ADR-003).
- **Coûts non maîtrisés côté client** : si un user malicieux contourne App Check, il pourrait spammer Firebase AI Logic à nos frais. Mitigations :
  - App Check enforce dès Story 0.8.
  - Quotas Firebase AI Logic à figer dans la Console (limite par jour).
  - Vérification serveur des crédits / quota avant chaque appel coûteux (pattern existant).
- **`firebase_ai` est encore jeune** : le package évolue rapidement, breaking changes possibles. Mitigation : pin la version dans `pubspec.yaml`, upgrader explicitement.
- **Pas de fine-tuning** au lancement : Gemini Developer API offre moins de personnalisation que Vertex AI ou un fine-tuning Claude. Acceptable en V1.

### Coûts qu'on n'aura PAS

- Maintenance de l'`@anthropic-ai/sdk` côté serveur.
- Code Cloud Function streaming (SSE) custom.
- Code Dio retry / interceptors côté client (Story 0.5 retirée).
- Gestion de la clé Anthropic (rotation, Secret Manager).
- Couche réseau HTTP non-Firebase (couvert par les SDK Firebase pour tout le reste : `firebase_storage`, `cloud_functions` pour les `onCall` non-IA).

## Alternatives écartées

### A1 — Garder Claude via Cloud Functions + Dio (status quo ADR-003)

**Pourquoi écarté** : Plus de code à écrire et maintenir (Cloud Functions IA, Dio interceptors, SSE custom), plus de latence, plus de surface d'attaque (clé serveur), pour un bénéfice qualité incertain et potentiellement marginal vs Gemini bien promptée.

### A2 — Genkit Dart (Google, model-agnostic) avec Claude

**Pourquoi écarté** : Genkit Dart est intéressant (Gemini + Claude + OpenAI via API unifiée, RAG, tools, flows) mais nécessite toujours une Cloud Function intermédiaire (la clé Anthropic ne va pas dans l'app — NFR-12). On garde donc les inconvénients de A1 sans le bénéfice principal de Firebase AI Logic (streaming natif client-side, pas de Cloud Function IA).

### A3 — Vertex AI Claude direct depuis Flutter (Anthropic dans Vertex AI Model Garden)

**Pourquoi écarté** : Vertex AI Model Garden héberge bien Claude (Anthropic) mais l'appel direct depuis Flutter est non standard, mal documenté, et le streaming Flutter via `firebase_ai` n'est pas garanti pour Claude. Chemin à risque pour P0.

### A4 — Gemini via OpenAI-compatible API + Dio

**Pourquoi écarté** : redondant avec Firebase AI Logic, et perd les bénéfices de l'intégration Firebase (App Check, Auth automatique, monitoring intégré).

## Impact sur les artefacts (refonte ciblée)

| Artefact | Changement |
|---|---|
| **ADR-003** | Mettre à jour : Firebase AI Logic remplace l'`@anthropic-ai/sdk` serveur ; les Cloud Functions IA sont supprimées du périmètre backend |
| **CLAUDE.md § Sécurité** | Retirer mention « clé Claude API » (l'IA n'a plus de clé serveur à protéger pour ce projet) |
| **PRD NFR-12** | Reformuler : « Aucun secret dans l'app mobile. La sécurité des appels IA est gérée par App Check + Auth (Firebase AI Logic) ; les secrets serveur restants (signature webhook agrégateur, etc.) vivent dans Secret Manager côté backend » |
| **PRD § Aesthetic / Posture IA** | Préciser : « Posture pédagogique cadrée par system prompt Gemini » (au lieu de « posture Claude par défaut ») |
| **doc/tech/Valide School App Architecture.md** | Section IA refondue : appels Gemini via `firebase_ai` client-side, providers Riverpod lazy, gestion crédits/quota |
| **doc/tech/Valide Cloud Function Architecture.md** | Retirer `askTutor`, `chatMessage`, `correctMode1` (les 3 Cloud Functions IA). Ajouter `consumeCredits` (nouveau, pour Mode 1 + chat premium). Refondre le tableau § 4.4 |
| **doc/partage/CONTRATS-API.md** | Retirer les 3 contrats IA. Possible ajout : `consumeCredits` (idempotent, débite avant l'appel `firebase_ai`) |
| **doc/partage/ALGORITHMES.md** | Si l'algorithme RAG y est décrit côté serveur, le déplacer côté client OU le simplifier (Firebase AI Logic + system prompt avec contexte injecté manuellement par le client) |
| **Epic 0 Story 0.5** | RETIRÉE. Story file `0-5-setup-dio-retry-connectivity.md` supprimé. Code livré (lib + tests) supprimé |
| **Epic 0 Story 0.6** | Étendue avec AC6 (Firebase AI Logic + `firebase_ai` package + smoke tests sync et streaming). Renommée `0-6-setup-firebase-android-ios-firebase-ai`. Estimation L+ → L++ |
| **sprint-status.yaml** | Ligne `0-5-setup-dio-retry-connectivity` retirée. Ligne `0-6-...` renommée |
| **Memory `project_architecture.md`** | Remplacer `@anthropic-ai/sdk` côté serveur par `firebase_ai` côté client + note Gemini |

## Open Questions résolues / nouvelles

### Résolues par cet ADR

- **Aucune OQ formelle PRD existante sur le choix Claude vs autre** — la décision Claude était implicite dans la doc ADR-003.

### Nouvelles OQ introduites

- **OQ-AI-1** — Quel modèle Gemini exact ? Proposition `gemini-2.5-flash` pour la V1 (rapide, économique). À comparer avec `gemini-2.5-pro` en E3 sur des cas pédagogiques réels.
- **OQ-AI-2** — Gemini Developer API ou Vertex AI Gemini API ? Pour la V1 : Gemini Developer (gratuit avec quota raisonnable). Migrer vers Vertex AI si besoin enterprise (SLA, contrôle régional, monitoring fin).
- **OQ-AI-3** — Comment reproduire la posture pédagogique « ne pas donner la réponse » Claude avec Gemini ? À cadrer en E6 (Mode 3, Chat IA) via system prompt rigoureux + tests adversariaux + tracking en analytics.
- **OQ-AI-4** — Quota Firebase AI Logic par user / jour ? À figer dans la Console au moment de Story 0.6, en réviser après mesure d'usage réel.
- **OQ-AI-5** — Pattern client pour Mode 1 (image + texte) : envoyer l'image directement en `Content.image(...)` à Gemini, ou la stocker en `firebase_storage` d'abord et passer une URL ? Gemini accepte les deux. Probablement direct pour Mode 1 (économise un round-trip).
- **OQ-AI-6** — Lien crédits côté serveur ↔ appel `firebase_ai` côté client : pattern à définir. Option simple : Cloud Function `consumeCredits(sessionId, action)` qui débite et retourne un token (HMAC court) à fournir dans le `system prompt` ou metadata de l'appel `firebase_ai`. Pas de verrou cryptographique strict mais traçabilité serveur. À détailler en E3.

## Suivi

- Cet ADR sera revu si :
  - Gemini ne tient pas la posture pédagogique en E3 / E6 → réexaminer Genkit Dart (Claude via proxy) ou Vertex AI Claude.
  - Les coûts Firebase AI Logic explosent → quotas plus stricts + back-off + cache de réponses fréquentes.
  - Firebase AI Logic ajoute un support natif Claude (ADR à mettre à jour, pas à reverter).

## Sources et références

- Firebase AI Logic (anciennement Vertex AI in Firebase) : <https://firebase.google.com/products/firebase-ai-logic>
- Package Flutter `firebase_ai` : <https://pub.dev/packages/firebase_ai>
- Comparaison Firebase AI Logic vs Genkit (article technique) : <https://itnext.io/choosing-the-right-ai-framework-for-flutter-firebase-ai-logic-vs-genkit-68888721efa7>
- Doc Flutter « Create with AI » : <https://docs.flutter.dev/ai/create-with-ai>
