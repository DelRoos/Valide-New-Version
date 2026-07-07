import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/widgets/errors/content_error_view.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../providers.dart';
import './lesson_tile.dart';

class LessonsTab extends ConsumerWidget {
  const LessonsTab({
    super.key,
    required this.chapterId,
    required this.subjectId,
    required this.languageCode,
    required this.progressPercent,
    required this.studentCount,
  });

  final String chapterId;
  final String subjectId;
  final String languageCode;
  final int progressPercent;
  final int studentCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsProvider(chapterId));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        Widget content = lessonsAsync.when(
          loading: () => const _LessonsLoadingSkeleton(),
          error: (error, _) => ContentErrorView(
            error: error,
            onRetry: () => ref.invalidate(lessonsProvider(chapterId)),
          ),
          data: (lessons) => _LessonContent(
            lessons: lessons,
            languageCode: languageCode,
            subjectId: subjectId,
            chapterId: chapterId,
            progressPercent: progressPercent,
            studentCount: studentCount,
          ),
        );

        if (width >= 840) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: content,
            ),
          );
        } else if (width >= 600) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: content,
            ),
          );
        }
        return content;
      },
    );
  }
}

class _LessonContent extends StatelessWidget {
  const _LessonContent({
    required this.lessons,
    required this.languageCode,
    required this.subjectId,
    required this.chapterId,
    required this.progressPercent,
    required this.studentCount,
  });

  final List<LessonEntity> lessons;
  final String languageCode;
  final String subjectId;
  final String chapterId;
  final int progressPercent;
  final int studentCount;

  static LessonProgressState _stateFor(int index, int doneCount, int total) {
    if (index < doneCount) return LessonProgressState.done;
    if (index == doneCount && doneCount < total) return LessonProgressState.current;
    return LessonProgressState.locked;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (lessons.isEmpty) {
      return Center(
        child: Text(
          l10n.lessonsEmptyLabel,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppFontSize.body,
            color: AppColors.muted,
          ),
        ),
      );
    }

    final doneCount =
        (progressPercent / 100 * lessons.length).floor().clamp(0, lessons.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO: réactiver quand la logique de progression est prête.
        // if (doneCount == 0)
        //   Padding(
        //     padding: EdgeInsets.fromLTRB(
        //       AppSpacing.s4,
        //       AppSpacing.s4,
        //       AppSpacing.s4,
        //       AppSpacing.s2,
        //     ),
        //     child: _RecommendedCard(
        //       lesson: lessons.first,
        //       languageCode: languageCode,
        //       onTap: () => context.push(
        //         AppRoutes.lesson(subjectId, chapterId, lessons.first.lessonId),
        //       ),
        //     ),
        //   ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s2,
              AppSpacing.s4,
              AppSpacing.s4,
            ).copyWith(
              bottom: AppSpacing.s4 +
                  MediaQuery.of(context).padding.bottom,
            ),
            itemCount: lessons.length + (studentCount > 0 ? 1 : 0),
            itemBuilder: (_, i) {
              if (i < lessons.length) {
                final lesson = lessons[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.s2),
                  child: LessonTile(
                    lesson: lesson,
                    languageCode: languageCode,
                    state: _stateFor(i, doneCount, lessons.length),
                    onTap: () => context.push(
                      AppRoutes.lesson(subjectId, chapterId, lesson.lessonId),
                    ),
                  ),
                );
              }
              return _StudentCountFooter(
                count: studentCount,
                languageCode: languageCode,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.lesson,
    required this.languageCode,
    required this.onTap,
  });

  final LessonEntity lesson;
  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtitle = lesson.subtitleFor(languageCode);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.primarySoftBorder),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        child: Row(
          children: [
            Icon(
              Icons.star_outline_rounded,
              size: AppIconSize.xl,
              color: AppColors.primary,
            ),
            SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.lessonStartHere,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.meta,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.s1),
                  Text(
                    lesson.titleFor(languageCode),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: AppSpacing.s1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.meta,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: AppIconSize.xl,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCountFooter extends StatelessWidget {
  const _StudentCountFooter({
    required this.count,
    required this.languageCode,
  });

  final int count;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: AppIconSize.md,
            color: AppColors.muted,
          ),
          SizedBox(width: AppSpacing.s1),
          Text(
            AppLocalizations.of(context).chapterStudentsUsingCount(count),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppFontSize.meta,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonsLoadingSkeleton extends StatelessWidget {
  const _LessonsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.s4),
      itemCount: 4,
      itemBuilder: (_, _) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.s2),
        child: AppSkeleton(
          width: double.infinity,
          height: 72,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}
