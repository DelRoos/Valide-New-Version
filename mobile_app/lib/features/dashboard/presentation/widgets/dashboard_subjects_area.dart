// Zone matieres du dashboard — Story 1.9.
//
// Orchestrateur d'etats (loading/error/empty/data) pour la grille de matieres
// + 4 sous-widgets prives :
//   - _SubjectsGrid : la GridView avec compteur
//   - _SubjectCard : 1 card matiere (icone Lucide + nom)
//   - _SkeletonGrid : shimmer placeholder pendant loading
//   - _EmptyDashboard : fallback empty/error state avec CTA back to onboarding
//
// Helpers de calcul exposes :
//   - dashboardCrossAxisCountFor : 3/4/5 colonnes selon breakpoint
//   - dashboardExamLabelFor : extrait le label exam depuis DerivedProfile
//
// Extrait de dashboard_page.dart en juin 2026 (CLAUDE.md regle 12 max-lines).

import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/catalogue_failure.dart';
import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/presentation/_subject_icons.dart';

/// 3 colonnes en phone (<600 dp), 4 en small tablet (600-840), 5 en tablet.
int dashboardCrossAxisCountFor(double maxWidth) {
  if (maxWidth >= 840) return 5;
  if (maxWidth >= 600) return 4;
  return 3;
}

/// Extrait le label exam target localise depuis le DerivedProfile, ou null
/// si pas de target ou Left(failure).
String? dashboardExamLabelFor(
  AsyncValue<Either<CatalogueFailure, DerivedProfile>> derivedAsync,
  String langKey,
) {
  return derivedAsync.maybeWhen(
    data: (either) => either.fold(
      (_) => null,
      (profile) {
        if (profile.examTargets.isEmpty) return null;
        final exam = profile.examTargets.first;
        return exam.name[langKey] ?? exam.name['fr'] ?? exam.examTargetId;
      },
    ),
    orElse: () => null,
  );
}

class DashboardSubjectsArea extends StatelessWidget {
  const DashboardSubjectsArea({
    super.key,
    required this.derivedAsync,
    required this.effectiveAsync,
    required this.crossAxisCount,
    required this.langKey,
  });

  final AsyncValue<Either<CatalogueFailure, DerivedProfile>> derivedAsync;
  final AsyncValue<List<Subject>> effectiveAsync;
  final int crossAxisCount;
  final String langKey;

  @override
  Widget build(BuildContext context) {
    return derivedAsync.when(
      loading: () => _SkeletonGrid(crossAxisCount: crossAxisCount),
      error: (_, _) => const _EmptyDashboard(),
      data: (either) => either.fold(
        (_) => const _EmptyDashboard(),
        (_) => effectiveAsync.when(
          loading: () => _SkeletonGrid(crossAxisCount: crossAxisCount),
          error: (_, _) => const _EmptyDashboard(),
          data: (subjects) {
            if (subjects.isEmpty) return const _EmptyDashboard();
            return _SubjectsGrid(
              subjects: subjects,
              crossAxisCount: crossAxisCount,
              langKey: langKey,
            );
          },
        ),
      ),
    );
  }
}

class _SubjectsGrid extends StatelessWidget {
  const _SubjectsGrid({
    required this.subjects,
    required this.crossAxisCount,
    required this.langKey,
  });

  final List<Subject> subjects;
  final int crossAxisCount;
  final String langKey;

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
                final s = subjects[index];
                return _SubjectCard(subject: s, langKey: langKey);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.langKey});

  final Subject subject;
  final String langKey;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () =>
          GoRouter.of(context).go('/matieres/${subject.subjectId}'),
      padding: EdgeInsets.all(AppSpacing.s3.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            subjectIconFor(subject.icon),
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
              onPressed: () =>
                  GoRouter.of(context).go('/onboarding/profile/filiere'),
            ),
          ],
        ),
      ),
    );
  }
}
