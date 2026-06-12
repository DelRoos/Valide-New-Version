// Zone matieres du dashboard — Story 1.9 (refactor E1bis-7).
//
// Consomme `userSubjectsProvider` qui lit users/{uid} (pickedSubjects) +
// catalogueProvider (resolution des Subject). 3 etats :
//   - loading : skeleton shimmer
//   - data vide : empty state avec CTA vers /onboarding/v2
//   - data non vide : grille de cards
// Erreur stream : empty state (best-effort, le banner offline global gere
// les reels problemes reseau).

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/providers.dart';

/// 3 colonnes en phone (<600 dp), 4 en small tablet (600-840), 5 en tablet.
int dashboardCrossAxisCountFor(double maxWidth) {
  if (maxWidth >= 840) return 5;
  if (maxWidth >= 600) return 4;
  return 3;
}

class DashboardSubjectsArea extends ConsumerWidget {
  const DashboardSubjectsArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(userSubjectsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            dashboardCrossAxisCountFor(constraints.maxWidth);
        return subjectsAsync.when(
          loading: () => _SkeletonGrid(crossAxisCount: crossAxisCount),
          error: (_, _) => const _EmptyDashboard(),
          data: (subjects) {
            if (subjects.isEmpty) return const _EmptyDashboard();
            return _SubjectsGrid(
              subjects: subjects,
              crossAxisCount: crossAxisCount,
            );
          },
        );
      },
    );
  }
}

class _SubjectsGrid extends StatelessWidget {
  const _SubjectsGrid({required this.subjects, required this.crossAxisCount});

  final List<Subject> subjects;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s4.w,
        AppSpacing.s4.h,
        AppSpacing.s4.w,
        AppSpacing.s2.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingRecapSubjectsCount(subjects.length),
            style: AppTypography.h3,
          ),
          SizedBox(height: AppSpacing.s3.h),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.s3.w,
                mainAxisSpacing: AppSpacing.s3.h,
                childAspectRatio: 0.95,
              ),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                return _SubjectCard(subject: subjects[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final langKey = Localizations.localeOf(context).languageCode;
    return AppCard(
      onTap: () =>
          GoRouter.of(context).go('/matieres/${subject.subjectId}'),
      padding: EdgeInsets.all(AppSpacing.s3.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.bookOpen,
            size: 32.sp,
            color: AppColors.primary,
          ),
          SizedBox(height: AppSpacing.s2.h),
          Text(
            subject.name[langKey] ?? subject.name['fr'] ?? subject.subjectId,
            style: AppTypography.caption.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid({required this.crossAxisCount});

  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final placeholderCount = crossAxisCount * 3;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s4.w,
        AppSpacing.s4.h,
        AppSpacing.s4.w,
        AppSpacing.s2.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120.w,
            height: 22.h,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: 1400.ms,
                color: AppColors.bg,
              ),
          SizedBox(height: AppSpacing.s3.h),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.s3.w,
                mainAxisSpacing: AppSpacing.s3.h,
                childAspectRatio: 0.95,
              ),
              itemCount: placeholderCount,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.xl2),
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(
                      duration: 1400.ms,
                      color: AppColors.bg,
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.bookOpen,
              size: 56.sp,
              color: AppColors.muted,
            ),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              l10n.dashboardEmptyStateText,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s5.h),
            AppButton.primary(
              label: l10n.dashboardEmptyStateCta,
              onPressed: () => GoRouter.of(context).go('/onboarding/v2'),
            ),
          ],
        ),
      ),
    );
  }
}
