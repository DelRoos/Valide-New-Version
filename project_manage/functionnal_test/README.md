# Tests fonctionnels — Parcours pré-dashboard Valide School

Dossier dédié aux **testeurs externes** chargés de valider le parcours utilisateur
depuis le premier lancement de l'app jusqu'à l'arrivée sur le Dashboard.

> 📅 Version du plan : 1.0 — 2026-06-13
> 🎯 Périmètre : 10 étapes onboarding + auth + identité + école + success
> 🚫 Hors périmètre : dashboard, matières, contenu pédagogique, paiement, IA

## Fichiers de ce dossier

| Fichier | Usage |
|---|---|
| [`plan-tests-fonctionnels.md`](plan-tests-fonctionnels.md) | **Plan principal** — 80+ scénarios numérotés (TF-X.Y) avec préconditions / étapes / résultat attendu / critère pass-fail |
| [`matrice-cursus.csv`](matrice-cursus.csv) | Matrice combinatoire sub-system × track × level × stream à dérouler (≈ 30 combinaisons) |
| [`temps-de-chargement.md`](temps-de-chargement.md) | Cibles de performance par étape + protocole de mesure |
| [`rapport-bug-template.md`](rapport-bug-template.md) | Template à remplir pour chaque bug détecté |
| [`checklist-livraison.md`](checklist-livraison.md) | Checklist pré-livraison (à cocher avant de soumettre le rapport global) |

## Qui lit quoi

- **Lead QA / responsable de campagne** : lit ce README puis distribue les scénarios par testeur via `matrice-cursus.csv`.
- **Testeur exécutant** : lit `plan-tests-fonctionnels.md` du début à la fin avant la première session, garde `rapport-bug-template.md` ouvert pendant l'exécution.
- **Développeur recevant les bugs** : reçoit des `rapport-bug-template.md` remplis + un export agrégé.

## Convention d'ID de test

`TF-<section>.<numéro>` — exemples :
- `TF-1.1` = Parcours principal #1
- `TF-2.5` = Scénario de robustesse #5
- `TF-3.7` = Scénario d'erreur #7
- `TF-9.2` = Test de temps de chargement #2

## Statuts de test

| Symbole | Sens |
|---|---|
| ✅ | Passed — comportement strictement conforme au résultat attendu |
| ⚠️ | Partial — comportement majoritairement OK mais détail manqué (à signaler) |
| ❌ | Failed — comportement non conforme bloquant |
| 🔒 | Blocked — impossible d'exécuter (dépendance, environnement) |
| ⏭️ | Skipped — non applicable sur ce device / cette config |

## Severité de bug (à utiliser dans `rapport-bug-template.md`)

| Severité | Critère |
|---|---|
| **S1 — Critique** | Crash, perte de données, utilisateur bloqué sans issue, faille de sécurité |
| **S2 — Haute** | Fonctionnalité majeure cassée mais contournable ; UX dégradée significativement |
| **S3 — Moyenne** | Bug visible non bloquant ; cas de figure secondaire ; comportement inattendu mais récupérable |
| **S4 — Basse** | Polish (typo, alignement pixel, animation imparfaite, traduction maladroite) |

## Reset entre deux scénarios

Sauf indication contraire, **avant chaque scénario** le testeur doit repartir d'un état "fresh install" :

1. Lancer l'app
2. Si arrivé sur le Dashboard → tap sur le **FAB de debug en haut à droite** → confirmation → `Delete account & clear`
3. L'app revient à l'écran de splash → puis SubSystemStepBody (étape 0)

Sur **iOS**, supprimer + réinstaller l'app si le FAB de debug n'apparaît pas (devrait
toujours apparaître mais alternative safe).

## Comment reporter

À la fin de chaque session :

1. Compléter un `rapport-bug-template.md` **par bug** (renommer en `bug-<id>-<court-titre>.md`)
2. Mettre à jour la `checklist-livraison.md`
3. Soumettre le tout dans `project_manage/functionnal_test/results/<date>-<testeur>/`

Pour les **bugs critiques (S1)**, alerter le développeur immédiatement (Slack /
WhatsApp / email) avec le numéro de TF concerné + une capture / vidéo.

---

**Bon courage et merci pour ton aide !** Plus tu trouves de cas tordus, plus l'app
sera robuste pour les élèves camerounais qui la téléchargeront depuis un téléphone
modeste avec une connexion 3G capricieuse.
