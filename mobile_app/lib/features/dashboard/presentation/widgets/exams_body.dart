import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'exams_countdown_banner.dart';
import 'exams_subject_card.dart';

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
            itemBuilder: (_, i) => ExamsSubjectCard(
              subject: subjects[i],
              index: i,
              langKey: langKey,
              l10n: l10n,
            ),
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
            height: 180.h,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ).animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1400.ms, color: AppColors.bg),
          SizedBox(height: AppSpacing.s6.h),
          Container(
            width: 140.w, height: 22.h,
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
              height: 72.h,
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
