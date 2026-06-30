import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/lesson_entity.dart';

enum LessonProgressState { done, current, locked }

class LessonTile extends StatelessWidget {
  const LessonTile({
    super.key,
    required this.lesson,
    required this.languageCode,
    required this.state,
    required this.onTap,
  });

  final LessonEntity lesson;
  final String languageCode;
  final LessonProgressState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFr = languageCode == 'fr';
    final hasDuration = lesson.durationMinutes > 0;
    final isCurrent = state == LessonProgressState.current;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: isCurrent
              ? Border.all(color: AppColors.primary, width: AppBorderWidth.normal)
              : null,
          boxShadow: AppElevation.soft,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _LessonStateIcon(state: state, order: lesson.order),
            SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isFr ? 'LEÇON ${lesson.order}' : 'LESSON ${lesson.order}',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.eyebrow,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                      letterSpacing: 0.5,
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
                  if (hasDuration) ...[
                    SizedBox(height: AppSpacing.s1),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: AppIconSize.sm, color: AppColors.muted),
                        SizedBox(width: AppSpacing.s1),
                        Text(
                          '${lesson.durationMinutes} min',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: AppFontSize.meta,
                            color: AppColors.muted,
                          ),
                        ),
                        SizedBox(width: AppSpacing.s2),
                        Icon(Icons.check_circle_outline,
                            size: AppIconSize.sm, color: AppColors.muted),
                        SizedBox(width: AppSpacing.s1),
                        Flexible(
                          child: Text(
                            isFr ? 'Quiz lié' : 'Linked quiz',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: AppFontSize.meta,
                              color: AppColors.muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: AppSpacing.s2),
            _LessonActionIcon(state: state),
          ],
        ),
      ),
    );
  }
}

// ── Icône d'état à gauche ─────────────────────────────────────

class _LessonStateIcon extends StatelessWidget {
  const _LessonStateIcon({required this.state, required this.order});

  final LessonProgressState state;
  final int order;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case LessonProgressState.done:
        return Container(
          width: AppSpacing.s10,
          height: AppSpacing.s10,
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            Icons.check,
            color: AppColors.success,
            size: AppIconSize.xl,
          ),
        );
      case LessonProgressState.current:
        return Container(
          width: AppSpacing.s10,
          height: AppSpacing.s10,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
            child: Text(
              '$order',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.w800,
                color: AppColors.card,
              ),
            ),
          ),
        );
      case LessonProgressState.locked:
        return Container(
          width: AppSpacing.s10,
          height: AppSpacing.s10,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Text(
              '$order',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.w700,
                color: AppColors.mute2,
              ),
            ),
          ),
        );
    }
  }
}

// ── Icône d'action à droite ───────────────────────────────────

class _LessonActionIcon extends StatelessWidget {
  const _LessonActionIcon({required this.state});

  final LessonProgressState state;

  @override
  Widget build(BuildContext context) {
    if (state == LessonProgressState.current) {
      return Container(
        width: AppSpacing.s8,
        height: AppSpacing.s8,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.play_arrow,
          color: AppColors.card,
          size: AppIconSize.xl,
        ),
      );
    }
    return Icon(
      Icons.chevron_right,
      size: AppIconSize.lg,
      color: AppColors.mute2,
    );
  }
}
