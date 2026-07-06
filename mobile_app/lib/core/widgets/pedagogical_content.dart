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
import 'dart:async';
import 'dart:convert';
// ignore: unused_import — utilisé par audio_block (part) pour File + writeAsBytes.
import 'dart:io';
// ignore: unused_import — utilisé par image_components (part) pour Uint8List (SvgPicture.memory).
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
// ignore: unused_import — utilisé par audio_block (part) pour le téléchargement avec headers.
import 'package:http/http.dart' as http;
// ignore: unused_import — utilisé par audio_block (part) pour getTemporaryDirectory.
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// ignore: unused_import — utilisé par les parts (image_components, gallery_block) pour les squelettes animés.
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: unused_import — utilisé par les parts (audio_block, image_components, gallery_block) pour les logs.
import '../logging/app_logger.dart';
import '../theme/tokens.dart';

part 'pedagogical_content/audio_block.dart';
part 'pedagogical_content/callout.dart';
part 'pedagogical_content/citation.dart';
part 'pedagogical_content/code_block.dart';
part 'pedagogical_content/gallery_block.dart';
part 'pedagogical_content/image_components.dart';
part 'pedagogical_content/mermaid_block.dart';
part 'pedagogical_content/streaming_markdown.dart';
part 'pedagogical_content/table_block.dart';

// Headers HTTP envoyés avec chaque requête image/vidéo.
// Wikimedia (et certains CDN) bloquent les user-agents Dart par défaut.
// Referer requis par le serveur de thumbnails Wikimedia (upload.wikimedia.org/thumb)
// pour éviter les HTTP 400 sur les rendus SVG→PNG et JPG redimensionnés.
const _kMediaHeaders = {
  'User-Agent': 'ValideSchool/1.0 (Flutter; educational app)',
  'Accept': 'image/gif,image/webp,image/apng,image/*,*/*;q=0.8',
  'Referer': 'https://en.wikipedia.org/',
};

/// Rendu pédagogique unifié : Markdown + LaTeX + images + Mermaid + streaming.
///
/// Blocs spéciaux reconnus en plus du Markdown standard :
/// - `:::definition`, `:::theoreme`, `:::demonstration`, `:::propriete`,
///   `:::methode`, `:::attention`, `:::retenir`, `:::exemple`, `:::figure`
/// - `:::audio\nurl=...\nlabel=...\n:::` → lecteur audio inline (_AudioBlock)
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
    // Phase 1 : construire la liste brute avec flag isMedia par segment.
    final rawWidgets = <Widget>[];
    final rawIsMedia = <bool>[];

    void addMedia(Widget w) {
      rawWidgets.add(w);
      rawIsMedia.add(true);
    }

    void addBlock(Widget w) {
      rawWidgets.add(w);
      rawIsMedia.add(false);
    }

    int cursor = 0;
    for (final m in _specialRe.allMatches(data)) {
      final pre = data.substring(cursor, m.start).trim();
      if (pre.isNotEmpty) addBlock(_md(pre, style));

      if (m.group(1) != null) {
        final cm = _calloutRe.firstMatch(m.group(1)!);
        if (cm != null) {
          final type = cm.group(1)!;
          final body = cm.group(2)!.trim();
          switch (type) {
            case 'audio':
              final block = _AudioBlock.fromBody(body);
              block != null ? addMedia(block) : addBlock(_md(m.group(1)!, style));
            case 'image':
              final block = _ImageBlock.fromBody(body);
              block != null ? addMedia(block) : addBlock(_md(m.group(1)!, style));
            case 'video':
              final block = _VideoBlock.fromBody(body);
              block != null ? addMedia(block) : addBlock(_md(m.group(1)!, style));
            case 'gallery':
              // gallery est déjà un carrousel — ne pas grouper avec d'autres médias
              final block = _GalleryBlock.fromBody(body);
              addBlock(block ?? _md(m.group(1)!, style));
            default:
              addBlock(_Callout(type: type, body: body, textStyle: style));
          }
        } else {
          addBlock(_md(m.group(1)!, style));
        }
      } else if (m.group(2) != null) {
        addBlock(_TableBlock(markdown: m.group(2)!.trim(), textStyle: style));
      } else if (m.group(3) != null) {
        final lines = m
            .group(3)!
            .split('\n')
            .map((l) => l.replaceFirst(RegExp(r'^> ?'), ''))
            .where((l) => l.isNotEmpty)
            .join('\n');
        addBlock(_Citation(text: lines, textStyle: style));
      }
      cursor = m.end;
    }
    final tail = data.substring(cursor).trim();
    if (tail.isNotEmpty) addBlock(_md(tail, style));

    if (rawWidgets.isEmpty) return [_md(data, style)];

    // Phase 2 : regrouper les blocs média consécutifs en _MediaCarousel.
    final result = <Widget>[];
    final mediaGroup = <Widget>[];

    void flushGroup() {
      if (mediaGroup.isEmpty) return;
      result.add(
        mediaGroup.length == 1
            ? mediaGroup.first
            : _MediaCarousel(children: List.from(mediaGroup)),
      );
      mediaGroup.clear();
    }

    for (int i = 0; i < rawWidgets.length; i++) {
      if (rawIsMedia[i]) {
        mediaGroup.add(rawWidgets[i]);
      } else {
        flushGroup();
        result.add(rawWidgets[i]);
      }
    }
    flushGroup();

    return result;
  }

  static Widget _md(String text, TextStyle style) => GptMarkdown(
        text,
        style: style,
        useDollarSignsForLatex: true,
        imageBuilder: _imageBuilder,
        codeBuilder: _codeBuilder,
        latexBuilder: _latexBuilder,
      );

  // flutter_math_fork rend les formules à leur taille naturelle sans contrainte
  // de largeur — elles débordent sur mobile pour les expressions longues, qu'elles
  // soient bloc ($$...$$) ou inline ($...$).
  // Solution : toujours envelopper dans SingleChildScrollView horizontal.
  // Pour les formules courtes, le scroll est transparent (aucun scroll nécessaire).
  // Pour les formules longues, l'utilisateur scrolle horizontalement.
  static Widget _latexBuilder(
    BuildContext context,
    String tex,
    TextStyle textStyle,
    bool inline,
  ) {
    final formula = Math.tex(
      tex,
      textStyle: textStyle,
      onErrorFallback: (_) => Text(tex, style: textStyle),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: inline
          ? null
          : EdgeInsets.symmetric(vertical: AppSpacing.s2.h),
      child: formula,
    );
  }

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
        placeholderBuilder: (_) => _SkeletonBox(width: w, height: h),
      );
    } else {
      child = CachedNetworkImage(
        imageUrl: imageUrl,
        httpHeaders: _kMediaHeaders,
        width: w,
        height: h,
        fit: BoxFit.contain,
        progressIndicatorBuilder: (_, _, p) =>
            _ImageProgress(progress: p.progress, width: w, height: h),
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
