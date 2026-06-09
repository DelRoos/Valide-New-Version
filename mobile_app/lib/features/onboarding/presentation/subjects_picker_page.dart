// Story 1.4 + 1.15 — Page polymorphe de selection des matieres (FR-3).
//
// Dispatch sur `DerivedProfile.pickerMode` (Story 1.13, ADR-016) :
//   - PickerMode.derived            -> redirect immediate recap (Fatou Tle D)
//   - PickerMode.optOut             -> _LegacyOptOutBody (James Upper Sixth S2,
//                                     pattern Story 1.4 quasi-litteral)
//   - PickerMode.freeWithObligatory -> _FreeWithObligatoryBody NEW (Mariam
//                                     Form 5, panier O-Level 2 sections)
//   - PickerMode.seriesPlusOptional -> placeholder Story 1.16 (redirect recap)
//   - PickerMode.tvePicker          -> placeholder Story 1.17 (redirect recap)
//
// Garde in-component : si derivedProfile.canOptOut == false ET pickerMode ==
// derived, redirige immediatement vers /onboarding/profile/recap + log warn
// (subSystem + niveau, JAMAIS l'uid -- CLAUDE.md securite 4).

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

class SubjectsPickerPage extends ConsumerStatefulWidget {
  const SubjectsPickerPage({super.key});

  @override
  ConsumerState<SubjectsPickerPage> createState() => _SubjectsPickerPageState();
}

class _SubjectsPickerPageState extends ConsumerState<SubjectsPickerPage> {
  /// IDs des matieres actuellement decochees (mode legacy `optOut`).
  /// Initialise depuis `users/{uid}.optedOutSubjects` au 1er snapshot.
  Set<String>? _optedOut;

  /// IDs des matieres optionnelles actuellement selectionnees (mode
  /// `freeWithObligatory`). Ne contient PAS les obligatoires (forcees en
  /// permanence). Initialise depuis `users/{uid}.pickedSubjects` au 1er snap.
  Set<String>? _pickedOptional;

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
            (profile) => _dispatchByPickerMode(
              context: context,
              profile: profile,
              langKey: subSystem.languageCode,
            ),
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

  /// Dispatch central Story 1.15 sur `profile.pickerMode`. 5 cas, 3
  /// placeholders (derived + seriesPlusOptional + tvePicker -> redirect recap).
  Widget _dispatchByPickerMode({
    required BuildContext context,
    required DerivedProfile profile,
    required String langKey,
  }) {
    switch (profile.pickerMode) {
      case PickerMode.derived:
        // Mode v1 default : matieres dérivées non modifiables. Si Fatou tape
        // /picker direct (cas impossible nominal car lien Story 1.3 masqué
        // quand canOptOut: false), defensive redirect recap.
        AppLogger.w(
          'PickerPage: pickerMode=derived canOptOut=${profile.canOptOut} '
          'redirect to recap',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            GoRouter.of(context).go('/onboarding/profile/recap');
          }
        });
        return const SizedBox.shrink();

      case PickerMode.optOut:
        // Mode v1 legacy Story 1.4 (James Upper Sixth S2). Layout inchangé.
        return _LegacyOptOutBody(
          profile: profile,
          langKey: langKey,
          optedOut: _optedOut,
          isSaving: _isSaving,
          onInitOptedOut: _initOptedOutIfNeeded,
          onToggle: _onToggleOptOut,
          onValidate: () => _onValidateOptOut(profile),
          onCancel: () =>
              GoRouter.of(context).go('/onboarding/profile/recap'),
        );

      case PickerMode.freeWithObligatory:
        // Mode v2 NEW Story 1.15 (Mariam Form 5). Panier O-Level 2 sections.
        return _FreeWithObligatoryBody(
          profile: profile,
          langKey: langKey,
          picked: _pickedOptional,
          isSaving: _isSaving,
          onInitPicked: _initPickedOptionalIfNeeded,
          onToggleOptional: _onToggleOptional,
          onTapObligatory: _onTapObligatory,
          onValidate: () => _onValidatePicked(profile),
          onCancel: () =>
              GoRouter.of(context).go('/onboarding/profile/recap'),
        );

