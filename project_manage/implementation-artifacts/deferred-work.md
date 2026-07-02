# Deferred Work

Findings différés lors des code reviews — à traiter dans des stories futures.

---

## Deferred from: code review of 2-4-content-integration (2026-07-02)

- SVG dans gallery sans httpHeaders : `SvgPicture.network` ne supporte pas `httpHeaders`, aucun SVG Wikimedia actuellement en gallery. Risque réel seulement si du contenu SVG est ajouté. Fix : télécharger via `http.get` + `SvgPicture.memory`. ([gallery_block.dart](../../mobile_app/lib/core/widgets/pedagogical_content/gallery_block.dart))
- TODO sans lien issue dans `lesson_content_tab.dart:120` : `// TODO: réactiver quand la logique de progression est prête`. À lier à la story de progression quand elle sera créée.
- `_RecommendedCard` dead code + `// ignore: unused_element` dans `lesson_content_tab.dart:176` : gardé pour réactivation future avec la logique de recommandation. À supprimer ou activer dans la story progression/recommandations.
- Extension audio fragile `Uri.parse(url).path.split('.').last` dans `audio_block.dart` : peut retourner un segment incorrect sur des URLs sans extension ou avec query params. Acceptable pour V1 (URLs contrôlées par les seeds). À robustifier si des sources audio tierces sont ajoutées.
- `MediaQuery.sizeOf` sans `LayoutBuilder` dans `lesson_page.dart` : pré-existant (Story 2.2). La réactivité aux changements de taille widget-level n'est pas garantie. À corriger dans la story responsive dédiée (Story 2.5 ou suivante).
