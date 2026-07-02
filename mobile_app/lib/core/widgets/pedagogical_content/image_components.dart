part of '../pedagogical_content.dart';

// ── _SkeletonBox ──────────────────────────────────────────────────────────────
// Placeholder animé (pulse) utilisé pendant le chargement des images.

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 120.h,
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.5, end: 1.0, duration: 900.ms, curve: Curves.easeInOut);
  }
}

// ── _ImageProgress ────────────────────────────────────────────────────────────
// Indicateur circulaire pendant le téléchargement d'une image.
// progress null → indéterminé ; 0.0-1.0 → affiche le pourcentage.

class _ImageProgress extends StatelessWidget {
  const _ImageProgress({this.progress, this.width, this.height});

  final double? progress;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 120.h,
      color: AppColors.muted.withValues(alpha: 0.05),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            if (progress != null && progress! > 0) ...[
              SizedBox(height: AppSpacing.s1.h),
              Text(
                '${(progress! * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppFontSize.meta,
                  color: AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── _ImageError (inline, non-retryable) ──────────────────────────────────────

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

// ── _ImageBlock ───────────────────────────────────────────────────────────────
// Syntaxe : :::image\nurl=...\ncaption=...\n:::
// Affichage inline avec cache, skeleton, retry et plein écran.

class _ImageBlock extends StatefulWidget {
  const _ImageBlock({required this.url, required this.caption});

  final String url;
  final String caption;

  static _ImageBlock? fromBody(String body) {
    String? url;
    String? caption;
    for (final line in body.split('\n')) {
      final t = line.trim();
      if (t.startsWith('url=')) {
        url = t.substring(4).trim();
      } else if (t.startsWith('caption=')) {
        caption = t.substring(8).trim();
      }
    }
    if (url == null || url.isEmpty) return null;
    return _ImageBlock(url: url, caption: caption ?? '');
  }

  @override
  State<_ImageBlock> createState() => _ImageBlockState();
}

class _ImageBlockState extends State<_ImageBlock> {
  int _retryCount = 0;

  // Vérifie le chemin URI (sans query string) pour éviter les faux positifs
  // ex. Pythagorean.svg/220px-Pythagorean.svg.png → pas SVG (c'est un PNG).
  bool get _isSvg {
    final path = Uri.tryParse(widget.url)?.path.toLowerCase() ?? '';
    return path.endsWith('.svg');
  }

  Future<void> _retry() async {
    await CachedNetworkImage.evictFromCache(widget.url);
    if (mounted) setState(() => _retryCount++);
  }

  void _openFullscreen(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FullscreenImageDialog(url: widget.url, caption: widget.caption),
    );
  }

  Widget _buildContent() {
    if (_isSvg) {
      return SvgPicture.network(
        widget.url,
        height: 180.h,
        width: double.infinity,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _ImageProgress(height: 180.h),
      );
    }
    return CachedNetworkImage(
      key: ValueKey('${widget.url}_$_retryCount'),
      imageUrl: widget.url,
      httpHeaders: _kMediaHeaders,
      height: 180.h,
      width: double.infinity,
      fit: BoxFit.contain,
      progressIndicatorBuilder: (_, _, p) => _ImageProgress(progress: p.progress, height: 180.h),
      errorWidget: (context, url, err) {
        AppLogger.w('[ImageBlock] load failed url=$url', error: err);
        return _buildError();
      },
    );
  }

  Widget _buildError() {
    return Container(
      height: 180.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: AppColors.dangerInk, size: AppIconSize.xl),
          SizedBox(height: AppSpacing.s2.h),
          TextButton.icon(
            onPressed: _retry,
            icon: Icon(Icons.refresh_rounded, size: AppIconSize.sm),
            label: Text(
              'Réessayer',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.meta,
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.dangerInk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
      child: GestureDetector(
        onTap: () => _openFullscreen(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: AppBorderWidth.normal),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  _buildContent(),
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.s1.w),
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.s1.w),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Icon(Icons.fullscreen, color: Colors.white, size: AppIconSize.sm),
                    ),
                  ),
                ],
              ),
              if (widget.caption.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s3.w,
                    AppSpacing.s2.h,
                    AppSpacing.s3.w,
                    AppSpacing.s2.h,
                  ),
                  child: Text(
                    widget.caption,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.meta,
                      color: AppColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _FullscreenImageDialog ────────────────────────────────────────────────────

class _FullscreenImageDialog extends StatefulWidget {
  const _FullscreenImageDialog({required this.url, required this.caption});

  final String url;
  final String caption;

  @override
  State<_FullscreenImageDialog> createState() => _FullscreenImageDialogState();
}

class _FullscreenImageDialogState extends State<_FullscreenImageDialog> {
  int _retryCount = 0;

  bool get _isSvg {
    final path = Uri.tryParse(widget.url)?.path.toLowerCase() ?? '';
    return path.endsWith('.svg');
  }

  Future<void> _retry() async {
    await CachedNetworkImage.evictFromCache(widget.url);
    if (mounted) setState(() => _retryCount++);
  }

  Widget _buildImage() {
    if (_isSvg) {
      return SvgPicture.network(
        widget.url,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _ImageProgress(height: 200.h, width: 200.w),
      );
    }
    return CachedNetworkImage(
      key: ValueKey('${widget.url}_fs_$_retryCount'),
      imageUrl: widget.url,
      httpHeaders: _kMediaHeaders,
      fit: BoxFit.contain,
      progressIndicatorBuilder: (_, _, p) =>
          _ImageProgress(progress: p.progress, height: 200.h, width: 200.w),
      errorWidget: (context, url, err) {
        AppLogger.w('[ImageBlock] fullscreen load failed url=$url', error: err);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
            SizedBox(height: AppSpacing.s2.h),
            TextButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: const SizedBox.expand(),
        ),
        Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 6.0,
            child: _buildImage(),
          ),
        ),
        Positioned(
          top: top + AppSpacing.s2,
          right: AppSpacing.s3,
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.s1.w),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: AppIconSize.lg),
            ),
          ),
        ),
        if (widget.caption.isNotEmpty)
          Positioned(
            bottom: bottom + AppSpacing.s3,
            left: AppSpacing.s4,
            right: AppSpacing.s4,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s3.w,
                vertical: AppSpacing.s2.h,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                widget.caption,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppFontSize.meta,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ── _VideoBlock ───────────────────────────────────────────────────────────────
// Syntaxe : :::video\nurl=...\ncaption=...\n:::
// Miniature YouTube auto-détectée. Tap → Chrome Custom Tab / SFSafariViewController (in-app).

class _VideoBlock extends StatelessWidget {
  const _VideoBlock({required this.url, required this.caption});

  final String url;
  final String caption;

  static _VideoBlock? fromBody(String body) {
    String? url;
    String? caption;
    for (final line in body.split('\n')) {
      final t = line.trim();
      if (t.startsWith('url=')) {
        url = t.substring(4).trim();
      } else if (t.startsWith('caption=')) {
        caption = t.substring(8).trim();
      }
    }
    if (url == null || url.isEmpty) return null;
    return _VideoBlock(url: url, caption: caption ?? '');
  }

  static String? _youtubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) return uri.pathSegments.firstOrNull;
    return uri.queryParameters['v'];
  }

  static String? _youtubeThumbnail(String url) {
    final id = _youtubeId(url);
    // mqdefault (320×180) disponible pour toute vidéo — hqdefault absent sur les vidéos peu vues.
    return id != null ? 'https://img.youtube.com/vi/$id/mqdefault.jpg' : null;
  }

  Future<void> _launch() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    // inAppWebView → Chrome Custom Tab (Android) / SFSafariViewController (iOS)
    // L'utilisateur reste dans l'app et peut revenir avec le bouton retour.
    await launchUrl(uri, mode: LaunchMode.inAppWebView);
  }

  @override
  Widget build(BuildContext context) {
    final thumbUrl = _youtubeThumbnail(url);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
      child: GestureDetector(
        onTap: _launch,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: AppBorderWidth.normal),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (thumbUrl != null)
                    CachedNetworkImage(
                      imageUrl: thumbUrl,
                      httpHeaders: _kMediaHeaders,
                      height: 180.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      progressIndicatorBuilder: (_, _, p) =>
                          _ImageProgress(progress: p.progress, height: 180.h),
                      errorWidget: (_, url, err) {
                        AppLogger.w('[VideoBlock] thumbnail failed url=$url', error: err);
                        return Container(height: 180.h, color: AppColors.muted.withValues(alpha: 0.1));
                      },
                    )
                  else
                    Container(
                      height: 160.h,
                      color: AppColors.muted.withValues(alpha: 0.1),
                    ),
                  Container(
                    padding: EdgeInsets.all(AppSpacing.s3.w),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.s3.w,
                  AppSpacing.s2.h,
                  AppSpacing.s3.w,
                  AppSpacing.s2.h,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.smart_display_outlined,
                      color: AppColors.primary,
                      size: AppIconSize.sm,
                    ),
                    SizedBox(width: AppSpacing.s2.w),
                    Expanded(
                      child: Text(
                        caption.isNotEmpty ? caption : 'Voir la vidéo',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: AppFontSize.meta,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Icon(Icons.play_circle_outline, color: AppColors.primary, size: AppIconSize.sm),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _MediaCarousel ────────────────────────────────────────────────────────────
// Enveloppe automatiquement N blocs média consécutifs (audio/image/vidéo)
// en défilement horizontal. Chaque carte est fixée à 260.w.

class _MediaCarousel extends StatelessWidget {
  const _MediaCarousel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            SizedBox(width: 260.w, child: children[i]),
            if (i < children.length - 1) SizedBox(width: AppSpacing.s3.w),
          ],
        ],
      ),
    );
  }
}
