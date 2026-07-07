part of '../pedagogical_content.dart';

class _TableBlock extends StatefulWidget {
  const _TableBlock({required this.markdown, required this.textStyle});

  final String markdown;
  final TextStyle textStyle;

  // Retourne (colonnes d'en-tête, lignes de données).
  static (List<String>, List<List<String>>) _parse(String md) {
    final lines =
        md.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
    final sepRe = RegExp(r'^\|?\s*[-:| ]+\s*\|?\s*$');

    List<String> cells(String line) {
      final t = line.trim();
      final inner = t.startsWith('|') ? t.substring(1) : t;
      final stripped =
          inner.endsWith('|') ? inner.substring(0, inner.length - 1) : inner;
      return stripped.split('|').map((c) => c.trim()).toList();
    }

    final data = lines.where((l) => !sepRe.hasMatch(l)).toList();
    if (data.isEmpty) return (<String>[], <List<String>>[]);
    return (cells(data.first), data.skip(1).map(cells).toList());
  }

  @override
  State<_TableBlock> createState() => _TableBlockState();
}

class _TableBlockState extends State<_TableBlock> {
  final _hScroll = ScrollController();
  bool _hasOverflow = false;
  bool _atEnd = false;
  bool _showLeftFade = false;

  @override
  void initState() {
    super.initState();
    _hScroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  @override
  void dispose() {
    _hScroll.removeListener(_onScroll);
    _hScroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hScroll.hasClients) return;
    final pos = _hScroll.position;
    final atEnd = pos.pixels >= pos.maxScrollExtent - 4;
    final showLeft = pos.pixels > 4;
    if (atEnd != _atEnd || showLeft != _showLeftFade) {
      setState(() {
        _atEnd = atEnd;
        _showLeftFade = showLeft;
      });
    }
  }

  void _checkOverflow() {
    if (!mounted || !_hScroll.hasClients) return;
    final has = _hScroll.position.maxScrollExtent > 0;
    if (has != _hasOverflow) setState(() => _hasOverflow = has);
  }

  void _showFullscreen(BuildContext context) {
    final (headers, rows) = _TableBlock._parse(widget.markdown);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TableFullscreen(
        headers: headers,
        rows: rows,
        textStyle: widget.textStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (headers, rows) = _TableBlock._parse(widget.markdown);
    if (headers.isEmpty) return const SizedBox.shrink();
    final colCount = headers.length;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border:
              Border.all(color: AppColors.border, width: AppBorderWidth.normal),
          boxShadow: AppElevation.soft,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg - 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── En-tête TABLEAU ──
              Container(
                width: double.infinity,
                color: AppColors.primarySoft,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3.w,
                  vertical: AppSpacing.s2.h,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.s1.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Icon(
                        Icons.grid_on_outlined,
                        size: AppIconSize.sm,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: AppSpacing.s2.w),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).tableLabel,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: AppFontSize.eyebrow,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showFullscreen(context),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.s1.w),
                        child: Icon(
                          Icons.open_in_full,
                          size: AppIconSize.sm,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Grille de données avec indicateur scroll ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final minColW = 80.0.w;
                  final minTotal = colCount * minColW;
                  final needsScroll = minTotal > constraints.maxWidth;
                  final tableW =
                      needsScroll ? minTotal : constraints.maxWidth;

                  // Construit la liste de cellules pour une ligne.
                  // Quand pas de scroll : Expanded (répartition flex, pas de dépassement).
                  // Quand scroll : largeur fixe minColW.
                  List<Widget> buildCells(
                    List<String> cells,
                    bool isHeader,
                  ) =>
                      cells.asMap().entries.map((e) {
                        final cell = _TableCell(
                          content: e.value,
                          width: needsScroll ? minColW : null,
                          isHeader: isHeader,
                          showRightBorder: e.key < cells.length - 1,
                          textStyle: widget.textStyle,
                        );
                        return needsScroll
                            ? cell
                            : Expanded(child: cell);
                      }).toList();

                  final tableContent = SingleChildScrollView(
                    controller: _hScroll,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableW,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            color: AppColors.bg,
                            child: Row(
                              children: buildCells(headers, true),
                            ),
                          ),
                          Container(
                              height: 1,
                              color: AppColors.primarySoftBorder),
                          ...rows.asMap().entries.map((entry) {
                            final i = entry.key;
                            final normalised = List.generate(
                              colCount,
                              (j) => j < entry.value.length
                                  ? entry.value[j]
                                  : '',
                            );
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (i > 0)
                                  Container(
                                      height: 0.5,
                                      color: AppColors.border),
                                Container(
                                  color: i.isOdd
                                      ? AppColors.bg
                                      : AppColors.card,
                                  child: Row(
                                    children:
                                        buildCells(normalised, false),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  );

                  if (!_hasOverflow) return tableContent;

                  return Stack(
                    children: [
                      tableContent,
                      if (!_atEnd)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 48.w,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    AppColors.card.withValues(alpha: 0),
                                    AppColors.card.withValues(alpha: 0.92),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_showLeftFade)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 32.w,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    AppColors.card.withValues(alpha: 0.85),
                                    AppColors.card.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.content,
    this.width,
    required this.isHeader,
    required this.showRightBorder,
    required this.textStyle,
  });

  final String content;
  // null → la cellule est dans un Expanded (pas de largeur fixe imposée).
  final double? width;
  final bool isHeader;
  final bool showRightBorder;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final style = isHeader
        ? textStyle.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)
        : textStyle.copyWith(color: AppColors.inkSoft);
    return Container(
      width: width,
      decoration: showRightBorder
          ? const BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.border, width: 0.5),
              ),
            )
          : null,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3.w,
        vertical: AppSpacing.s2.h,
      ),
      child: GptMarkdown(
        content,
        style: style,
        useDollarSignsForLatex: true,
        imageBuilder: PedagogicalContent._imageBuilder,
        codeBuilder: PedagogicalContent._codeBuilder,
      ),
    );
  }
}

