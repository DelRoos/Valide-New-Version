<!--
Merci pour ta contribution !
Avant d'ouvrir la PR, lis doc/tools/CONTRIBUTING.md § 5.5 si tu hésites sur le format.
-->

## Quoi

<!-- Résumé en 2-3 phrases — pas un copier-coller du message de commit. -->

## Pourquoi

<!-- Lien vers la story BMAD / l'issue / l'ADR. -->

- Story / Issue :
- ADR (si applicable) :
- `.decision-log.md` (si une décision a été prise pendant la PR) :

## Comment tester

<!-- Étapes manuelles à reproduire pour valider la PR. -->

- [ ] Étape 1
- [ ] Étape 2
- [ ] Étape 3

## Captures (si UI)

<!-- Screenshots ou GIF. Particulièrement important pour les modifs visuelles. -->

## Impact sur `doc/partage/`

<!-- COCHER OBLIGATOIREMENT. Cf. CONTRIBUTING § 13. -->

- [ ] Aucun
- [ ] Oui — j'ai mis à jour le(s) fichier(s) concerné(s) **dans cette PR** et obtenu l'accord cross-équipe :
  - [ ] `doc/partage/BASE-DE-DONNEES.md` — accord équipe backend obtenu
  - [ ] `doc/partage/ALGORITHMES.md` — accord équipe backend obtenu
  - [ ] `doc/partage/CONTRATS-API.md` — accord équipe backend obtenu
  - [ ] `doc/partage/DONNEES-REFERENCE.md` — accord PM obtenu

## Checklist auteur

### Code
- [ ] Tests ajoutés ou mis à jour (cf. CONTRIBUTING § 8)
- [ ] `flutter analyze` passe sans warning
- [ ] `flutter test` passe
- [ ] `dart format` appliqué
- [ ] Pas de `print()`, `debugPrint()` ou commentaire de debug oublié
- [ ] Pas de TODO/FIXME sans issue liée

### Architecture
- [ ] Le `domain` n'importe ni Flutter, ni Firebase, ni Dio, ni Riverpod, ni `logger`
- [ ] `Exception → Failure` uniquement dans un repository impl
- [ ] Les models ne sortent pas de `data/` (`toEntity()` à la frontière)
- [ ] Pas d'accès Firestore direct depuis `presentation/` (via un datasource)

### Logging
- [ ] `package:logger` n'apparaît que dans `core/logging/app_logger.dart`
- [ ] Toute opération réseau / décision d'accès / paiement / appel IA est loggée
- [ ] Aucune donnée sensible (PIN, jeton, n° de téléphone complet) n'est loggée

### UI
- [ ] Pas de couleur ou taille en dur (tokens via Design System / `flutter_screenutil`)
- [ ] États gérés (loading / error / empty / success)
- [ ] Testé sur ≥ 2 gabarits d'écran (petit + standard)
- [ ] Testé en français ET en anglais (si UI bilingue)
- [ ] Testé en connexion lente / coupée (si flux réseau)

### Sécurité
- [ ] Pas de secret commit (clé, token, mot de passe, PIN)
- [ ] `.env.local`, `google-services.json`, `GoogleService-Info.plist`, keystore : aucun n'est tracké

### Documentation
- [ ] Documentation à jour si l'API publique a changé
- [ ] README de feature mis à jour si setup spécifique
- [ ] Story / issue référencée plus haut

---

<!-- Une fois prêt : passe la PR en "Ready for review" et ajoute les reviewers selon CONTRIBUTING § 7.2. -->
