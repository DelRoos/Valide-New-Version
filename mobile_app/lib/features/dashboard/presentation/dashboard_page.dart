// Story 1.9 — Dashboard skeleton (FR-10 partiel).
//
// Premier ecran metier post-onboarding. Pure presentation : aucun nouveau
// provider/repo, on consomme :
//   - subSystemNotifierProvider (Story 1.2) -> langKey
//   - firebaseAuthProvider (Story 0.6) -> isAnonymous (lecture sync)
//   - userProfileRepositoryProvider.watchProfile() (Story 1.5) -> displayName
//   - derivedProfileProvider (Story 1.3) -> examTargets pour le bandeau
//   - effectiveDerivedSubjectsProvider (Story 1.4) -> liste filtree des matieres
//   - subjectIconFor (helper Story 1.4) -> mapping icone Lucide
//
// AC5 fallback : si derivedProfile.Left ou effective.data([]) -> empty state.
// Loading : skeleton shimmer via flutter_animate (Story 0.14 deja au pubspec).

import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/catalogue/domain/catalogue_failure.dart';
import '../../../core/catalogue/domain/models.dart';
import '../../../core/firebase/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/presentation/_subject_icons.dart';
import '../../onboarding/providers.dart';
import '_main_bottom_nav.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subSystem = ref.watch(subSystemNotifierProvider);
    final langKey = subSystem?.languageCode ?? 'fr';
    final isAnonymous =
        ref.watch(firebaseAuthProvider).currentUser?.isAnonymous ?? true;

    final profileStream =
        ref.watch(userProfileRepositoryProvider).watchProfile();
    final derivedAsync = ref.watch(derivedProfileProvider);
    final effectiveAsync = ref.watch(effectiveDerivedSubjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = _crossAxisCountFor(constraints.maxWidth);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StreamBuilder<Map<String, dynamic>?>(
                  stream: profileStream,
                  builder: (context, snap) {
                    final displayName = snap.data?['displayName'] as String?;
                    final firstName =
                        (displayName != null && displayName.isNotEmpty)
                            ? displayName.split(' ').first
                            : null;
                    return _Hero(
                      firstName: firstName,
                      examLabel: _examLabelFor(derivedAsync, langKey),
                      isAnonymous: isAnonymous,
                    );
                  },
                ),
                Expanded(
                  child: _SubjectsArea(
                    derivedAsync: derivedAsync,
                    effectiveAsync: effectiveAsync,
                    crossAxisCount: crossAxisCount,
                    langKey: langKey,
                  ),
                ),
                if (isAnonymous)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.s4.w,
                      AppSpacing.s2.h,
                      AppSpacing.s4.w,
                      AppSpacing.s3.h,
                    ),
                    child: const _GuestInviteCard(),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
    );
  }
}

int _crossAxisCountFor(double maxWidth) {
  if (maxWidth >= 840) return 5;
  if (maxWidth >= 600) return 4;
  return 3;
}

String? _examLabelFor(
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

class _Hero extends StatelessWidget {
  const _Hero({
    required this.firstName,
    required this.examLabel,
    required this.isAnonymous,
  });

  final String? firstName;
  final String? examLabel;
  final bool isAnonymous;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final welcome = firstName != null
        ? l10n.dashboardWelcomeWithName(firstName!)
        : l10n.dashboardWelcomeGuest;
    final subtitle = examLabel != null
        ? l10n.dashboardSubtitleWithExam(examLabel!)
        : l10n.dashboardSubtitleNoExam;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        border: Border(
          bottom: BorderSide(color: AppColors.primarySoftBorder),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s5.w,
        AppSpacing.s5.h,
        AppSpacing.s5.w,
        AppSpacing.s6.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAnonymous)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3.w,
                  vertical: AppSpacing.s1.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  l10n.dashboardGuestBadge,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warningInk,
                  ),
                ),
              ),
            ),
          SizedBox(height: AppSpacing.s2.h),
          Text(
            welcome,
            style: AppTypography.h1.copyWith(
              color: AppColors.primaryDark,
              fontSize: AppTypography.h1.fontSize!.sp,
            ),
          ),
          SizedBox(height: AppSpacing.s2.h),
          Text(
            subtitle,
            style: AppTypography.body.copyWith(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _SubjectsArea extends StatelessWidget {
  const _SubjectsArea({
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

class _GuestInviteCard extends StatelessWidget {
  const _GuestInviteCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.s4.w),
      child: Row(
        children: [
          Icon(
            LucideIcons.bookmark,
            size: 28.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: AppSpacing.s3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.dashboardGuestInviteText,
                  style: AppTypography.body.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
                SizedBox(height: AppSpacing.s2.h),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.secondary(
                    label: l10n.dashboardGuestInviteCta,
                    onPressed: () =>
                        GoRouter.of(context).go('/onboarding/account'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