      case PickerMode.seriesPlusOptional:
        // Mode v2 NEW Story 1.16 (James Upper Sixth S2 + ICT). Series A-Level
        // figees (3-4 matieres) + transversales optionnelles (max 5 total).
        return _SeriesPlusOptionalBody(
          profile: profile,
          langKey: langKey,
          picked: _pickedOptional,
          isSaving: _isSaving,
          onInitPicked: _initPickedOptionalIfNeeded,
          onToggleOptional: _onToggleOptional,
          onTapObligatory: _onTapObligatory,
          onValidate: () => _onValidatePicked(profile),
          onCancel: () =>
              GoRouter.of(context).go('/onboarding/profile/recap'),
        );

      case PickerMode.tvePicker:
        // Mode v3 NEW Story 1.17 (Eyong TVE AL Electrotechnique). 3 sections :
        // Professional Subjects + Related Professional Subjects + Other (mix
        // EN/FR locked + Hist/Geo/RS interactif).
        return _TvePickerBody(
          profile: profile,
          langKey: langKey,
          picked: _pickedOptional,
          isSaving: _isSaving,
          onInitPicked: _initPickedOptionalIfNeeded,
          onToggleOptional: _onToggleOptional,
          onTapObligatory: _onTapObligatory,
          onValidate: () => _onValidatePicked(profile),
          onCancel: () =>
              GoRouter.of(context).go('/onboarding/profile/recap'),
        );
    }
  }

  // ===================================================================
  // Mode legacy optOut (Story 1.4) — handlers preserves
  // ===================================================================

  void _initOptedOutIfNeeded(List<String> initial) {
    if (_optedOut != null) return;
    setState(() => _optedOut = Set<String>.from(initial));
  }

  void _onToggleOptOut(String subjectId, bool included) {
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

  Future<void> _onValidateOptOut(DerivedProfile profile) async {
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

  // ===================================================================
  // Mode freeWithObligatory (Story 1.15) — handlers NEW
  // ===================================================================

  void _initPickedOptionalIfNeeded(List<String> initial) {
    if (_pickedOptional != null) return;
    setState(() => _pickedOptional = Set<String>.from(initial));
  }

  void _onToggleOptional(String subjectId, bool selected) {
    final current = _pickedOptional ?? <String>{};
    setState(() {
      _pickedOptional = Set<String>.from(current);
      if (selected) {
        _pickedOptional!.add(subjectId);
      } else {
        _pickedOptional!.remove(subjectId);
      }
    });
  }

  void _onTapObligatory(String subjectId) {
    // CLAUDE.md securite 4 : ID matiere n'est PAS du PII direct, OK a logger
    // pour debug, mais bref. Pas de console flood.
    AppLogger.w('PickerPage: tap obligatoire bloque subject=$subjectId');
    final l10n = AppLocalizations.of(context);
    AppToast.show(
      context,
      message: l10n.onboardingPickerErrorObligatoryToast,
      tone: ToastTone.warning,
    );
  }

  Future<void> _onValidatePicked(DerivedProfile profile) async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context);

    // CRITIQUE : la liste posee Firestore DOIT contenir oblig + optionnels
    // selectionnes (cf. BASE-DE-DONNEES.md ligne 75, story Decision 3).
    //
    // Story 1.17 — Decision 5 figee : branchement conditionnel TVEE-specifique.
    // Ordre TVEE : [Pro, Related, Obligatoires EN+FR, Optionnels selectionnes].
    // Ordre 1.15+1.16 : [Obligatoires, Optionnels] - inchange.
    final List<String> allPicked;
    if (profile.pickerMode == PickerMode.tvePicker) {
      allPicked = <String>[
        ...profile.professionalSubjects.map((s) => s.subjectId),
        ...profile.relatedProfessionalSubjects.map((s) => s.subjectId),
        ...profile.obligatorySubjects.map((s) => s.subjectId),
        ...(_pickedOptional ?? <String>{}),
      ];
    } else {
      // Pattern Story 1.15 + 1.16 — inchange pour freeWithObligatory +
      // seriesPlusOptional.
      allPicked = <String>[
        ...profile.obligatorySubjects.map((s) => s.subjectId),
        ...(_pickedOptional ?? <String>{}),
      ];
    }

    setState(() => _isSaving = true);
    final result = await ref
        .read(userProfileRepositoryProvider)
        .updatePickedSubjects(allPicked);
    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) {
        AppLogger.w('updatePickedSubjects failed: ${failure.message}');
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

// ============================================================================
// _LegacyOptOutBody — copie quasi-litterale du _OptOutBody Story 1.4. Aucun
// changement logique : preserve les 3 widget tests Story 1.4 (AC6 strict).
// ============================================================================

class _LegacyOptOutBody extends StatelessWidget {
  const _LegacyOptOutBody({
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
      final profileStream =
          ref.watch(userProfileRepositoryProvider).watchProfile();
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

// ============================================================================
// _FreeWithObligatoryBody — NEW Story 1.15 (Mariam Form 5 panier O-Level).
//
// 2 sections empilees :
//   1. "Matieres obligatoires" : N checkboxes checked + disabled + cadenas.
//      Tap -> onTapObligatory (toast warning + log warn).
//   2. "Matieres au choix" : N checkboxes interactifs.
//      Init depuis users/{uid}.pickedSubjects (modulo retrait des obligatoires
//      qui y sont aussi).
//
// Compteur live + couleur conditionnelle (primary si valide, danger sinon).
// Bouton Valider active si pickedTotal ∈ [minSubjects, maxSubjects].
// ============================================================================

class _FreeWithObligatoryBody extends StatelessWidget {
  const _FreeWithObligatoryBody({
    required this.profile,
    required this.langKey,
    required this.picked,
    required this.isSaving,
    required this.onInitPicked,
    required this.onToggleOptional,
    required this.onTapObligatory,
    required this.onValidate,
    required this.onCancel,
  });

  final DerivedProfile profile;
  final String langKey;
  final Set<String>? picked;
  final bool isSaving;
  final void Function(List<String>) onInitPicked;
  final void Function(String subjectId, bool selected) onToggleOptional;
  final void Function(String subjectId) onTapObligatory;
  final VoidCallback onValidate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Consumer(builder: (context, ref, _) {
      final profileStream =
          ref.watch(userProfileRepositoryProvider).watchProfile();
      return StreamBuilder<Map<String, dynamic>?>(
        stream: profileStream,
        builder: (context, snap) {
          if (picked == null) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            // Lire `pickedSubjects` initial Firestore + retirer les
            // obligatoires (forcees en permanence cote UI -> ne pas les
            // afficher cochees deux fois).
            final pickedFromFs =
                (snap.data?['pickedSubjects'] as List?)?.cast<String>() ??
                    const <String>[];
            final obligIds =
                profile.obligatorySubjects.map((s) => s.subjectId).toSet();
            final optionalOnly = pickedFromFs
                .where((id) => !obligIds.contains(id))
                .toList(growable: false);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onInitPicked(optionalOnly);
            });
            return const Center(child: CircularProgressIndicator());
          }

          final obligCount = profile.obligatorySubjects.length;
          final optionalSelected = picked!.length;
          final pickedTotal = obligCount + optionalSelected;

          final min = profile.minSubjects ?? 1;
          final max = profile.maxSubjects ?? (profile.subjects.length);
          final isWithinBounds = pickedTotal >= min && pickedTotal <= max;
          final canSave = isWithinBounds && !isSaving;

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
                        // -- Titre H2 + sous-titre ---
                        Text(
                          l10n.onboardingPickerTitle,
                          style: AppTypography.h2,
                        ),
                        SizedBox(height: AppSpacing.s2.h),
                        Text(
                          l10n.onboardingPickerSubtitle,
                          style: AppTypography.body.copyWith(
                            color: AppColors.inkSoft,
                          ),
                        ),
                        SizedBox(height: AppSpacing.s5.h),

                        // -- Sections scrollables (ListView parent) ---
                        Expanded(
                          child: ListView(
                            children: [
                              // -- Section obligatoires ---
                              Text(
                                l10n.onboardingPickerObligatoryTitle,
                                style: AppTypography.h3,
                              ),
                              SizedBox(height: AppSpacing.s2.h),
                              ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: profile.obligatorySubjects.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(height: AppSpacing.s2.h),
                                itemBuilder: (context, index) {
                                  final s = profile.obligatorySubjects[index];
                                  return CheckboxListTile(
                                    value: true,
                                    onChanged: isSaving
                                        ? null
                                        : (_) => onTapObligatory(s.subjectId),
                                    secondary: Icon(
                                      LucideIcons.lock,
                                      color: AppColors.primary,
                                      size: 18.sp,
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

                              SizedBox(height: AppSpacing.s5.h),

                              // -- Section optionnels ---
                              Text(
                                l10n.onboardingPickerOptionalTitle,
                                style: AppTypography.h3,
                              ),
                              SizedBox(height: AppSpacing.s2.h),
                              ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: profile.optionalSubjects.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(height: AppSpacing.s2.h),
                                itemBuilder: (context, index) {
                                  final s = profile.optionalSubjects[index];
                                  final selected =
                                      picked!.contains(s.subjectId);
                                  return CheckboxListTile(
                                    value: selected,
                                    onChanged: isSaving
                                        ? null
                                        : (v) => onToggleOptional(
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
                            ],
                          ),
                        ),

                        SizedBox(height: AppSpacing.s4.h),

                        // -- Compteur live (couleur conditionnelle) ---
                        Row(
                          children: [
                            Icon(
                              LucideIcons.listChecks,
                              color: isWithinBounds
                                  ? AppColors.primary
                                  : AppColors.danger,
                              size: 20.sp,
                            ),
                            SizedBox(width: AppSpacing.s2.w),
                            Expanded(
                              child: Text(
                                l10n.onboardingPickerCounterLive(
                                  pickedTotal,
                                  max,
                                ),
                                style: AppTypography.bodyStrong.copyWith(
                                  color: isWithinBounds
                                      ? AppColors.primary
                                      : AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.s3.h),
                        AppButton.primary(
                          label: l10n.onboardingPickerValidateCta,
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

// ============================================================================
// _SeriesPlusOptionalBody — NEW Story 1.16 (James Upper Sixth S2 + ICT).
//
// 2 sections empilees (semantique A-Level GCE Board) :
//   1. "Series (obligatoires)" : Series figee 3-4 matieres lockees + cadenas.
//      Tap -> onTapObligatory (toast warning + log warn).
//   2. "Transversales optionnelles" : Computer Science / ICT / Religious
//      Studies / Commerce - checkboxes interactives ajoutables jusqu'a max 5.
//      Init depuis users/{uid}.pickedSubjects (modulo retrait des Series qui
//      y sont aussi).
//
// Compteur live + couleur conditionnelle (primary si valide, danger sinon).
// Bouton Valider active si pickedTotal ∈ [minSubjects, maxSubjects].
//
// Decision 2 Story 1.16 figee : copie quasi-litterale de _FreeWithObligatoryBody
// (3 differences semantiques uniquement : 2 cles ARB titres + meme cadenas).
// Pas de refactor generique - ROI negatif a 2 widgets.
// ============================================================================

class _SeriesPlusOptionalBody extends StatelessWidget {
  const _SeriesPlusOptionalBody({
    required this.profile,
    required this.langKey,
    required this.picked,
    required this.isSaving,
    required this.onInitPicked,
    required this.onToggleOptional,
    required this.onTapObligatory,
    required this.onValidate,
    required this.onCancel,
  });

  final DerivedProfile profile;
  final String langKey;
  final Set<String>? picked;
  final bool isSaving;
  final void Function(List<String>) onInitPicked;
  final void Function(String subjectId, bool selected) onToggleOptional;
  final void Function(String subjectId) onTapObligatory;
  final VoidCallback onValidate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Consumer(builder: (context, ref, _) {
      final profileStream =
          ref.watch(userProfileRepositoryProvider).watchProfile();
      return StreamBuilder<Map<String, dynamic>?>(
        stream: profileStream,
        builder: (context, snap) {
          if (picked == null) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            // Lire `pickedSubjects` initial Firestore + retirer les Series
            // (forcees en permanence cote UI -> ne pas les afficher cochees
            // deux fois).
            final pickedFromFs =
                (snap.data?['pickedSubjects'] as List?)?.cast<String>() ??
                    const <String>[];
            final seriesIds =
                profile.obligatorySubjects.map((s) => s.subjectId).toSet();
            final transversalesOnly = pickedFromFs
                .where((id) => !seriesIds.contains(id))
                .toList(growable: false);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onInitPicked(transversalesOnly);
            });
            return const Center(child: CircularProgressIndicator());
          }

          final seriesCount = profile.obligatorySubjects.length;
          final transversalesSelected = picked!.length;
          final pickedTotal = seriesCount + transversalesSelected;

          final min = profile.minSubjects ?? 1;
          final max = profile.maxSubjects ?? (profile.subjects.length);
          final isWithinBounds = pickedTotal >= min && pickedTotal <= max;
          final canSave = isWithinBounds && !isSaving;

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
                        // -- Titre H2 + sous-titre (reutilise cles Story 1.15) -
                        Text(
                          l10n.onboardingPickerTitle,
                          style: AppTypography.h2,
                        ),
                        SizedBox(height: AppSpacing.s2.h),
                        Text(
                          l10n.onboardingPickerSubtitle,
                          style: AppTypography.body.copyWith(
                            color: AppColors.inkSoft,
                          ),
                        ),
                        SizedBox(height: AppSpacing.s5.h),

                        // -- Sections scrollables (ListView parent) ---
                        Expanded(
                          child: ListView(
                            children: [
                              // -- Section Series (obligatoires) NEW Story 1.16
                              Text(
                                l10n.onboardingPickerSeriesTitle,
                                style: AppTypography.h3,
                              ),
                              SizedBox(height: AppSpacing.s2.h),
                              ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: profile.obligatorySubjects.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(height: AppSpacing.s2.h),
                                itemBuilder: (context, index) {
                                  final s = profile.obligatorySubjects[index];
                                  return CheckboxListTile(
                                    value: true,
                                    onChanged: isSaving
                                        ? null
                                        : (_) => onTapObligatory(s.subjectId),
                                    secondary: Icon(
                                      LucideIcons.lock,
                                      color: AppColors.primary,
                                      size: 18.sp,
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

                              SizedBox(height: AppSpacing.s5.h),

                              // -- Section Transversales (optionnelles) NEW
                              Text(
                                l10n.onboardingPickerTransversalesTitle,
                                style: AppTypography.h3,
                              ),
                              SizedBox(height: AppSpacing.s2.h),
                              ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: profile.optionalSubjects.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(height: AppSpacing.s2.h),
                                itemBuilder: (context, index) {
                                  final s = profile.optionalSubjects[index];
                                  final selected =
                                      picked!.contains(s.subjectId);
                                  return CheckboxListTile(
                                    value: selected,
                                    onChanged: isSaving
                                        ? null
                                        : (v) => onToggleOptional(
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
                            ],
                          ),
                        ),

                        SizedBox(height: AppSpacing.s4.h),

                        // -- Compteur live (couleur conditionnelle) ---
                        Row(
                          children: [
                            Icon(
                              LucideIcons.listChecks,
                              color: isWithinBounds
                                  ? AppColors.primary
                                  : AppColors.danger,
                              size: 20.sp,
                            ),
                            SizedBox(width: AppSpacing.s2.w),
                            Expanded(
                              child: Text(
                                l10n.onboardingPickerCounterLive(
                                  pickedTotal,
                                  max,
                                ),
                                style: AppTypography.bodyStrong.copyWith(
                                  color: isWithinBounds
                                      ? AppColors.primary
                                      : AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.s3.h),
                        AppButton.primary(
                          label: l10n.onboardingPickerValidateCta,
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

// ============================================================================
// _TvePickerBody — NEW Story 1.17 (Eyong TVE AL Electrotechnique).
//
// 3 sections empilees (semantique TVEE GCE Board) :
//   1. "Matieres professionnelles (obligatoires)" : profile.professionalSubjects
//      lockees + cadenas (Ex. ELET : Electrotechnique theory/practical/Electrical
//      machines). Tap -> onTapObligatory (toast warning).
//   2. "Matieres connexes (obligatoires)" : profile.relatedProfessionalSubjects
//      lockees + cadenas (Ex. ELET : Math Industrial / Physics / Drawing).
//      Tap -> onTapObligatory.
//   3. "Autres matieres" : Mix
//      - Obligatoires Other : profile.obligatorySubjects (EN+FR) lockees + cadenas.
//      - Au choix : profile.optionalSubjects (Hist/Geo/RS) interactives.
//
// Init depuis users/{uid}.pickedSubjects : retirer les 3 ensembles lockes
// (Pro + Related + Obligatoires Other) pour pre-populer _pickedOptional avec
// uniquement les au-choix selectionnes.
//
// Compteur live + couleur conditionnelle (primary si valide, danger sinon).
// pickedTotal = Pro + Related + Obligatoires + picked.length (auto-comptes).
// Bouton Valider active si pickedTotal in [minSubjects, maxSubjects].
//
// Decision 3 Story 1.17 figee : copie quasi-litterale de _SeriesPlusOptionalBody
// avec 1 section additionnelle (Pro) + sous-loops dans Other. Pas de refactor
// generique - ROI negatif a 3 widgets.
// ============================================================================

class _TvePickerBody extends StatelessWidget {
  const _TvePickerBody({
    required this.profile,
    required this.langKey,
    required this.picked,
    required this.isSaving,
    required this.onInitPicked,
    required this.onToggleOptional,
    required this.onTapObligatory,
    required this.onValidate,
    required this.onCancel,
  });

  final DerivedProfile profile;
  final String langKey;
  final Set<String>? picked;
  final bool isSaving;
  final void Function(List<String>) onInitPicked;
  final void Function(String subjectId, bool selected) onToggleOptional;
  final void Function(String subjectId) onTapObligatory;
  final VoidCallback onValidate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Consumer(builder: (context, ref, _) {
      final profileStream =
          ref.watch(userProfileRepositoryProvider).watchProfile();
      return StreamBuilder<Map<String, dynamic>?>(
        stream: profileStream,
        builder: (context, snap) {
          if (picked == null) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final pickedFromFs =
                (snap.data?['pickedSubjects'] as List?)?.cast<String>() ??
                    const <String>[];
            final lockedIds = <String>{
              ...profile.professionalSubjects.map((s) => s.subjectId),
              ...profile.relatedProfessionalSubjects.map((s) => s.subjectId),
              ...profile.obligatorySubjects.map((s) => s.subjectId),
            };
            final optionalsOnly = pickedFromFs
                .where((id) => !lockedIds.contains(id))
                .toList(growable: false);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onInitPicked(optionalsOnly);
            });
            return const Center(child: CircularProgressIndicator());
          }

          final proCount = profile.professionalSubjects.length;
          final relatedCount = profile.relatedProfessionalSubjects.length;
          final obligCount = profile.obligatorySubjects.length;
          final optionalSelected = picked!.length;
          final pickedTotal =
              proCount + relatedCount + obligCount + optionalSelected;

          final min = profile.minSubjects ?? 1;
          final max = profile.maxSubjects ?? (profile.subjects.length);
          final isWithinBounds = pickedTotal >= min && pickedTotal <= max;
          final canSave = isWithinBounds && !isSaving;

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
                          l10n.onboardingPickerTitle,
                          style: AppTypography.h2,
                        ),
                        SizedBox(height: AppSpacing.s2.h),
                        Text(
                          l10n.onboardingPickerSubtitle,
                          style: AppTypography.body.copyWith(
                            color: AppColors.inkSoft,
                          ),
                        ),
                        SizedBox(height: AppSpacing.s5.h),
                        Expanded(
                          child: ListView(
                            children: [
                              Text(
                                l10n.onboardingPickerProfessionalTitle,
                                style: AppTypography.h3,
                              ),
                              SizedBox(height: AppSpacing.s2.h),
                              ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount:
                                    profile.professionalSubjects.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(height: AppSpacing.s2.h),
                                itemBuilder: (context, index) {
                                  final s =
                                      profile.professionalSubjects[index];
                                  return CheckboxListTile(
                                    value: true,
                                    onChanged: isSaving
                                        ? null
                                        : (_) => onTapObligatory(s.subjectId),
                                    secondary: Icon(
                                      LucideIcons.lock,
                                      color: AppColors.primary,
                                      size: 18.sp,
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
                              SizedBox(height: AppSpacing.s5.h),
                              Text(
                                l10n.onboardingPickerRelatedTitle,
                                style: AppTypography.h3,
                              ),
                              SizedBox(height: AppSpacing.s2.h),
                              ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: profile
                                    .relatedProfessionalSubjects.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(height: AppSpacing.s2.h),
                                itemBuilder: (context, index) {
                                  final s = profile
                                      .relatedProfessionalSubjects[index];
                                  return CheckboxListTile(
                                    value: true,
                                    onChanged: isSaving
                                        ? null
                                        : (_) => onTapObligatory(s.subjectId),
                                    secondary: Icon(
                                      LucideIcons.lock,
                                      color: AppColors.primary,
                                      size: 18.sp,
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
                              SizedBox(height: AppSpacing.s5.h),
                              Text(
                                l10n.onboardingPickerOtherTitle,
                                style: AppTypography.h3,
                              ),
                              SizedBox(height: AppSpacing.s2.h),
                              ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: profile.obligatorySubjects.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(height: AppSpacing.s2.h),
                                itemBuilder: (context, index) {
                                  final s = profile.obligatorySubjects[index];
                                  return CheckboxListTile(
                                    value: true,
                                    onChanged: isSaving
                                        ? null
                                        : (_) => onTapObligatory(s.subjectId),
                                    secondary: Icon(
                                      LucideIcons.lock,
                                      color: AppColors.primary,
                                      size: 18.sp,
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
                              SizedBox(height: AppSpacing.s2.h),
                              ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: profile.optionalSubjects.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(height: AppSpacing.s2.h),
                                itemBuilder: (context, index) {
                                  final s = profile.optionalSubjects[index];
                                  final selected =
                                      picked!.contains(s.subjectId);
                                  return CheckboxListTile(
                                    value: selected,
                                    onChanged: isSaving
                                        ? null
                                        : (v) => onToggleOptional(
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
                            ],
                          ),
                        ),
                        SizedBox(height: AppSpacing.s4.h),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.listChecks,
                              color: isWithinBounds
                                  ? AppColors.primary
                                  : AppColors.danger,
                              size: 20.sp,
                            ),
                            SizedBox(width: AppSpacing.s2.w),
                            Expanded(
                              child: Text(
                                l10n.onboardingPickerCounterLive(
                                  pickedTotal,
                                  max,
                                ),
                                style: AppTypography.bodyStrong.copyWith(
                                  color: isWithinBounds
                                      ? AppColors.primary
                                      : AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.s3.h),
                        AppButton.primary(
                          label: l10n.onboardingPickerValidateCta,
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