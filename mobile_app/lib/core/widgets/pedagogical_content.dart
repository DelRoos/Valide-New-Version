// Application stricte d'ADR-014 (qui supersede ADR-009) : `package:gpt_markdown`
// ne doit JAMAIS être importé ailleurs que dans ce fichier. Le wrapper
// `PedagogicalContent` est l'unique surface d'usage côté projet — si le package
// est abandonné, on remplace l'implémentation interne sans toucher aux écrans
// consommateurs.
//
// Tout autre `import 'package:gpt_markdown/...'` doit être refusé en revue +
// via le check CI grep prévu en Story 0.17.
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../theme/tokens.dart';

/// Rendu pédagogique unifié : Markdown + LaTeX + streaming.
///
/// Deux usages :
/// - [PedagogicalContent] (constructeur par défaut) — rendu statique d'une
///   chaîne Markdown. À utiliser pour les cours, les énoncés, les snippets
///   pédagogiques.
/// - [PedagogicalContent.streaming] — rendu progressif depuis un `Stream<String>`.
///   À utiliser pour le tuteur Mode 3 et le chat IA (effet « réponse qui s'écrit »).
///   `gpt_markdown` gère nativement les markdown incomplets — chaque mise à jour
///   du stream redessine sans crash.
///
/// LaTeX : on utilise la convention `$...$` (inline) et `$$...$$` (display) via
/// `useDollarSignsForLatex: true`. Le rendu LaTeX passe par `flutter_math_fork`
/// (dépendance transitive du package).
///
/// Mermaid : **non supporté nativement** par gpt_markdown. Les blocs
/// ```` ```mermaid ```` tomberont en bloc code brut. Story future si besoin
/// d'un rendu graphique des flowcharts (WebView ou builder custom).
class PedagogicalContent extends StatelessWidget {
  /// Rendu statique d'une chaîne Markdown (avec LaTeX).
  const PedagogicalContent({
    super.key,
    required String this.data,
    this.style,
    this.onLinkTap,
  }) : stream = null;

  /// Rendu progressif d'un flux Markdown — chaque chunk redéclenche un rendu
  /// complet. Source canonique pour Mode 3 / Chat IA.
  const PedagogicalContent.streaming({
    super.key,
    required Stream<String> this.stream,
    this.style,
    this.onLinkTap,
  }) : data = null;

  final String? data;
  final Stream<String>? stream;
  final TextStyle? style;
  final void Function(String url, String title)? onLinkTap;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? _defaultStyle(context);
    if (stream != null) {
      return _StreamingMarkdown(
        stream: stream!,
        style: effectiveStyle,
        onLinkTap: onLinkTap,
      );
    }
    return GptMarkdown(
      data!,
      style: effectiveStyle,
      onLinkTap: onLinkTap,
      useDollarSignsForLatex: true,
    );
  }

  /// Style par défaut aligné avec [AppTypography] (corps de texte courant).
  /// Les titres et autres styles sont gérés par `gpt_markdown` selon ses
  /// règles de scaling internes basées sur ce baseStyle.
  static TextStyle _defaultStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium ?? AppTypography.body;
    return base.merge(AppTypography.body);
  }
}

class _StreamingMarkdown extends StatelessWidget {
  const _StreamingMarkdown({
    required this.stream,
    required this.style,
    required this.onLinkTap,
  });

  final Stream<String> stream;
  final TextStyle style;
  final void Function(String url, String title)? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: stream,
      initialData: '',
      builder: (context, snapshot) {
        final data = snapshot.data ?? '';
        return GptMarkdown(
          data,
          style: style,
          onLinkTap: onLinkTap,
          useDollarSignsForLatex: true,
        );
      },
    );
  }
}
