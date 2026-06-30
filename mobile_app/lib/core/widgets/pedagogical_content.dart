// Application stricte d'ADR-014 (qui supersede ADR-009) : `package:gpt_markdown`
// ne doit JAMAIS être importé ailleurs que dans ce fichier. Le wrapper
// `PedagogicalContent` est l'unique surface d'usage côté projet — si le package
// est abandonné, on remplace l'implémentation interne sans toucher aux écrans
// consommateurs.
//
// Tout autre `import 'package:gpt_markdown/...'` doit être refusé en revue +
// via le check CI grep prévu en Story 0.17.
//
// Les widgets internes sont découpés en parts (§12 CLAUDE.md) pour limiter la
// taille de ce fichier. Les fichiers `part` partagent la portée de la librairie
// et peuvent utiliser `GptMarkdown` sans importer le package eux-mêmes —
// ADR-014 est donc pleinement respecté.
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../theme/tokens.dart';

part 'pedagogical_content/callout.dart';
part 'pedagogical_content/citation.dart';
part 'pedagogical_content/code_block.dart';
part 'pedagogical_content/image_components.dart';
part 'pedagogical_content/mermaid_block.dart';
part 'pedagogical_content/streaming_markdown.dart';
part 'pedagogical_content/table_block.dart';

/// Rendu pédagogique unifié : Markdown + LaTeX + images + Mermaid + streaming.
///
/// Blocs spéciaux reconnus en plus du Markdown standard :
/// - `:::definition`, `:::theoreme`, `:::demonstration`, `:::propriete`,
///   `:::methode`, `:::attention`, `:::retenir`, `:::exemple`, `:::figure`
/// - Tables Markdown `|...|` → card avec en-tête TABLEAU + scroll horizontal
/// - Blockquotes `> ...` → bloc citation avec guillemet décoratif
class PedagogicalContent extends StatelessWidget {
  const PedagogicalContent({
    super.key,
    required String this.data,
    this.style,
    this.onLinkTap,
  }) : stream = null;

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
    return _build(data!, effectiveStyle);
  }

  // ── Regexes ────────────────────────────────────────────────

  static final _calloutRe =
      RegExp(r':::(\w+)\n([\s\S]*?):::', multiLine: true);

  // Détecte dans l'ordre : callout, table markdown, blockquote.
  static final _specialRe = RegExp(
    r'(:::(?:\w+)\n[\s\S]*?:::)'            // group(1) bloc callout
    r'|(^\|.+\n\|[-: |]+\n(?:^\|.+\n?)*)'  // group(2) table markdown
    r'|((?:^> ?[^\n]*\n?)+)',               // group(3) blockquote
    multiLine: true,
  );

  // ── Parsing ────────────────────────────────────────────────

  static Widget _build(String data, TextStyle style) {
    final segments = _parseContent(data, style);
    if (segments.length == 1) return segments.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: segments,
    );
  }

  static List<Widget> _parseContent(String data, TextStyle style) {
    final result = <Widget>[];
    int cursor = 0;
    for (final m in _specialRe.allMatches(data)) {
      final pre = data.substring(cursor, m.start).trim();
      if (pre.isNotEmpty) result.add(_md(pre, style));

      if (m.group(1) != null) {
        final cm = _calloutRe.firstMatch(m.group(1)!);
        if (cm != null) {
          result.add(_Callout(
            type: cm.group(1)!,
            body: cm.group(2)!.trim(),
            textStyle: style,
          ));
        } else {
          result.add(_md(m.group(1)!, style));
        }
      } else if (m.group(2) != null) {
        result.add(_TableBlock(markdown: m.group(2)!.trim(), textStyle: style));
      } else if (m.group(3) != null) {
        final lines = m
            .group(3)!
            .split('\n')
            .map((l) => l.replaceFirst(RegExp(r'^> ?'), ''))
            .where((l) => l.isNotEmpty)
            .join('\n');
        result.add(_Citation(text: lines, textStyle: style));
      }
      cursor = m.end;
    }
    final tail = data.substring(cursor).trim();
    if (tail.isNotEmpty) result.add(_md(tail, style));
    return result.isEmpty ? [_md(data, style)] : result;
  }

  static Widget _md(String text, TextStyle style) => GptMarkdown(
        text,
        style: style,
        useDollarSignsForLatex: true,
        imageBuilder: _imageBuilder,
        codeBuilder: _codeBuilder,
      );

  static TextStyle _defaultStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium ?? AppTypography.body;
    return base.merge(AppTypography.body);
  }

  // ── Builders partagés (accessibles aux parts via portée librairie) ─────────

  static Widget _imageBuilder(
    BuildContext context,
    String imageUrl,
    double? width,
    double? height,
  ) {
    final isSvg = imageUrl.toLowerCase().endsWith('.svg');
    final w = width?.w;
    final h = height?.h;

    Widget child;
    if (isSvg) {
      child = SvgPicture.network(
        imageUrl,
        width: w,
        height: h,
        placeholderBuilder: (_) => _ImagePlaceholder(width: w, height: h),
      );
    } else {
      child = CachedNetworkImage(
        imageUrl: imageUrl,
        width: w,
        height: h,
        fit: BoxFit.contain,
        placeholder: (_, _) => _ImagePlaceholder(width: w, height: h),
        errorWidget: (_, _, _) => _ImageError(url: imageUrl),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
      child: Align(
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: child,
        ),
      ),
    );
  }

  static Widget _codeBuilder(
    BuildContext context,
    String name,
    String code,
    bool closed,
  ) {
    if (name.toLowerCase() == 'mermaid' && closed) {
      return _MermaidBlock(source: code);
    }
    return _CodeBlock(language: name, code: code);
  }
}
