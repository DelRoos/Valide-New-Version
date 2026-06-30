// Story 2.4 — Page détail d'une matière : UI Story 2.2 + chapitres Firestore.
//
// Route : /subject/:subjectId (hors shell).
// États : loading (skeleton header + liste), error (ContentErrorView), data (header + chapitres).
// Nom/icône matière : userSubjectsProvider. Chapitres : chaptersProvider(subjectId).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/errors/content_error_view.dart';
import '../../../../core/widgets/picker/subject_icon_resolver.dart';
import '../../../onboarding/providers.dart';
import '../../domain/entities/chapter_entity.dart';
import '../../providers.dart';
import '../widgets/chapter_card.dart';

class SubjectDetailPage extends ConsumerWidget {
  const SubjectDetailPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = Localizations.localeOf(context).languageCode;
    final isFr = langCode == 'fr';
    final chaptersAsync = ref.watch(chaptersProvider(subjectId));
    final subjectsAsync = ref.watch(userSubjectsProvider);

    final subject = subjectsAsync.maybeWhen(
      data: (list) => list.where((s) => s.subjectId == subjectId).firstOrNull,
      orElse: () => null,
    );
    final subjectName =
        subject?.name[langCode] ?? subject?.name['fr'] ?? subjectId;
    final subjectIcon = subjectIconFor(subject?.icon ?? '');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: chaptersAsync.when(
        loading: () => _SubjectLoadingBody(
          subjectName: subjectName,
          subjectIcon: subjectIcon,
          isFr: isFr,
          onBack: () => context.pop(),
        ),
        error: (error, _) => Column(
          children: [
            _SubjectHeader(
              subjectName: subjectName,
              subjectIcon: subjectIcon,
              eyebrow: '',
              overallProgress: 0,
              rank: 0,
              isFr: isFr,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ContentErrorView(
                error: error,
                onRetry: () => ref.invalidate(chaptersProvider(subjectId)),
              ),
            ),
          ],
        ),
        data: (chapters) {
          final overallProgress = chapters.isEmpty
              ? 0
              : (chapters
                          .map((c) => c.progressPercent)
                          .fold(0, (s, p) => s + p) /
                      chapters.length)
                  .round();
          final eyebrow = '${chapters.length} ${isFr ? 'CHAPITRES' : 'CHAPTERS'}';

          return Column(
            children: [
              _SubjectHeader(
                subjectName: subjectName,
                subjectIcon: subjectIcon,
                eyebrow: eyebrow,
                overallProgress: overallProgress,
                rank: 0,
                isFr: isFr,
                onBack: () => context.pop(),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final list = _ChapterList(
                      chapters: chapters,
                      languageCode: langCode,
                      subjectId: subjectId,
                    );
                    if (width >= 840) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: list,
                        ),
                      );
                    } else if (width >= 600) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: list,
                        ),
                      );
                    }
                    return list;
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Header dégradé ────────────────────────────────────────────────────────────

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({
    required this.subjectName,
    required this.subjectIcon,
    required this.eyebrow,
    required this.overallProgress,
    required this.rank,
    required this.isFr,
    required this.onBack,
  });

  final String subjectName;
  final IconData subjectIcon;
  final String eyebrow;
  final int overallProgress;
  final int rank;
  final bool isFr;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s2,
            AppSpacing.s1,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.s2),
                      child: Icon(Icons.arrow_back, color: AppColors.card, size: AppIconSize.xl),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.s2),
                      child: Icon(Icons.search, color: AppColors.card, size: AppIconSize.xl),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s1),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: AppSpacing.s10,
                    height: AppSpacing.s10,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(subjectIcon, color: AppColors.card, size: AppIconSize.xl2),
                  ),
                  SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (eyebrow.isNotEmpty)
                          Text(
                            eyebrow,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: AppFontSize.eyebrow,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.75),
                              letterSpacing: 0.5,
                            ),
                          ),
                        SizedBox(height: AppSpacing.s1),
                        Text(
                          subjectName,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: AppFontSize.h2,
                            fontWeight: FontWeight.w900,
                            color: AppColors.card,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    isFr ? 'Progression' : 'Progress',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.eyebrow,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: overallProgress / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.20),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.s2),
                  Text(
                    '$overallProgress%',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.meta,
                      fontWeight: FontWeight.w700,
                      color: AppColors.card,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Liste chapitres ───────────────────────────────────────────────────────────

class _ChapterList extends StatelessWidget {
  const _ChapterList({
    required this.chapters,
    required this.languageCode,
    required this.subjectId,
  });

  final List<ChapterEntity> chapters;
  final String languageCode;
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return Center(
        child: Text(
          languageCode == 'fr' ? 'Aucun chapitre disponible' : 'No chapters available',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppFontSize.body,
            color: AppColors.muted,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s3),
      itemCount: chapters.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.s2),
      itemBuilder: (_, i) {
        final chapter = chapters[i];
        return ChapterCard(
          chapter: chapter,
          languageCode: languageCode,
          onTap: () => context.push(AppRoutes.chapter(subjectId, chapter.chapterId)),
        );
      },
    );
  }
}

// ── Skeleton loading ──────────────────────────────────────────────────────────

class _SubjectLoadingBody extends StatelessWidget {
  const _SubjectLoadingBody({
    required this.subjectName,
    required this.subjectIcon,
    required this.isFr,
    required this.onBack,
  });

  final String subjectName;
  final IconData subjectIcon;
  final bool isFr;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SubjectHeader(
          subjectName: subjectName,
          subjectIcon: subjectIcon,
          eyebrow: '',
          overallProgress: 0,
          rank: 0,
          isFr: isFr,
          onBack: onBack,
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s3,
            ),
            itemCount: 5,
            separatorBuilder: (_, _) => SizedBox(height: AppSpacing.s2),
            itemBuilder: (_, _) => AppSkeleton(
              width: double.infinity,
              height: 80,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ),
      ],
    );
  }
}
