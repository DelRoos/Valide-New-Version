part of '../pedagogical_content.dart';

// ── _GalleryBlock ─────────────────────────────────────────────────────────────
// Syntaxe : :::gallery\nhttps://url1|Caption 1\nhttps://url2|Caption 2\n:::
// PageView horizontal avec indicateur de points. Tap → fullscreen.

class _GalleryItem {
  const _GalleryItem({required this.url, required this.caption});
  final String url;
  final String caption;
}

class _GalleryBlock extends StatefulWidget {
  const _GalleryBlock({required this.items});

  final List<_GalleryItem> items;

  static _GalleryBlock? fromBody(String body) {
    final items = <_GalleryItem>[];
    for (final line in body.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final parts = t.split('|');
      final url = parts[0].trim();
      if (url.startsWith('http://') || url.startsWith('https://')) {
        items.add(_GalleryItem(
          url: url,
          caption: parts.length > 1 ? parts[1].trim() : '',
        ));
      }
    }
    return items.isEmpty ? null : _GalleryBlock(items: items);
  }

  @override
  State<_GalleryBlock> createState() => _GalleryBlockState();
}

class _GalleryBlockState extends State<_GalleryBlock> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen(BuildContext context, int index) {
    final item = widget.items[index];
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FullscreenImageDialog(url: item.url, caption: item.caption),
    );
  }

  bool _isSvg(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    return path.endsWith('.svg');
  }

  Widget _buildSlide(_GalleryItem item) {
    if (_isSvg(item.url)) {
      return SvgPicture.network(
        item.url,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _ImageProgress(height: 200.h),
      );
    }
    return CachedNetworkImage(
      imageUrl: item.url,
      httpHeaders: _kMediaHeaders,
      fit: BoxFit.cover,
      progressIndicatorBuilder: (_, _, p) =>
          _ImageProgress(progress: p.progress, height: 200.h),
      errorWidget: (_, url, err) {
        AppLogger.w('[GalleryBlock] image failed url=$url', error: err);
        return _ImageError(url: item.url);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.items[_page].caption;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: AppBorderWidth.normal),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s3.w,
                vertical: AppSpacing.s2.h,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: AppIconSize.sm,
                    color: AppColors.muted,
                  ),
                  SizedBox(width: AppSpacing.s2.w),
                  Text(
                    'GALERIE · ${widget.items.length} images',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.eyebrow,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.fullscreen, size: AppIconSize.sm, color: AppColors.muted),
                ],
              ),
            ),
            // Carrousel
            SizedBox(
              height: 200.h,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => _openFullscreen(context, i),
                  child: _buildSlide(widget.items[i]),
                ),
              ),
            ),
            // Indicateur points
            if (widget.items.length > 1) ...[
              SizedBox(height: AppSpacing.s2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.items.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _page == i ? 16.w : 6.w,
                    height: 6.h,
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      color: _page == i ? AppColors.primary : AppColors.border,
                    ),
                  ),
                ),
              ),
            ],
            // Légende de la diapositive courante
            SizedBox(
              height: caption.isNotEmpty ? null : AppSpacing.s2.h,
              child: caption.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.s3.w,
                        AppSpacing.s2.h,
                        AppSpacing.s3.w,
                        AppSpacing.s2.h,
                      ),
                      child: Text(
                        caption,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: AppFontSize.meta,
                          color: AppColors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