class _TableFullscreen extends StatelessWidget {
  const _TableFullscreen({
    required this.headers,
    required this.rows,
    required this.textStyle,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final colCount = headers.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.s4.w,
                  0,
                  AppSpacing.s4.w,
                  AppSpacing.s3.h,
                ),
                child: Row(
                  children: [
                    Icon(Icons.grid_on_outlined,
                        size: AppIconSize.md, color: AppColors.primary),
                    SizedBox(width: AppSpacing.s2.w),
                    Text(
                      AppLocalizations.of(context).tableLabel,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.h3,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close,
                          size: AppIconSize.lg, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Divider(color: AppColors.border, height: 1),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final hPadding = AppSpacing.s3.w;
                    const borderWidth = 1.0; // Border.all default
                    final contentW = constraints.maxWidth -
                        2 * hPadding -
                        2 * borderWidth;
                    final minColW = 100.0.w;
                    final minTotal = colCount * minColW;
                    final needsScroll = minTotal > contentW;
                    final tableW = needsScroll ? minTotal : contentW;

                    List<Widget> buildCells(
                      List<String> cells,
                      bool isHeader,
                    ) =>
                        cells.asMap().entries.map((e) {
                          final cell = _TableCell(
                            content: e.value,
                            width: needsScroll ? minColW : null,
                            isHeader: isHeader,
                            showRightBorder: e.key < cells.length - 1,
                            textStyle: textStyle,
                          );
                          return needsScroll
                              ? cell
                              : Expanded(child: cell);
                        }).toList();

                    return SingleChildScrollView(
                      controller: scrollController,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: hPadding,
                          vertical: AppSpacing.s3.h,
                        ),
                        child: SizedBox(
                          width: tableW,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg - 1),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    color: AppColors.bg,
                                    child: Row(
                                      children:
                                          buildCells(headers, true),
                                    ),
                                  ),
                                  Container(
                                      height: 1,
                                      color: AppColors.primarySoftBorder),
                                  ...rows.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final normalised = List.generate(
                                      colCount,
                                      (j) => j < entry.value.length
                                          ? entry.value[j]
                                          : '',
                                    );
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (i > 0)
                                          Container(
                                              height: 0.5,
                                              color: AppColors.border),
                                        Container(
                                          color: i.isOdd
                                              ? AppColors.bg
                                              : AppColors.card,
                                          child: Row(
                                            children: buildCells(
                                                normalised, false),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
