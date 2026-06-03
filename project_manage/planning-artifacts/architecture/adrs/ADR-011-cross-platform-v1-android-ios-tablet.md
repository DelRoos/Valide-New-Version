# ADR-011 — Scope V1 cross-platform : Android + iOS, phone + tablette

**Date** : 2026-06-04
**Statut** : 🟢 Accepté
**Supersede partiel** : PRD § 2.2 Out of scope (mention « Utilisateurs d'iPhone — V1 Android-first ; iOS reporté à V2 »), PRD § 6.2 (« iOS reporté V2 »), PRD § 14 (« Android-first », « iOS V2 », « iPad et tablette V3 ou jamais »), Epic 0 § Out of scope (« iOS build (V1 = Android-only) »).

## Contexte

Décision initiale (2026-06-03, capturée dans le PRD et l'Epic 0) :

- V1 = Android-only, phone-only.
- iOS reporté V2.
- iPad et tablettes Android reportés V3 ou jamais.
- Timeline V1 : **6 semaines** (P0-P6).

Cette décision était motivée par :

- **Part de marché iPhone Cameroun** ~8 % (~92 % Android).
- **ROI court terme** : effort iOS perçu comme disproportionné vu la cible géographique.
- **Tablette** : prévalence faible dans la cible secondaire camerounaise (élèves en familles modestes équipés majoritairement de phones).
- **Timeline 6 semaines** : ambitieuse même en Android phone seul.

Cependant, en cours de Foundation (Stories 0.1-0.4 livrées), le porteur produit a re-tranché :

> *« de facon generale l'application dois fonctionner sur ios et android et dois etres responsive pense le design pour telephone et tablette c'est un responsive natif »*

Cette directive porte sur **3 dimensions simultanées** :

1. **iOS** inclus en V1 (pas en V2).
2. **Tablette** (Android ET iPad) incluse en V1.
3. **Responsive natif** — pas de WebView wrapper, pas de mobile-only sur tablette.

## Décision

**V1 cible 4 form factors / 2 OS** :

- Android phone (Play Store, AAB)
- Android tablet (même AAB, Play Store)
- iPhone (App Store, IPA)
- iPad (App Store, IPA)

**Responsive 3 layouts** (cf. EXPERIENCE.md § Responsive & Platform, NFR-17) :

- Phone portrait : largeur < 600 dp
- Phone landscape ou small tablet : 600-840 dp
- Tablet : ≥ 840 dp

**Stack technique** :

- Flutter cross-platform (déjà choisi pour Android — bonus cross-platform natif gratuit côté code).
- Min Android API 26 (8.0), target API 34 (14+).
- Min iOS 13.0, target iOS 17+.
- Compte Apple Developer actif (confirmé par le porteur).
- Mac local ou cloud pour builds iOS (confirmé).

**Conventions cross-platform** (CLAUDE.md § Cross-platform & responsive) :

- Pas de code `dart:io` / `Platform.is*` hors `lib/core/platform/*`.
- Pas de package Android-only sans wrapper avec fallback iOS.
- `LayoutBuilder` ou `MediaQuery.sizeOf(context).width` pour les form factors (helper `Responsive` en Story 0.12).
- Assets audio en AAC/M4A (OGG non supporté nativement iOS).
- Détection mode silencieux Android via API publique ; iOS = fallback exclusif sur setting Profil utilisateur.
- Haptic via API Flutter `HapticFeedback.*` (Taptic Engine côté iOS, vibrator côté Android — mapping documenté DESIGN.md § Haptics).

**Distribution** :

- **Android** : Play Internal Track puis Closed Testing puis Production (workflow standard).
- **iOS** : TestFlight Internal puis External puis App Store Production (TestFlight = équivalent Internal Track).

## Conséquences

### Conséquences positives

- **Couverture marché plus large** : on adresse aussi les ~8 % iPhone et le segment tablette (parents qui achètent une tablette familiale partagée).
- **Image de marque** : « disponible sur les deux stores » signale sérieux et professionnalisme.
- **Architecture future-proof** : les choix faits maintenant (cross-platform stricts, responsive natif) évitent une refonte douloureuse plus tard.
- **Parité parents** : si la cible secondaire utilise un parent comme proxy (achat, configuration), le parent a souvent un iPhone ; couvrir iOS aide aussi le funnel d'acquisition.

### Conséquences négatives / coûts

- **Timeline V1 glisse à ~8-10 semaines** (au lieu de 6) :
  - +30-50 % effort Foundation (Story 0.4bis bootstrap iOS, Story 0.6 Firebase iOS, Story 0.12 helper Responsive, Story 0.17 CI macOS, Story 0.21 deploy TestFlight).
  - +20-30 % effort par story de feature E1-E6 (chaque écran porte 2-3 breakpoints, tests responsive).
- **Coûts opérationnels** :
  - Compte Apple Developer **99 USD/an**.
  - Runner GitHub Actions macOS **10× plus cher** qu'Ubuntu (à surveiller, ~2000 min/mois gratuit pour repo privé).
  - Review App Store ~24-48h pour chaque release (plus long que Play).
- **Coûts cognitifs** :
  - L'équipe doit penser cross-platform en permanence (pas de feature Android-only sans réflexion iOS).
  - QA × 4 form factors au lieu de 1.

### Coûts qu'on N'aura PAS

- **Refonte forcée plus tard** : si on décidait iOS post-V1, on devrait revenir sur 100+ écrans pour les rendre iOS-friendly. Le faire dès le départ est moins coûteux que le faire après.
- **Stack divergente** : pas besoin de wrapper React Native ou de PWA iOS — Flutter compile nativement les deux.

## Alternatives écartées

### A1 — Garder V1 Android-only, faire iOS en V1.5

**Pourquoi écarté** : Imposait une refonte responsive et plateforme dans 3 mois sur du code qui aurait pris des plis Android-only. Coût total estimé supérieur.

### A2 — V1 Android phone + iOS phone, tablette en V2

**Pourquoi écarté** : Le porteur a explicité « téléphone et tablette ». Faire tablette en V2 forcerait à reprendre chaque écran. Le helper `Responsive` est presque gratuit à mettre en place dès la Story 0.12 et les composants atomiques de Story 0.13 le consommeront naturellement.

### A3 — Architecture cross-platform prête mais livraison V1 = Android phone uniquement

**Pourquoi écarté** : Le porteur veut **livrer** iOS et tablette, pas juste être prêt. La directive est explicite.

### A4 — Web (PWA) à la place d'iOS pour économiser sur l'inscription Apple Developer

**Pourquoi écarté** : Sortie de scope (NFR initial : « pas de web »). Les PWA iOS ont des limitations (pas de FCM, expérience dégradée). Compte Apple Developer payé déjà par le porteur.

## Impact sur les artefacts (refonte ciblée)

| Artefact | Changement |
|---|---|
| **CLAUDE.md** | § Contexte (plateformes V1) ; nouvelle § Cross-platform & responsive ; § Points ouverts (Bundle ID, min iOS) |
| **PRD § 2.2** | Out of scope iPhone retiré ; note MAJ 2026-06-04 |
| **PRD § 6.1-6.2** | In scope cross-platform et responsive ; iOS retiré de Out of scope |
| **PRD § 10 (NFRs)** | NFR-16 (cross-platform), NFR-17 (responsive 3 form factors), NFR-18 (audio AAC/M4A) ajoutés ; NFR-1, NFR-2 enrichis avec cible iOS |
| **PRD § 14 Platform** | Section refondue (14.1 cibles V1, 14.2 conventions cross-platform, 14.3 impact timeline) |
| **PRD § 16 OQs** | OQ-3 (stratégie iOS post-V1) résolue |
| **EXPERIENCE.md § Responsive & Platform** | Refonte : 3 breakpoints (phone / phone-landscape / tablet) ; § Plateforme iOS ajoutée ; tablette in scope |
| **EXPERIENCE.md § Multisensoriel coupures** | Lignes iOS (silencieux, Low Power Mode) ajoutées |
| **DESIGN.md § Audio** | Format OGG → AAC/M4A ; `soundpool` éliminé (Android-only) |
| **DESIGN.md § Haptics** | Mapping iOS Taptic / Android vibrator ajouté |
| **DESIGN.md § Layout & Spacing** | Nouvelle § Layout tablette (≥ 840 dp) avec NavigationRail, max-width 600 dp lecture, etc. |
| **Epic 0 § Out of scope** | iOS retiré, tablette in scope (minimal en E0, complet en E1-E6) |
| **Epic 0 § Dependency graph** | Story 0.4bis insérée, Story 0.6 renommée |
| **Epic 0 Story 0.6** | « Firebase Android » → « Firebase Android + iOS » (AC1-AC5 enrichis 2 plateformes) |
| **Epic 0 Story 0.12** | + AC5 Helper Responsive, + AC6 Hello adaptée 3 form factors, estimation S → M |
| **Epic 0 Story 0.17** | + AC2 PR iOS, + AC4 release iOS TestFlight, + AC6 cache Pods, estimation M → L |
| **Epic 0 Story 0.21** | + AC4 deploy TestFlight, + AC6 rendu 4 cibles vérifié, estimation M → M+ |
| **Epic 0 Story 0.4bis** | **Nouvelle** — bootstrap squelette iOS + audit cross-platform |
| **sprint-status.yaml** | + ligne `0-4bis-bootstrap-ios-cross-platform: backlog`, rename `0-6-...-android` → `-android-ios` |
| **Memory `project_architecture.md`** | Mise à jour pour refléter cross-platform |

## Open Questions résolues / nouvelles

### Résolues par cet ADR

- **PRD OQ-3 — Stratégie iOS post-V1** : résolue (iOS en V1).

### Nouvelles OQs introduites

- **OQ-Platform-1** — Bundle ID iOS définitif : proposition `com.valideStartup.valideSchool` (aligné Android). À figer en Story 0.4bis.
- **OQ-Platform-2** — Min iOS version : proposition 13.0. À figer en Story 0.4bis. Si on remonte à 14.0 ou 15.0, on perd quelques % d'utilisateurs mais on gagne des APIs (notamment Widget Kit, Focus modes).
- **OQ-Platform-3** — Source des sons AAC/M4A : nouvelle production ou conversion de sons OGG existants ? Hérite OQ-UX-5.
- **OQ-Platform-4** — Mac CI : runner GitHub Actions macOS standard ou cloud Mac dédié (MacInCloud) pour économie ? À trancher Story 0.17.

## Suivi

- Cet ADR sera revu si **timeline V1 dépasse 12 semaines** : on devra splitter en livrant Android phone d'abord (V1.0) puis iOS+tablette (V1.1), pour ne pas bloquer la mise en marché.
- Le porteur produit accepte le glissement de 6 → 8-10 semaines explicitement (cf. réponse `AskUserQuestion` du 2026-06-04 : « Tout en V1 […] glissement à ~8-10 semaines »).
