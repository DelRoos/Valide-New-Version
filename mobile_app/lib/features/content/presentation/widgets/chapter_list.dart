import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/chapter_entity.dart';
import 'chapter_card.dart';

class ChapterList extends StatelessWidget {
  const ChapterList({
    super.key,
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
