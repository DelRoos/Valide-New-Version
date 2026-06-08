// Story 1.3 — Ecran recap matieres + examen vise + creation doc users/{uid}.
//
// AC5 : appelle catalogueRepository.derive() via derivedProfileProvider et
// affiche bandeau exam target + grille matieres + compteur + 2 boutons.
// AC6 : tap "C'est ma classe" -> userProfileRepository.createProfile() avec
// set(merge:true) + FieldValue.serverTimestamp(). En cas d'erreur Firestore,
// toast non bloquant et state preserve pour retry.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/catalogue/domain/catalogue_failure.dart';
import '../../../core/catalogue/domain/models.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/onboarding_flow_state.dart';
import '../providers.dart';

class ProfileRecapPage extends ConsumerStatefulWidget {
  const ProfileRecapPage({super.key});

  @override
  ConsumerState<ProfileRecapPage> createState() => _ProfileRecapPageState();
}

class _ProfileRecapPageState extends ConsumerState<ProfileRecapPage> {
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subSystem = ref.watch(subSystemNotifierProvider);
    final flow = ref.watch(onboardingFlowProvider);

    // Guard : si flow incomplet, redirect vers la 1ere etape manquante.
    if (subSystem == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          GoRouter.of(context).go('/onboarding/subsystem');
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    if (!flow.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          GoRouter.of(context).go('/onboarding/profile/filiere');
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final derivedAsync = ref.watch(derivedProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 840;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 720 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.s5.w,
                    vertical: AppSpacing.s6.h,
                  ),
                  child: derivedAsync.when(
                    data: (either) => either.fold(
                      (failure) => _RecapErrorView(
                        failure: failure,
                        onBack: () {
                          ref
                              .read(onboardingFlowProvider.notifier)
                              .backTo(OnboardingFlowStep.filiere);
                          GoRouter.of(context)
                              .go('/onboarding/profile/filiere');
                        },
                      ),
                      (profile) => _RecapDataView(
                        profile: profile,
                        langKey: subSystem.languageCode,
                        isCreating: _isCreating,
                        onValidate: () => _onValidate(profile),
                        onBack: () {
                          // Si serieId pose -> retour vers serie ; sinon -> niveau.
                          final hasSerie = flow.serieId != null;
                          ref.read(onboardingFlowProvider.notifier).backTo(
                                hasSerie
                                    ? OnboardingFlowStep.serie
                                    : OnboardingFlowStep.serie,
                              );
                          GoRouter.of(context).go(
                            hasSerie
                                ? '/onboarding/profile/serie'
                                : '/onboarding/profile/niveau',
                          );
                        },
                      ),
                    ),
                    loading: () => _RecapLoadingView(),
                    error: (e, st) => Center(
                      child: Text(
                        l10n.errorGeneric,
                        style: AppTypography.body.copyWith(
                          color: AppColors.danger,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onValidate(DerivedProfile profile) async {
    if (_isCreating) return;
    final l10n = AppLocalizations.of(context);
    final subSystem = ref.read(subSystemNotifierProvider)!;
    final flow = ref.read(onboardingFlowProvider);
    final repo = ref.read(userProfileRepositoryProvider);

    setState(() => _isCreating = true);

    final result = await repo.createProfile(
      subSystem: subSystem,
      filiereId: flow.filiereId!,
      niveauId: flow.niveauId!,
      // serie '-' si niveau sans serie (cohrent regles Firestore AC7).
      serieId: flow.serieId ?? '-',
      derivedSubjects: profile.subjects.map((s) => s.subjectId).toList(),
      examTargets: profile.examTargets.map((e) => e.examTargetId).toList(),
    );

    if (!mounted) return;
    setState(() => _isCreating = false);

    result.fold(
      (failure) {
        AppLogger.w('createProfile failed: ${failure.message}');
        AppToast.show(
          context,
          message: l10n.onboardingRecapFirestoreErrorToast,
          tone: ToastTone.warning,
        );
      },
      (_) {
        // Story 1.3 V1 : navigation vers /hello. Sera remplacee par
        // /onboarding/account (Story 1.6) ou /onboarding/school (Story 1.7).
        GoRouter.of(context).go('/hello');
      },
    );
  }
}

class _RecapDataView extends StatelessWidget {
  const _RecapDataView({
    required this.profile,
    required this.langKey,
    required this.isCreating,
    required this.onValidate,
    required this.onBack,
  });

  final DerivedProfile profile;
  final String langKey;
  final bool isCreating;
  final VoidCallback onValidate;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final examNames = profile.examTargets
        .map((e) => e.name[langKey] ?? e.name['fr'] ?? e.examTargetId)
        .toList();
    final examBannerText = examNames.isEmpty
        ? l10n.onboardingRecapNoExamLabel
        : l10n.onboardingRecapPrepareLabel(examNames.join(', '));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.s4.w),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.target,
                color: AppColors.primary,
                size: 24.sp,
              ),
              SizedBox(width: AppSpacing.s3.w),
              Expanded(
                child: Text(
                  examBannerText,
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.s5.h),
        Text(
          l10n.onboardingRecapSubjectsCount(profile.subjects.length),
          style: AppTypography.h3,
        ),
        SizedBox(height: AppSpacing.s3.h),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.s3.w,
              mainAxisSpacing: AppSpacing.s3.h,
              childAspectRatio: 0.9,
            ),
            itemCount: profile.subjects.length,
            itemBuilder: (context, index) {
              final s = profile.subjects[index];
              return _SubjectCard(subject: s, langKey: langKey);
            },
          ),
        ),
        SizedBox(height: AppSpacing.s4.h),
        if (profile.canOptOut)
          TextButton(
            onPressed: () {
              // Story 1.4 — pas encore implementee.
              AppLogger.i(
                'Opt-out subjects tapped (Story 1.4 pending implementation)',
              );
            },
            child: Text(l10n.onboardingRecapOptOutLink),
          ),
        SizedBox(height: AppSpacing.s2.h),
        AppButton.primary(
          label: isCreating
              ? l10n.onboardingRecapCreatingLabel
              : l10n.onboardingRecapValidateCta,
          onPressed: isCreating ? null : onValidate,
          loading: isCreating,
        ),
        SizedBox(height: AppSpacing.s2.h),
        AppButton.secondary(
          label: l10n.back,
          onPressed: isCreating ? null : onBack,
        ),
      ],
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
      padding: EdgeInsets.all(AppSpacing.s3.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _iconFor(subject.icon),
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

  /// Mapping iconName -> IconData. Fallback `book-open` si non reconnu.
  IconData _iconFor(String iconName) {
    return switch (iconName) {
      'function-square' => LucideIcons.functionSquare,
      'atom' => LucideIcons.atom,
      'flask-conical' => LucideIcons.flaskConical,
      'dna' => LucideIcons.dna,
      'cog' => LucideIcons.cog,
      'book-open-text' => LucideIcons.bookOpenText,
      'languages' => LucideIcons.languages,
      'globe' => LucideIcons.globe,
      'brain' => LucideIcons.brain,
      'landmark' => LucideIcons.landmark,
      'scale' => LucideIcons.scale,
      'dumbbell' => LucideIcons.dumbbell,
      'wrench' => LucideIcons.wrench,
      'file-text' => LucideIcons.fileText,
      'calculator' => LucideIcons.calculator,
      'shopping-bag' => LucideIcons.shoppingBag,
      'sigma' => LucideIcons.sigma,
      'mountain' => LucideIcons.mountain,
      'trending-up' => LucideIcons.trendingUp,
      'code-2' => LucideIcons.code,
      'book' => LucideIcons.book,
      'book-marked' => LucideIcons.bookMarked,
      _ => LucideIcons.bookOpen,
    };
  }
}

class _RecapLoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _RecapErrorView extends StatelessWidget {
  const _RecapErrorView({required this.failure, required this.onBack});

  final CatalogueFailure failure;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (failure) {
      CatalogueNoMatchingRuleFailure() => l10n.onboardingRecapNoMatchingRule,
      _ => l10n.errorGeneric,
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.triangleAlert,
            color: AppColors.danger,
            size: 48.sp,
          ),
          SizedBox(height: AppSpacing.s4.h),
          Text(
            message,
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.s5.h),
          AppButton.secondary(
            label: l10n.back,
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}
