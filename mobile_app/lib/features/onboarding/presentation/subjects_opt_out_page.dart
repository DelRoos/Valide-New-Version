// Story 1.4 AC2 — Page de retrait conditionnel des matieres (FR-3).
//
// Affiche une liste de CheckboxListTile (1 par matiere derivee). Cochee = la
// matiere reste presentee a l'examen. Decochee = retiree (ajoutee a
// `users/{uid}.optedOutSubjects`).
//
// Garde in-component (AC6) : si derivedProfile.canOptOut == false, redirige
// immediatement vers /onboarding/profile/recap + log warn (subSystem + niveau,
// JAMAIS l'uid — CLAUDE.md securite 4).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/catalogue/domain/models.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers.dart';
import '_subject_icons.dart';

class SubjectsOptOutPage extends ConsumerStatefulWidget {
  const SubjectsOptOutPage({super.key});

  @override
  ConsumerState<SubjectsOptOutPage> createState() =>
      _SubjectsOptOutPageState();
}

class _SubjectsOptOutPageState extends ConsumerState<SubjectsOptOutPage> {
  /// IDs des matieres actuellement decochees (= retirees).
  /// Initialise depuis `users/{uid}.optedOutSubjects` au 1er snapshot.
  Set<String>? _optedOut;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subSystem = ref.watch(subSystemNotifierProvider);
    final derivedAsync = ref.watch(derivedProfileProvider);

    // Guard subSystem (defensive, le router devrait le couvrir).
    if (subSystem == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          GoRouter.of(context).go('/onboarding/subsystem');
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: derivedAsync.when(
          data: (either) => either.fold(
            (failure) {
              // Profil non resolu -> retour recap (cas edge si user atterrit
              // ici sans flow valide en memoire).
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  GoRouter.of(context).go('/onboarding/profile/recap');
                }
              });
              return const SizedBox.shrink();
            },
            (profile) {
              // AC6 — garde in-component : profil non eligible -> recap.
              if (!profile.canOptOut) {
                AppLogger.w(
                  'OptOut tentee sur profil non eligible: '
                  'subSystem=${subSystem.id} canOptOut=false',
                );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    GoRouter.of(context).go('/onboarding/profile/recap');
                  }
                });
                return const SizedBox.shrink();
              }
              return _OptOutBody(
                profile: profile,
                langKey: subSystem.languageCode,
                optedOut: _optedOut,
                isSaving: _isSaving,
                onInitOptedOut: _initOptedOutIfNeeded,
                onToggle: _onToggle,
                onValidate: () => _onValidate(profile),
                onCancel: () =>
                    GoRouter.of(context).go('/onboarding/profile/recap'),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: Text(
              l10n.errorGeneric,
              style: AppTypography.body.copyWith(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void _initOptedOutIfNeeded(List<String> initial) {
    if (_optedOut != null) return;
    setState(() => _optedOut = Set<String>.from(initial));
  }

  void _onToggle(String subjectId, bool included) {
    final current = _optedOut ?? <String>{};
    setState(() {
      _optedOut = Set<String>.from(current);
      if (included) {
        _optedOut!.remove(subjectId);
      } else {
        _optedOut!.add(subjectId);
      }
    });
  }

  Future<void> _onValidate(DerivedProfile profile) async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context);
    final opted = (_optedOut ?? <String>{}).toList(growable: false);

    setState(() => _isSaving = true);
    final result = await ref
        .read(userProfileRepositoryProvider)
        .updateOptedOutSubjects(opted);
    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) {
        AppLogger.w('updateOptedOutSubjects failed: ${failure.message}');
        AppToast.show(
          context,
          message: l10n.onboardingRecapFirestoreErrorToast,
          tone: ToastTone.warning,
        );
      },
      (_) {
        GoRouter.of(context).go('/onboarding/profile/recap');
      },
    );
  }
}

class _OptOutBody extends StatelessWidget {
  const _OptOutBody({
    required this.profile,
    required this.langKey,
    required this.optedOut,
    required this.isSaving,
    required this.onInitOptedOut,
    required this.onToggle,
    required this.onValidate,
    required this.onCancel,
  });

  final DerivedProfile profile;
  final String langKey;
  final Set<String>? optedOut;
  final bool isSaving;
  final void Function(List<String>) onInitOptedOut;
  final void Function(String subjectId, bool included) onToggle;
  final VoidCallback onValidate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Consumer(builder: (context, ref, _) {
      // Pre-populate _optedOut depuis users/{uid}.optedOutSubjects au 1er build.
      final profileStream = ref.watch(userProfileRepositoryProvider).watchProfile();
      return StreamBuilder<Map<String, dynamic>?>(
        stream: profileStream,
        builder: (context, snap) {
          if (optedOut == null) {
            // Attendre le 1er event du stream avant d'initialiser : sinon on
            // ecrirait `_optedOut = []` avant que les donnees Firestore ne
            // soient remontees, en perdant l'etat persiste.
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final initial =
                (snap.data?['optedOutSubjects'] as List?)?.cast<String>() ??
                    const <String>[];
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onInitOptedOut(initial);
            });
            return const Center(child: CircularProgressIndicator());
          }

          final total = profile.subjects.length;
          final takingCount = total - optedOut!.length;
          final canSave = takingCount > 0 && !isSaving;

          return LayoutBuilder(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.onboardingOptOutTitle,
                          style: AppTypography.h2,
                        ),
                        SizedBox(height: AppSpacing.s2.h),
                        Text(
                          l10n.onboardingOptOutSubtitle,
                          style: AppTypography.body.copyWith(
                            color: AppColors.inkSoft,
                          ),
                        ),
                        SizedBox(height: AppSpacing.s5.h),
                        Expanded(
                          child: ListView.separated(
                            itemCount: profile.subjects.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: AppSpacing.s2.h),
                            itemBuilder: (context, index) {
                              final s = profile.subjects[index];
                              final included = !optedOut!.contains(s.subjectId);
                              return CheckboxListTile(
                                value: included,
                                onChanged: isSaving
                                    ? null
                                    : (v) => onToggle(
                                          s.subjectId,
                                          v ?? false,
                                        ),
                                secondary: Icon(
                                  subjectIconFor(s.icon),
                                  color: AppColors.primary,
                                ),
                                title: Text(
                                  s.name[langKey] ??
                                      s.name['fr'] ??
                                      s.subjectId,
                                  style: AppTypography.bodyStrong,
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: AppColors.primary,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: AppSpacing.s4.h),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.listChecks,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                            SizedBox(width: AppSpacing.s2.w),
                            Expanded(
                              child: Text(
                                l10n.onboardingOptOutTakingCount(
                                  takingCount,
                                  total,
                                ),
                                style: AppTypography.bodyStrong,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.s3.h),
                        AppButton.primary(
                          label: l10n.onboardingOptOutValidateCta,
                          onPressed: canSave ? onValidate : null,
                          loading: isSaving,
                        ),
                        SizedBox(height: AppSpacing.s2.h),
                        AppButton.secondary(
                          label: l10n.back,
                          onPressed: isSaving ? null : onCancel,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    });
  }
}
