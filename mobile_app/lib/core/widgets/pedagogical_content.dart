// Application stricte d'ADR-014 (qui supersede ADR-009) : `package:gpt_markdown`
// ne doit JAMAIS être importé ailleurs que dans ce fichier. Le wrapper
// `PedagogicalContent` est l'unique surface d'usage côté projet — si le package
// est abandonné, on remplace l'implémentation interne sans toucher aux écrans
// consommateurs.
//
// Tout autre `import 'package:gpt_markdown/...'` doit être refusé en revue +
// via le check CI grep prévu en Story 0.17.
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../theme/tokens.dart';

/// Rendu pédagogique unifié : Markdown + LaTeX + images + Mermaid + streaming.
///
/// Deux usages :
/// - [PedagogicalContent] (constructeur par défaut) — rendu statique d'une
///   chaîne Markdown. À utiliser pour les cours, énoncés, snippets pédagogiques.
/// - [PedagogicalContent.streaming] — rendu progressif depuis un `Stream<String>`.
///   À utiliser pour le tuteur Mode 3 et le chat IA (effet « réponse qui s'écrit »).
///
/// **Supports** (Story 0.19.2) :
/// - Markdown standard (titres, listes, tableaux, blockquotes, code fenced)
/// - LaTeX inline `$x^2$` et display `$$\int_0^1 f(x)\,dx$$` via `flutter_math_fork`
/// - Images raster + SVG via `imageBuilder` (CachedNetworkImage + flutter_svg)
/// - Mermaid via `codeBuilder` (rendu serveur `mermaid.ink` SVG, fallback bloc code
///   si offline). Alt-text `![100x200](url)` parse aussi width × height.
/// - Bloc code stylisé avec typo monospace (Nunito Sans body + JetBrains Mono pour code)
///
/// **Pas encore supportés** (à arbitrer en stories futures) :
/// - HTML `<details>`/`<summary>` (expandable) — testable nativement via `components`
/// - Vidéos (`![video](url.mp4)`) — demande `video_player` + cas full-screen
/// - Callouts custom (`> **Astuce** ...`) — composable via blockquote override
/// - `selectable: true` — wrapper consommateur peut entourer de `SelectionArea`
class PedagogicalContent extends StatelessWidget {
  /// Rendu statique d'une chaîne Markdown.
  const PedagogicalContent({
    super.key,
    required String this.data,
    this.style,
    this.onLinkTap,
  }) : stream = null;

  /// Rendu progressif d'un flux Markdown.
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

  static Widget _build(String data, TextStyle style) {
    return GptMarkdown(
      data,
      style: style,
      useDollarSignsForLatex: true,
      imageBuilder: _imageBuilder,
      codeBuilder: _codeBuilder,
    );
  }

  /// Style par défaut aligné avec [AppTypography] : corps de texte courant.
  /// `gpt_markdown` applique son scaling pour titres/code.
  static TextStyle _defaultStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium ?? AppTypography.body;
    return base.merge(AppTypography.body);
  }

  /// Build d'une image : SVG distant, raster (PNG/JPG/WebP) cache disque,
  /// fallback texte si URL invalide.
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

  /// Build d'un bloc code :
  /// - `language == 'mermaid'` → rendu serveur via `https://mermaid.ink/svg/<base64>`
  ///   (fallback bloc code brut en cas d'offline).
  /// - Autres langages → bloc code stylisé monospace, fond muted.
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
          imageBuilder: PedagogicalContent._imageBuilder,
          codeBuilder: PedagogicalContent._codeBuilder,
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 120.h,
      color: AppColors.muted.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: SizedBox(
        width: 24.w,
        height: 24.h,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.s3.w),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.dangerInk),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: AppColors.dangerInk),
          SizedBox(width: AppSpacing.s2.w),
          Flexible(
            child: Text(
              'Image indisponible',
              style: AppTypography.meta.copyWith(color: AppColors.dangerInk),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.language, required this.code});

  final String language;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.muted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (language.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3.w,
                  vertical: AppSpacing.s1.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.md),
                    topRight: Radius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  language,
                  style: AppTypography.meta.copyWith(
                    color: AppColors.muted,
                    fontFamily: AppTypography.monoFontFamily,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.s3.w),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  code,
                  style: AppTypography.body.copyWith(
                    fontFamily: AppTypography.monoFontFamily,
                    fontSize: 13.sp,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rendu Mermaid via service serveur `mermaid.ink` qui retourne du PNG.
/// L'URL contient le source encodé base64 URL-safe. Fallback bloc code brut
/// en cas d'erreur réseau (errorWidget de CachedNetworkImage).
///
/// **Pourquoi PNG et pas SVG ?** Le SVG renvoyé par mermaid.ink utilise des
/// `<text>` qui réfèrent à des fonts non embarquées par défaut dans
/// `flutter_svg` → labels invisibles sur device. Le PNG rastérise le texte
/// côté serveur, garanti lisible cross-device.
///
/// NFR-4 : un seul appel réseau par diagramme, cache disque via
/// `cached_network_image` (memoize par URL = memoize par contenu).
class _MermaidBlock extends StatelessWidget {
  const _MermaidBlock({required this.source});

  final String source;

  String get _url {
    final bytes = utf8.encode(source);
    final b64 = base64UrlEncode(bytes).replaceAll('=', '');
    return 'https://mermaid.ink/img/$b64?type=png';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.s3.w),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: CachedNetworkImage(
          imageUrl: _url,
          fit: BoxFit.contain,
          placeholder: (_, _) => _MermaidLoading(),
          errorWidget: (_, _, _) => _MermaidError(source: source),
        ),
      ),
    );
  }
}

/// Fallback si mermaid.ink est down ou offline : on rend le source en bloc
/// code brut, l'utilisateur peut au moins lire le diagramme en texte.
class _MermaidError extends StatelessWidget {
  const _MermaidError({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.s2.h),
          child: Text(
            'Diagramme indisponible (mode source ci-dessous)',
            style: AppTypography.meta.copyWith(color: AppColors.muted),
          ),
        ),
        _CodeBlock(language: 'mermaid', code: source),
      ],
    );
  }
}

class _MermaidLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s4.h),
      child: Column(
        children: [
          SizedBox(
            width: 24.w,
            height: 24.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.muted,
            ),
          ),
          SizedBox(height: AppSpacing.s2.h),
          Text(
            'Chargement diagramme…',
            style: AppTypography.meta.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
