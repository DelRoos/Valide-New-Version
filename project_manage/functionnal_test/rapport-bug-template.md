# Rapport de bug — `bug-<id>-<court-titre>.md`

> Copie ce fichier en `results/<date>-<testeur>/bug-001-titre.md` et remplis-le.
> Un fichier par bug. Numérotation libre par testeur (`bug-001`, `bug-002`, …).

---

## Identification

| Champ | Valeur |
|---|---|
| **ID rapport** | bug-XXX-YYYY |
| **TF associé** | Ex. TF-1.5 ou TF-2.4 |
| **Sévérité proposée** | S1 / S2 / S3 / S4 (cf. README §Severité) |
| **Date** | YYYY-MM-DD |
| **Testeur** | Prénom + email |
| **Build version** | Ex. `1.0.0+1` (lu dans logs ou app info) |
| **Branche** | `main` au commit `<sha>` |

## Environnement

| Champ | Valeur |
|---|---|
| **Plateforme** | Android / iOS / Web |
| **Device** | Modèle exact (ex. Pixel 4a, iPhone 13 mini, Samsung A03) |
| **OS** | Ex. Android 13, iOS 16.4 |
| **Form factor** | Phone portrait / Phone landscape / Tablet portrait / Tablet landscape |
| **Connexion** | Wi-Fi rapide / 3G / 4G / Mode avion / Toggle pendant test |
| **Compte test** | Visiteur / Google test1 / Apple test1 / Pas connecté |
| **Langue UI** | Français / Anglais |

## Résumé en 1 phrase

Décris le problème en **une seule phrase** : ce que tu as fait → ce qui s'est passé → ce qui aurait dû se passer.

> Exemple : Au tap sur "Continuer avec Google" à l'étape 5, l'app crash avec un écran blanc alors qu'elle devrait afficher le picker Google natif.

## Étapes pour reproduire

1.
2.
3.
4.
5.

**Reproductibilité** : Toujours / 1 fois sur 2 / 1 fois sur 5 / Une seule fois observé / Non reproductible

**Données nécessaires** : (compte de test précis, école choisie, etc.)

## Comportement constaté

(Ce qui s'est passé. Plus c'est descriptif, mieux c'est. Inclure messages d'erreur littéraux, codes, screenshots.)

## Comportement attendu

(Le comportement défini dans `plan-tests-fonctionnels.md` ou attendu par le bon sens.)

## Pièces jointes

- [ ] Screenshot(s) : `bug-XXX-screen1.png`, `bug-XXX-screen2.png`
- [ ] Vidéo : `bug-XXX-screencast.mp4` (si comportement dynamique, transition, animation)
- [ ] Logs : copier les ~50 dernières lignes filtrées `valide` depuis `adb logcat` ou Console.app
- [ ] Capture Firestore : si le bug touche les données users/{uid}, screenshot du doc avant/après

```
(Coller ici les logs pertinents, encadrés en code block)
```

## Workaround si trouvé

(Si tu as réussi à contourner le bug : explique comment. Sinon "Aucun".)

## Impact utilisateur estimé

- [ ] L'utilisateur est totalement bloqué (ne peut pas continuer)
- [ ] L'utilisateur peut continuer mais perd des données / sa progression
- [ ] L'utilisateur peut continuer avec une UX dégradée significative
- [ ] L'utilisateur subit un défaut visuel / textuel sans conséquence fonctionnelle

## Suspicions / hypothèses (optionnel)

(Si tu as une intuition sur la cause : module, story, condition. Aide les devs à investiguer plus vite.)

## Hypothèse de fix (optionnel — uniquement si évident)

(Ex. "Validation du téléphone refuse aussi les numéros valides en +237 9..." — ne pas spéculer si pas évident.)

---

## Section réservée aux devs

| Champ | Valeur |
|---|---|
| **Triage** | Confirmed / Cannot reproduce / Duplicate of / Not a bug / Wontfix |
| **Assigné à** | @dev |
| **PR de fix** | #XXX |
| **Date de fix** | YYYY-MM-DD |
| **Vérifié par** | @testeur |
| **Status final** | Closed-fixed / Closed-wontfix / Closed-duplicate |
