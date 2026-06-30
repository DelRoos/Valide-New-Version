import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'courses_recommendation_banner.dart';
import 'subject_grid_card.dart';

class CoursesContent extends StatelessWidget {
  const CoursesContent({
    super.key,
    required this.subjects,
    required this.languageCode,
    required this.l10n,
  });

  final List<Subject> subjects;
  final String languageCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Banner recommandation
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s4.w,
              AppSpacing.s2.h,
              AppSpacing.s4.w,
              AppSpacing.s5.h,
            ),
            child: CoursesRecommendationBanner(
              languageCode: languageCode,
              l10n: l10n,
            ),
          ),
        ),
        // Grille matières
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s4.w,
            0,
            AppSpacing.s4.w,
            AppSpacing.s8.h,
          ),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => SubjectGridCard(subject: subjects[i], index: i),
              childCount: subjects.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.s3.w,
              mainAxisSpacing: AppSpacing.s3.h,
              childAspectRatio: 0.77,
            ),
          ),
        ),
      ],
    );
  }
}
