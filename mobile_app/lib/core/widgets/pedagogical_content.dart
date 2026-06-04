// Application stricte d'ADR-009 : `package:flutter_smooth_markdown` ne doit
// JAMAIS être importé ailleurs que dans ce fichier. Le wrapper `PedagogicalContent`
// est l'unique surface d'usage côté projet — si le package est abandonné, on
// remplace l'implémentation interne sans toucher aux écrans consommateurs.
//
// Tout autre `import 'package:flutter_smooth_markdown/...'` doit être refusé
// en revue + via le check CI grep prévu en Story 0.17.
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';

import '../theme/tokens.dart';

/// Rendu pédagogique unifié : Markdown + LaTeX + Mermaid + streaming.
///
/// Deux usages :
/// - [PedagogicalContent] (constructeur par défaut) — rendu statique d'une
///   chaîne Markdown. À utiliser pour les cours, les énoncés, les snippets
///   pédagogiques. Cache de parsing activé (parse-cache LRU global du package).
/// - [PedagogicalContent.streaming] — rendu progressif depuis un `Stream<String>`.
///   À utiliser pour le tuteur Mode 3 et le chat IA (effet « réponse qui s'écrit »).
///
/// Le style hérite par défaut de `Theme.of(context).textTheme.bodyMedium`
/// (alimenté par `AppTypography.body` via `buildLightTheme()`). Pour un override
/// ponctuel, passer un `MarkdownStyleSheet` via [styleSheet].
class PedagogicalContent extends StatelessWidget {
  /// Rendu statique d'une chaîne Markdown (avec LaTeX + Mermaid).
  const PedagogicalContent({
    super.key,
    required String this.data,
    this.styleSheet,
    this.onTapLink,
    this.selectable = false,
  }) : stream = null;

  /// Rendu progressif d'un flux Markdown — chaque chunk est concaténé et
  /// le rendu complet est rafraîchi. Source canonique pour Mode 3 / Chat IA.
  const PedagogicalContent.streaming({
    super.key,
    required Stream<String> this.stream,
    this.styleSheet,
    this.onTapLink,
    this.selectable = false,
  }) : data = null;

  final String? data;
  final Stream<String>? stream;
  final MarkdownStyleSheet? styleSheet;
  final void Function(String url)? onTapLink;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = styleSheet ?? _defaultStyleSheet(context);
    if (stream != null) {
      return StreamMarkdown(
        stream: stream!,
        styleSheet: effectiveStyle,
        onTapLink: onTapLink,
        selectable: selectable,
      );
    }
    return SmoothMarkdown(
      data: data!,
      styleSheet: effectiveStyle,
      onTapLink: onTapLink,
      selectable: selectable,
    );
  }

  /// Style par défaut aligné avec [AppTypography] et [AppColors].
  /// On part de `MarkdownStyleSheet.fromTheme` (qui consomme `Theme.of`) puis
  /// on ajuste les titres avec nos tokens.
  static MarkdownStyleSheet _defaultStyleSheet(BuildContext context) {
    final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return base.copyWith(
      h1Style: AppTypography.h1,
      h2Style: AppTypography.h2,
      h3Style: AppTypography.h3,
      paragraphStyle: AppTypography.body,
      inlineCodeStyle: AppTypography.body.copyWith(
        fontFamily: AppTypography.monoFontFamily,
      ),
    );
  }
}
