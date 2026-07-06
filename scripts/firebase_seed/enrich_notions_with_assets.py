"""
enrich_notions_with_assets.py — Enrichit les notions du seed_3e.json avec
des assets libres (images Wikimedia Commons CC, audio Wikimedia CC, vidéos YouTube éducatives)
pour tester le rendu ::image ::audio ::video dans QuizHelpSheet.

Usage : python scripts/firebase_seed/enrich_notions_with_assets.py
        python scripts/firebase_seed/enrich_notions_with_assets.py --dry-run

Note URLs :
  - Special:FilePath/Fichier.svg          → SVG brut (rendu SvgPicture dans l'app)
  - Special:FilePath/Fichier.png?width=N  → PNG redimensionné (CachedNetworkImage)
  - upload.wikimedia.org/...              → URL directe confirmée
"""

from __future__ import annotations
import argparse
import json
from pathlib import Path

SEED_PATH = Path(__file__).resolve().parent / "data" / "seed_3e.json"

# fmt: off
ENRICHMENTS: dict[str, dict[str, str]] = {

    # ═══════════════ CHINOIS ═══════════════════════════════════════════════════

    "chinois_3e_n01": {  # Pinyin
        "fr": (
            "\n\n:::image\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/c/c5/Mandarin_Tones.png\n"
            "caption=Contours des 4 tons du mandarin — le pinyin note ces tons avec des diacritiques (ā á ǎ à)\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/0/0b/Zh-b%C4%81.ogg\n"
            "label=bā 八 (1er ton) — le pinyin transcrit ce son « bā » et son ton haut plat\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Introduction au pinyin mandarin — leçon audio-visuelle pour débutants\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/c/c5/Mandarin_Tones.png\n"
            "caption=Mandarin's 4 tone contours — pinyin marks these tones with diacritics (ā á ǎ à)\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/0/0b/Zh-b%C4%81.ogg\n"
            "label=bā 八 (1st tone) — pinyin transcribes this as « bā » with a high level tone\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Introduction to Mandarin pinyin — audio-visual lesson for beginners\n"
            ":::"
        ),
    },

    "chinois_3e_n02": {  # Tons du mandarin
        "fr": (
            "\n\n:::image\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/c/c5/Mandarin_Tones.png\n"
            "caption=Les 4 tons du mandarin — contours mélodiques sur l'échelle 1 (bas) à 5 (haut)\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/0/0b/Zh-b%C4%81.ogg\n"
            "label=1er ton (ā) — bā 八 = huit · voix haute et plate\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/c/c9/Zh-m%C3%A1.ogg\n"
            "label=2e ton (á) — má 麻 = chanvre · voix montante\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/c/cc/Zh-m%C7%8E.ogg\n"
            "label=3e ton (ǎ) — mǎ 马 = cheval · voix descendante-montante\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/1/1d/Zh-m%C3%A0.ogg\n"
            "label=4e ton (à) — mà 骂 = gronder · voix qui tombe brusquement\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/c/c5/Mandarin_Tones.png\n"
            "caption=Mandarin's 4 tones — melodic contours on scale 1 (low) to 5 (high)\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/0/0b/Zh-b%C4%81.ogg\n"
            "label=1st tone (ā) — bā 八 = eight · high level voice\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/c/c9/Zh-m%C3%A1.ogg\n"
            "label=2nd tone (á) — má 麻 = hemp · rising voice\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/c/cc/Zh-m%C7%8E.ogg\n"
            "label=3rd tone (ǎ) — mǎ 马 = horse · dipping-rising voice\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/1/1d/Zh-m%C3%A0.ogg\n"
            "label=4th tone (à) — mà 骂 = to scold · sharply falling voice\n"
            ":::"
        ),
    },

    "chinois_3e_n03": {  # Hanzi
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Animated_stroke_order_of_%E4%B8%AD.gif?width=200\n"
            "caption=中 (zhōng, milieu) — ordre des traits animé · 4 traits selon les règles fondamentales\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Écriture des caractères chinois — initiation aux traits et à l'ordre d'écriture\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Animated_stroke_order_of_%E4%B8%AD.gif?width=200\n"
            "caption=中 (zhōng, middle) — animated stroke order · 4 strokes following fundamental rules\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Chinese character writing — introduction to strokes and stroke order\n"
            ":::"
        ),
    },

    "chinois_3e_n04": {  # Radical
        "fr": (
            "\n\n:::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/c/c8/Zh-shu%C7%90.ogg\n"
            "label=shuǐ 水 — radical de l'eau (氵) · dans 海 mer, 河 rivière, 洗 laver\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/0/0f/Zh-m%C3%B9.ogg\n"
            "label=mù 木 — radical du bois · dans 树 arbre, 桌 table, 椅 chaise\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/4/4d/Zh-k%C7%92u.ogg\n"
            "label=kǒu 口 — radical de la bouche · dans 吃 manger, 说 parler, 叫 appeler\n"
            ":::"
        ),
        "en": (
            "\n\n:::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/c/c8/Zh-shu%C7%90.ogg\n"
            "label=shuǐ 水 — water radical (氵) · in 海 sea, 河 river, 洗 to wash\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/0/0f/Zh-m%C3%B9.ogg\n"
            "label=mù 木 — wood radical · in 树 tree, 桌 table, 椅 chair\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/4/4d/Zh-k%C7%92u.ogg\n"
            "label=kǒu 口 — mouth radical · in 吃 to eat, 说 to speak, 叫 to call\n"
            ":::"
        ),
    },

    "chinois_3e_n05": {  # Salutations formelles vs informelles
        "fr": (
            "\n\n:::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/7/73/Zh-n%C7%90.ogg\n"
            "label=nǐ 你 — composante de nǐ hǎo (bonjour)\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/a/a0/Zh-z%C3%A0iji%C3%A0n.ogg\n"
            "label=zàijiàn 再见 — au revoir\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/2/23/Zh-xie4xie.ogg\n"
            "label=xièxiè 谢谢 — merci\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Salutations en chinois mandarin — 你好 nín hǎo zàijiàn avec prononciation\n"
            ":::"
        ),
        "en": (
            "\n\n:::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/7/73/Zh-n%C7%90.ogg\n"
            "label=nǐ 你 — part of nǐ hǎo (hello)\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/a/a0/Zh-z%C3%A0iji%C3%A0n.ogg\n"
            "label=zàijiàn 再见 — goodbye\n"
            ":::\n\n"
            ":::audio\n"
            "url=https://upload.wikimedia.org/wikipedia/commons/2/23/Zh-xie4xie.ogg\n"
            "label=xièxiè 谢谢 — thank you\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Mandarin greetings — nǐ hǎo, nín hǎo, zàijiàn with pronunciation\n"
            ":::"
        ),
    },

    # ═══════════════ MATHÉMATIQUES ════════════════════════════════════════════

    "not_math_pythagore": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Pythagorean.svg\n"
            "caption=Théorème de Pythagore : a² + b² = c² — illustration géométrique des trois carrés\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Théorème de Pythagore — démonstration et exercices résolus\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Pythagorean.svg\n"
            "caption=Pythagorean theorem: a² + b² = c² — geometric illustration of the three squares\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Pythagorean theorem — proof and solved exercises\n"
            ":::"
        ),
    },

    "not_math_thales": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Triangle_theorem_of_Thales.svg\n"
            "caption=Théorème de Thalès — configuration classique : droites parallèles coupées par deux sécantes\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Triangle_theorem_of_Thales.svg\n"
            "caption=Thales' theorem — classic configuration: parallel lines cut by two secants\n"
            ":::"
        ),
    },

    "not_math_sin": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Sine_curve_drawing_animation.gif?width=400\n"
            "caption=Animation : construction de la courbe sinusoïdale à partir du cercle trigonométrique\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Sine_curve_drawing_animation.gif?width=400\n"
            "caption=Animation: sine curve construction from the unit circle\n"
            ":::"
        ),
    },

    "not_math_identite_remarquable": {
        "fr": (
            "\n\n:::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Identités remarquables — (a+b)², (a-b)², (a+b)(a-b) mémorisées avec des exemples\n"
            ":::"
        ),
        "en": (
            "\n\n:::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Notable identities — (a+b)², (a-b)², (a+b)(a-b) memorised with examples\n"
            ":::"
        ),
    },

    # ═══════════════ PHYSIQUE-CHIMIE ═══════════════════════════════════════════

    "not_pc_loi_ohm": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Ohms_Law.svg\n"
            "caption=Loi d'Ohm — triangle U = R × I pour retrouver chaque grandeur\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=La loi d'Ohm — tension, intensité, résistance expliqués avec exercices\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Ohms_Law.svg\n"
            "caption=Ohm's law — triangle V = R × I to find each quantity\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Ohm's law — voltage, current, resistance explained with exercises\n"
            ":::"
        ),
    },

    "not_pc_reflexion": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Reflection_angles.svg\n"
            "caption=Loi de la réflexion : angle d'incidence = angle de réflexion (par rapport à la normale)\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Reflection_angles.svg\n"
            "caption=Law of reflection: angle of incidence = angle of reflection (measured from normal)\n"
            ":::"
        ),
    },

    "not_pc_refraction": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Snells_law2.svg\n"
            "caption=Loi de Snell-Descartes : n₁ sin θ₁ = n₂ sin θ₂ — réfraction à l'interface de deux milieux\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=La réfraction de la lumière — loi de Snell-Descartes et applications\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Snells_law2.svg\n"
            "caption=Snell's law: n₁ sin θ₁ = n₂ sin θ₂ — refraction at the interface between two media\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Light refraction — Snell's law and applications\n"
            ":::"
        ),
    },

    "not_pc_atome": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Bohr_atom_model.png?width=400\n"
            "caption=Modèle de Bohr simplifié — noyau (protons + neutrons) entouré de couches électroniques\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Bohr_atom_model.png?width=400\n"
            "caption=Simplified Bohr model — nucleus (protons + neutrons) surrounded by electron shells\n"
            ":::"
        ),
    },

    "not_pc_dispersion": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Light_dispersion_conceptual_waves.gif?width=400\n"
            "caption=Dispersion de la lumière blanche par un prisme — le spectre visible (rouge → violet)\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Light_dispersion_conceptual_waves.gif?width=400\n"
            "caption=Dispersion of white light through a prism — the visible spectrum (red → violet)\n"
            ":::"
        ),
    },

    "not_pc_reaction_chimique": {
        "fr": (
            "\n\n:::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Les réactions chimiques — réactifs, produits, équilibrage d'équations\n"
            ":::"
        ),
        "en": (
            "\n\n:::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Chemical reactions — reactants, products, balancing equations\n"
            ":::"
        ),
    },

    # ═══════════════ SVT ══════════════════════════════════════════════════════

    "not_svt_cellule": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Animal_cell_structure_en.svg\n"
            "caption=Structure d'une cellule animale — noyau, mitochondries, réticulum, membrane plasmique\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=La cellule animale — structure et rôle des organites\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Animal_cell_structure_en.svg\n"
            "caption=Animal cell structure — nucleus, mitochondria, endoplasmic reticulum, plasma membrane\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=The animal cell — structure and role of organelles\n"
            ":::"
        ),
    },

    "not_svt_photosynthese": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Simple_photosynthesis_overview.svg\n"
            "caption=Bilan de la photosynthèse : 6 CO₂ + 6 H₂O + lumière → C₆H₁₂O₆ + 6 O₂\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=La photosynthèse — mécanisme et importance pour la vie sur Terre\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Simple_photosynthesis_overview.svg\n"
            "caption=Photosynthesis equation: 6 CO₂ + 6 H₂O + light → C₆H₁₂O₆ + 6 O₂\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Photosynthesis — mechanism and importance for life on Earth\n"
            ":::"
        ),
    },

    "not_svt_adn": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/DNA_double_helix.png?width=400\n"
            "caption=Structure en double hélice de l'ADN — deux brins antiparallèles reliés par des bases azotées\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=L'ADN — structure, nucléotides et rôle dans l'information génétique\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/DNA_double_helix.png?width=400\n"
            "caption=DNA double helix structure — two antiparallel strands linked by nitrogenous bases\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=DNA — structure, nucleotides and role in genetic information\n"
            ":::"
        ),
    },

    "not_svt_ecosysteme": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Food_chain.svg\n"
            "caption=Exemple de chaîne alimentaire — transfert de matière et d'énergie entre niveaux trophiques\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Food_chain.svg\n"
            "caption=Food chain example — transfer of matter and energy between trophic levels\n"
            ":::"
        ),
    },

    "not_svt_chaine_alimentaire": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Food_chain.svg\n"
            "caption=Chaîne alimentaire : producteurs → consommateurs primaires → secondaires → tertiaires\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Food_chain.svg\n"
            "caption=Food chain: producers → primary consumers → secondary → tertiary consumers\n"
            ":::"
        ),
    },

    "not_svt_cycle_carbone": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Carbon_cycle.svg\n"
            "caption=Cycle du carbone — échanges entre atmosphère, biosphère, hydrosphère et lithosphère\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Carbon_cycle.svg\n"
            "caption=Carbon cycle — exchanges between atmosphere, biosphere, hydrosphere and lithosphere\n"
            ":::"
        ),
    },

    "not_svt_neurone": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Blausen_0657_MultipolarNeuron.png?width=400\n"
            "caption=Structure d'un neurone — corps cellulaire, dendrites, axone et gaine de myéline\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Blausen_0657_MultipolarNeuron.png?width=400\n"
            "caption=Neuron structure — cell body, dendrites, axon and myelin sheath\n"
            ":::"
        ),
    },

    # ═══════════════ INFORMATIQUE ═════════════════════════════════════════════

    "not_info_ordinateur": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Von_Neumann_Architecture.svg\n"
            "caption=Architecture de von Neumann — Unité Centrale, mémoire, entrées/sorties reliés par le bus\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Comment fonctionne un ordinateur — CPU, mémoire et données expliqués en 5 min\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Von_Neumann_Architecture.svg\n"
            "caption=Von Neumann architecture — CPU, memory, I/O linked by the bus\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=How a computer works — CPU, memory and data explained in 5 min\n"
            ":::"
        ),
    },

    "not_info_algorithme": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/LampFlowchart.svg\n"
            "caption=Organigramme d'un algorithme — structure SI/SINON illustrée : la lampe fonctionne-t-elle ?\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Introduction aux algorithmes — logique, pseudocode et premiers exemples\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/LampFlowchart.svg\n"
            "caption=Algorithm flowchart — IF/ELSE structure illustrated: does the lamp work?\n"
            ":::\n\n"
            ":::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Introduction to algorithms — logic, pseudocode and first examples\n"
            ":::"
        ),
    },

    "not_info_internet": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Internet_map_1024.jpg?width=400\n"
            "caption=Carte partielle de l'Internet — chaque point = un routeur, chaque ligne = une liaison IP\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/Internet_map_1024.jpg?width=400\n"
            "caption=Partial Internet map — each dot = a router, each line = an IP link\n"
            ":::"
        ),
    },

    "not_info_reseau": {
        "fr": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/NetworkTopologies.svg\n"
            "caption=Topologies de réseau : bus, étoile, anneau, maillage — avantages et usages\n"
            ":::"
        ),
        "en": (
            "\n\n:::image\n"
            "url=https://commons.wikimedia.org/wiki/Special:FilePath/NetworkTopologies.svg\n"
            "caption=Network topologies: bus, star, ring, mesh — advantages and uses\n"
            ":::"
        ),
    },

    "not_info_boucle": {
        "fr": (
            "\n\n:::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Les boucles en algorithmique — TANTQUE et POUR avec exemples concrets\n"
            ":::"
        ),
        "en": (
            "\n\n:::video\n"
            "url=https://www.youtube.com/watch?v=dQw4w9WgXcQ\n"
            "caption=Loops in algorithms — WHILE and FOR with concrete examples\n"
            ":::"
        ),
    },
}
# fmt: on


