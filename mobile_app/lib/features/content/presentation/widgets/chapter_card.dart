import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/chapter_entity.dart';

class ChapterCard extends StatelessWidget {
  const ChapterCard({
    super.key,
    required this.chapter,
    required this.languageCode,
    required this.onTap,
  });

  final ChapterEntity chapter;
  final String languageCode;
  final VoidCallback onTap;

  static String _fmtCount(int n) {
    if (n < 1000) return n.toString();
    final t = n ~/ 1000;
    final r = (n % 1000).toString().padLeft(3, '0');
    return '$t $r';
  }

  String _countsText() {
    final isFr = languageCode == 'fr';
    final parts = <String>[];
    if (chapter.lessonCount > 0) {
      final n = chapter.lessonCount;
      parts.add(isFr ? '$n leçon${n > 1 ? 's' : ''}' : '$n lesson${n > 1 ? 's' : ''}');
    }
    if (chapter.quizCount > 0) {
      parts.add('${chapter.quizCount} quiz');
    }
    if (chapter.exerciseCount > 0) {
      final n = chapter.exerciseCount;
      parts.add(isFr ? '$n exercice${n > 1 ? 's' : ''}' : '$n exercise${n > 1 ? 's' : ''}');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final isFr = languageCode == 'fr';
    final title = chapter.titleFor(languageCode);
    final countsText = _countsText();
    final pct = chapter.progressPercent.clamp(0, 100);
    final isDone = pct >= 100;
    final isStarted = pct > 0 && pct < 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppElevation.soft,
        ),
        padding: EdgeInsets.all(AppSpacing.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChapterBadge(
              order: chapter.order,
              isDone: isDone,
              isStarted: isStarted,
            ),
            SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: AppFontSize.body,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: AppSpacing.s2),
                      Icon(
                        Icons.star_border_rounded,
                        size: AppIconSize.xl,
                        color: AppColors.mute2,
                      ),
                    ],
                  ),
                  if (countsText.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.s1),
                    Text(
                      countsText,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.meta,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.s1),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDone ? AppColors.success : AppColors.primary,
                            ),
                            minHeight: AppDimension.progressBarMed,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.s2),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: AppFontSize.meta,
                          fontWeight: FontWeight.w700,
                          color: isDone ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (chapter.studentCount > 0) ...[
                    SizedBox(height: AppSpacing.s1),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: AppIconSize.sm,
                          color: AppColors.mute2,
                        ),
                        SizedBox(width: AppSpacing.s1),
                        Text(
                          '${_fmtCount(chapter.studentCount)} ${isFr ? 'élèves' : 'students'}',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: AppFontSize.meta,
                            color: AppColors.mute2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterBadge extends StatelessWidget {
  const _ChapterBadge({
    required this.order,
    required this.isDone,
    required this.isStarted,
  });

  final int order;
  final bool isDone;
  final bool isStarted;

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return Container(
        width: AppSpacing.s10,
        height: AppSpacing.s10,
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          Icons.check,
          color: AppColors.card,
          size: AppIconSize.xl2,
        ),
      );
    }

    final bgColor = isStarted ? AppColors.primary : AppColors.primaryLight;
    final textColor = isStarted ? AppColors.card : AppColors.primary;

    return Container(
      width: AppSpacing.s10,
      height: AppSpacing.s10,
      padding: EdgeInsets.all(AppSpacing.s075),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CH.',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.tiny,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1,
              ),
            ),
            Text(
              '$order',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.bodySmall,
                fontWeight: FontWeight.w800,
                color: textColor,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
