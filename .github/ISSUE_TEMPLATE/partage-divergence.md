---
name: ⚠️ Divergence doc/partage/
about: Signaler un écart entre doc/partage/ et la réalité du code
title: "[partage] "
labels: doc/partage, divergence
assignees: ''
---

<!--
Ce template est destiné principalement aux équipes admin et landing,
qui consomment doc/partage/ sans le modifier. Si elles découvrent
qu'un fichier de partage ne reflète pas la réalité du code mobile/backend,
elles ouvrent une issue ici.
-->

## Fichier de partage concerné

- [ ] `doc/partage/BASE-DE-DONNEES.md`
- [ ] `doc/partage/ALGORITHMES.md`
- [ ] `doc/partage/CONTRATS-API.md`
- [ ] `doc/partage/DONNEES-REFERENCE.md`

**Section précise** (lien d'ancre Markdown si possible) :

## Ce que le document dit

<!-- Cite ou résume ce qui est documenté. -->

## Ce qui est observé en réalité

<!-- Décris ce que tu observes côté code mobile ou backend. Mets une capture / un extrait. -->

## Contexte

- **Où as-tu observé l'écart** (écran admin, requête, log…) :
- **Quand** (date, environnement dev/staging/prod) :
- **Quel impact** (chiffres faux ? feature cassée ? juste cosmétique ?) :

## Hypothèse sur la cause (optionnel)

- [ ] La doc est en retard sur le code — il faut mettre la doc à jour
- [ ] Le code a dérivé sans mise à jour de la doc — il faut décider quoi corriger
- [ ] Désaccord entre équipes — à trancher en sync archi cross-équipes
- [ ] Pas sûr

## Équipe consommatrice

- [ ] Admin
- [ ] Landing
- [ ] Backend
- [ ] Mobile (lecture interne)
