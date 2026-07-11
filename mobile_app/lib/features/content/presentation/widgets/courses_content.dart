import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/cards/subject_progress_list_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'courses_term_banner.dart';

const List<int> _kFakeTotal = [12, 15, 10, 18, 8, 14, 11, 16];
const List<int> _kFakeDone = [3, 7, 2, 10, 4, 8, 5, 6];

int _fakeChapterTotal(int i) => _kFakeTotal[i % _kFakeTotal.length];
int _fakeChapterDone(int i) =>
    _kFakeDone[i % _kFakeDone.length].clamp(0, _fakeChapterTotal(i));

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
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s4.w, AppSpacing.s2.h, AppSpacing.s4.w, AppSpacing.s8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoursesTermBanner(
            l10n: l10n,
            onCtaTap: subjects.isEmpty
                ? null
                : () => GoRouter.of(context)
                    .push(AppRoutes.subject(subjects.first.subjectId)),
          ),
          SizedBox(height: AppSpacing.s6.h),
          Text(
            l10n.coursesSectionTitle,
            style: AppTypography.h3.copyWith(fontSize: AppFontSize.h3),
          ),
          SizedBox(height: AppSpacing.s3.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjects.length,
            separatorBuilder: (_, _) => SizedBox(height: AppSpacing.s3.h),
            itemBuilder: (_, i) {
              final total = _fakeChapterTotal(i);
              final done = _fakeChapterDone(i);
              return SubjectProgressListCard(
                subject: subjects[i],
                index: i,
                langKey: languageCode,
                progressLabel: l10n.coursesChaptersOf(done, total),
                progressValue: done / total,
                onTap: () => GoRouter.of(context)
                    .push(AppRoutes.subject(subjects[i].subjectId)),
              );
            },
          ),
        ],
      ),
    );
  }
}
