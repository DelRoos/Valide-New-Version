import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/cards/subject_progress_list_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'exams_countdown_banner.dart';

const double _kBannerH = 180;
const double _kTitleSkeletonW = 140;
const double _kTitleSkeletonH = 22;
const double _kItemSkeletonH = 72;

const List<int> _kFakeTotal = [18, 24, 12, 30, 16, 22, 14, 28];
const List<int> _kFakeDone = [6, 14, 3, 22, 4, 18, 9, 12];

int _fakeTotal(int i) => _kFakeTotal[i % _kFakeTotal.length];
int _fakeDone(int i) => _kFakeDone[i % _kFakeDone.length].clamp(0, _fakeTotal(i));

// ── Body ─────────────────────────────────────────────────────────────────────

class ExamsBody extends StatelessWidget {
  const ExamsBody({super.key, required this.subjects});

  final List<Subject> subjects;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langKey = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s4.w, AppSpacing.s2.h, AppSpacing.s4.w, AppSpacing.s8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExamsCountdownBanner(l10n: l10n),
          SizedBox(height: AppSpacing.s6.h),
          Text(
            l10n.examsSectionTitle,
            style: AppTypography.h3.copyWith(fontSize: AppFontSize.h3),
          ),
          SizedBox(height: AppSpacing.s3.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjects.length,
            separatorBuilder: (_, _) => SizedBox(height: AppSpacing.s3.h),
            itemBuilder: (_, i) {
              final total = _fakeTotal(i);
              final done = _fakeDone(i);
              return SubjectProgressListCard(
                subject: subjects[i],
                index: i,
                langKey: langKey,
                progressLabel: l10n.examsExercisesOf(done, total),
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

// ── Skeleton ──────────────────────────────────────────────────────────────────

class ExamsSkeleton extends StatelessWidget {
  const ExamsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s4.w, AppSpacing.s2.h, AppSpacing.s4.w, AppSpacing.s8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: _kBannerH.h,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ).animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1400.ms, color: AppColors.bg),
          SizedBox(height: AppSpacing.s6.h),
          Container(
            width: _kTitleSkeletonW.w, height: _kTitleSkeletonH.h,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ).animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1400.ms, color: AppColors.bg),
          SizedBox(height: AppSpacing.s3.h),
          ...List.generate(4, (i) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s3.h),
            child: Container(
              height: _kItemSkeletonH.h,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppElevation.soft,
              ),
            ).animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1400.ms, color: AppColors.bg),
          )),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class ExamsEmpty extends StatelessWidget {
  const ExamsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bookMarked,
                size: AppIconSize.xl9, color: AppColors.muted),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              AppLocalizations.of(context).dashboardEmptyStateText,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
