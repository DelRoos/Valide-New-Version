import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/errors/content_error_view.dart';
import '../../../../core/widgets/pedagogical_content.dart';
import '../../../onboarding/providers.dart';
import '../../providers.dart';
import '../widgets/lesson_cta_row.dart';
import '../widgets/lesson_page_skeleton.dart';
import '../widgets/lesson_reading_time_pill.dart';

class LessonPage extends ConsumerStatefulWidget {
  const LessonPage({
    super.key,
    required this.subjectId,
    required this.chapterId,
    required this.lessonId,
  });

  final String subjectId;
  final String chapterId;
  final String lessonId;

  @override
  ConsumerState<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends ConsumerState<LessonPage> {
  final _scrollController = ScrollController();
  double _readingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.maxScrollExtent > 0) {
      final progress = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
      if ((progress - _readingProgress).abs() > 0.005) {
        setState(() => _readingProgress = progress);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final isFr = langCode == 'fr';

    final lessonAsync = ref.watch(lessonByIdProvider(widget.lessonId));
    final lessonContentAsync = ref.watch(lessonContentProvider(widget.lessonId));
    final chaptersAsync = ref.watch(chaptersProvider(widget.subjectId));
    final subjectsAsync = ref.watch(userSubjectsProvider);

    final lesson = lessonAsync.maybeWhen(data: (l) => l, orElse: () => null);
    final lessonTitle = lesson?.titleFor(langCode) ?? widget.lessonId;
    final duration = lesson?.durationMinutes ?? 0;

    final chapter = chaptersAsync.maybeWhen(
      data: (list) =>
          list.where((c) => c.chapterId == widget.chapterId).firstOrNull,
      orElse: () => null,
    );
    final chapterOrder = chapter?.order ?? 0;

    final subject = subjectsAsync.maybeWhen(
      data: (list) =>
          list.where((s) => s.subjectId == widget.subjectId).firstOrNull,
      orElse: () => null,
    );
    final subjectAbbrev = subject?.abbreviationFor(langCode) ??
        subject?.name[langCode] ??
        subject?.name['fr'] ??
        widget.subjectId;
    final breadcrumb = '$subjectAbbrev · CH. $chapterOrder';

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.s2),
            child: Icon(
              Icons.arrow_back,
              size: AppIconSize.xl,
              color: AppColors.ink,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              breadcrumb,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.eyebrow,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              lessonTitle,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.h3,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.s2),
              child: Icon(
                Icons.favorite,
                color: AppColors.warning,
                size: AppIconSize.xl,
              ),
            ),
          ),
        ],
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        toolbarHeight: AppDimension.lessonToolbarHeight,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _readingProgress,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: AppDimension.progressBarThin,
          ),
        ),
      ),
      backgroundColor: AppColors.card,
      body: lessonAsync.when(
        loading: () => const LessonPageSkeleton(),
        error: (error, _) => ContentErrorView(
          error: error,
          onRetry: () => ref.invalidate(lessonByIdProvider(widget.lessonId)),
        ),
        data: (_) => lessonContentAsync.when(
          loading: () => const LessonPageSkeleton(),
          error: (error, _) => ContentErrorView(
            error: error,
            onRetry: () => ref.invalidate(lessonContentProvider(widget.lessonId)),
          ),
          data: (lessonContent) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final bottomInset = MediaQuery.paddingOf(context).bottom;
            final content = lessonContent.contentFor(langCode);
            final effectiveMaxWidth = screenWidth >= 840
                ? 720.0
                : screenWidth >= 600
                    ? 600.0
                    : screenWidth;
            return Center(
              child: SizedBox(
                width: effectiveMaxWidth,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s4,
                    AppSpacing.s4,
                    AppSpacing.s4,
                    AppSpacing.s6 + bottomInset,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (duration > 0) ...[
                        LessonReadingTimePill(duration: duration, isFr: isFr),
                        SizedBox(height: AppSpacing.s4),
                      ],
                      PedagogicalContent(data: content),
                      SizedBox(height: AppSpacing.s6),
                      LessonCtaRow(isFr: isFr),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
