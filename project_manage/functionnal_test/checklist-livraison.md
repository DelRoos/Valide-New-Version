# Checklist de livraison — Campagne de tests fonctionnels

> À cocher au fil de la session par chaque testeur, puis à transmettre avec les
> rapports de bug. Une checklist par session par testeur.

---

## En-tête de session

| Champ | Valeur |
|---|---|
| **Testeur** | |
| **Date de la session** | |
| **Durée totale** | h |
| **Build version testée** | |
| **Devices utilisés** | Liste : ex. Pixel 4a + iPad mini |
| **Conditions réseau** | Wi-Fi exclusivement / Mix Wi-Fi+3G / Avec offline tests |

---

## Couverture des tests par section

Pour chaque test, cocher le statut (✅ / ⚠️ / ❌ / 🔒 / ⏭️). Si bug trouvé, indiquer
l'ID du rapport (`bug-XXX`).

### Section 4 — Parcours principaux (TF-1.x)

| TF | Description | Statut | Bug(s) | Notes |
|---|---|---|---|---|
| TF-1.1 | Visiteur Francophone Terminale D | ☐ | | |
| TF-1.2 | Visiteur Francophone 6e | ☐ | | |
| TF-1.3 | Visiteur Anglophone Form 5 (free basket) | ☐ | | |
| TF-1.4 | Visiteur Anglophone Lower Sixth | ☐ | | |
| TF-1.5 | Compte Google Francophone Terminale C | ☐ | | |
| TF-1.6 | Compte Apple Anglophone Upper Sixth | ☐ | | |
| TF-1.7 | Compte Google Francophone 1ère Technique F2 | ☐ | | |
| TF-1.8 | Reprise après arrière-plan | ☐ | | |

### Section 5 — Robustesse (TF-2.x)

| TF | Description | Statut | Bug(s) | Notes |
|---|---|---|---|---|
| TF-2.1 | Kill app à chaque étape → reprise | ☐ | | Détailler quelle étape pose problème si besoin |
| TF-2.2 | Back nav à chaque étape | ☐ | | |
| TF-2.3 | Switch sub-system à mi-parcours | ☐ | | |
| TF-2.4 | Switch OAuth → Visiteur (modale destructive) | ☐ | | |
| TF-2.5 | Upgrade visiteur → compte permanent | ☐ | | |
| TF-2.6 | Réinstallation de l'app | ☐ | | |
| TF-2.7 | Navigation rapide (double-tap) | ☐ | | |

### Section 6 — Erreurs et offline (TF-3.x)

| TF | Description | Statut | Bug(s) | Notes |
|---|---|---|---|---|
| TF-3.1 | Démarrer offline | ☐ | | |
| TF-3.2 | Couper réseau pendant flush | ☐ | | |
| TF-3.3 | Cancellation OAuth Google | ☐ | | |
| TF-3.4 | Cancellation OAuth Apple | ☐ | | |
| TF-3.5 | Permission-denied Firestore | ☐ | | Nécessite l'aide du dev |
| TF-3.6 | Numéro téléphone invalide | ☐ | | |
| TF-3.7 | Nom < 2 chars ou > 50 chars | ☐ | | |
| TF-3.8 | École : aucun résultat + ajout custom | ☐ | | |
| TF-3.9 | École : skip avec micro-friction | ☐ | | |
| TF-3.10 | Bouton back système | ☐ | | |

### Section 7 — Cursus scolaires (TF-4.x)

> Voir `matrice-cursus.csv` pour les 35 lignes. Cocher par batch.

| Batch | Description | Statut | Bugs | Notes |
|---|---|---|---|---|
| TF-4.01 → 04 | Francophone Collège (6e/5e/4e/3e) | ☐ | | |
| TF-4.05 → 11 | Francophone Lycée Générale | ☐ | | |
| TF-4.12 → 23 | Francophone Technique (F1-F8/AF1-3) | ☐ | | |
| TF-4.24 → 28 | Anglophone General Form 1-5 | ☐ | | |
| TF-4.29 → 33 | Anglophone Lower/Upper Sixth | ☐ | | |
| TF-4.34 → 35 | Anglophone Technical (TVE) | ☐ | | Statut connu : actuellement inactif |

### Section 8 — Responsive (TF-5.x)