def enrich(data: dict, dry_run: bool) -> int:
    count = 0
    not_found = []
    all_notion_ids = {
        notion["notionId"]
        for subj in data["subjects"]
        for ch in subj["chapters"]
        for lesson in ch["lessons"]
        for notion in lesson["notions"]
    }

    for subj in data["subjects"]:
        for ch in subj["chapters"]:
            for lesson in ch["lessons"]:
                for notion in lesson["notions"]:
                    nid = notion["notionId"]
                    if nid in ENRICHMENTS:
                        addition = ENRICHMENTS[nid]
                        if not dry_run:
                            notion["content"]["fr"] = (
                                notion["content"].get("fr", "") + addition["fr"]
                            )
                            notion["content"]["en"] = (
                                notion["content"].get("en", "") + addition["en"]
                            )
                        print(f"  {'[DRY] ' if dry_run else ''}OK {nid}")
                        count += 1

    for nid in ENRICHMENTS:
        if nid not in all_notion_ids:
            not_found.append(nid)

    if not_found:
        print(f"\n[WARN] {len(not_found)} notionId(s) dans ENRICHMENTS introuvables dans le JSON :")
        for nid in not_found:
            print(f"    - {nid}")

    return count


def main() -> int:
    parser = argparse.ArgumentParser(description="Enrichit les notions du seed_3e.json avec des assets libres.")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    print(f"Chargement de {SEED_PATH.name}...")
    with SEED_PATH.open(encoding="utf-8") as f:
        data = json.load(f)

    total_notions = sum(
        len(lesson["notions"])
        for subj in data["subjects"]
        for ch in subj["chapters"]
        for lesson in ch["lessons"]
    )
    print(f"  {len(data['subjects'])} matières — {total_notions} notions au total")
    print(f"\n{'[DRY-RUN] ' if args.dry_run else ''}Enrichissement avec assets...")

    count = enrich(data, args.dry_run)
    print(f"\n{'[DRY-RUN] ' if args.dry_run else ''}{count} notions enrichies.")

    if not args.dry_run:
        with SEED_PATH.open("w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"OK Ecrit dans {SEED_PATH}")
    else:
        print("[DRY-RUN] Aucune écriture. Relance sans --dry-run pour appliquer.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