| TF | Form factor | Statut | Bug(s) | Notes |
|---|---|---|---|---|
| TF-5.1 | Phone portrait (référence) | ☐ | | |
| TF-5.2 | Phone landscape | ☐ | | Vérifier d'abord si le verrou portrait est en V1 |
| TF-5.3 | Tablet portrait | ☐ | | |
| TF-5.4 | Tablet landscape | ☐ | | |

### Section 9 — i18n (TF-6.x)

| TF | Description | Statut | Bug(s) | Notes |
|---|---|---|---|---|
| TF-6.1 | Switch FR ↔ EN via sub-system | ☐ | | |
| TF-6.2 | Vérification exhaustive EN | ☐ | | Lister les strings non traduites trouvées |

### Section 10 — UI/UX par étape (TF-7.x)

| TF | Étape | Statut | Bug(s) | Notes |
|---|---|---|---|---|
| TF-7.0 | Splash animation | ☐ | | |
| TF-7.1 | Étape 0 (sub-system) | ☐ | | |
| TF-7.2 | Étape 1 (hero) | ☐ | | |
| TF-7.3 | Étape 2 (track) | ☐ | | |
| TF-7.4 | Étape 3 (level) | ☐ | | |
| TF-7.5 | Étape 4 (stream + subjects, tous modes) | ☐ | | |
| TF-7.6 | Étape 5 (auth choice) | ☐ | | |
| TF-7.7 | Étape 6 (name) | ☐ | | |
| TF-7.8 | Étape 7 (phone) | ☐ | | |
| TF-7.9 | Étape 8 (school) | ☐ | | |
| TF-7.10 | Étape 9 (success) | ☐ | | |

### Section 11 — Accessibilité (TF-8.x)

| TF | Description | Statut | Bug(s) | Notes |
|---|---|---|---|---|
| TF-8.1 | Taille texte 200% | ☐ | | |
| TF-8.2 | Contraste minimal | ☐ | | |
| TF-8.3 | TalkBack / VoiceOver | ☐ | | Audit complet planifié plus tard |

### Section 12 — Performance (TF-9.x)

> Reporter les mesures dans la colonne Notes au format `min/médiane/max` (3 essais)

| TF | Mesure | Statut | Médiane mesurée | Notes |
|---|---|---|---|---|
| TF-9.1 | Cold start → étape 0 | ☐ | | sec |
| TF-9.2 | Transition entre 2 étapes | ☐ | | ms |
| TF-9.3 | Login Google | ☐ | | sec |
| TF-9.4 | Recherche école | ☐ | | sec |
| TF-9.5 | Flush success étape 9 | ☐ | | sec |
| TF-9.6 | Retry cycle complet (offline forcé) | ☐ | | sec |

### Section 13 — Sécurité (TF-10.x)

| TF | Description | Statut | Bug(s) | Notes |
|---|---|---|---|---|
| TF-10.1 | Aucun secret dans les logs | ☐ | | Nécessite USB + adb/Console |
| TF-10.2 | Pas de fuite entre comptes | ☐ | | |
| TF-10.3 | Switch d'appareil (uid stable OAuth) | ☐ | | Nécessite 2 devices |

---

## Synthèse de session

- Total TFs prévus : **80+**
- Total TFs exécutés : **___**
- ✅ Passed : **___**
- ⚠️ Partial : **___**
- ❌ Failed : **___**
- 🔒 Blocked : **___**
- ⏭️ Skipped : **___** (préciser raison)

### Bugs ouverts par sévérité

| Sévérité | Nombre | Liste IDs |
|---|---|---|
| S1 Critique | 0 | |
| S2 Haute | 0 | |
| S3 Moyenne | 0 | |
| S4 Basse | 0 | |

### Points marquants / impressions générales

(Ressenti global du testeur, fluidité, qualité de l'UX, suggestions hors bug.)

### Recommandation de release

- [ ] L'app est prête à être livrée à des élèves bêta-testeurs externes
- [ ] L'app peut être livrée APRÈS correction des S1+S2 listés ci-dessus
- [ ] L'app n'est PAS prête (préciser pourquoi)

### Suggestions d'améliorations hors scope bug

(UX, copywriting, animations, idées qui ne sont pas des bugs mais des opportunités.)

---

## Signature

| Champ | Valeur |
|---|---|
| Testeur | |
| Date | |
| Signature (initiales) | |
