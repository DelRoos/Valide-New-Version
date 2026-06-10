// Story 1.4 + 1.15 + 1.16 + 1.17 — Page polymorphe de selection des matieres
// (FR-3). Refactor Story 1.18 : les 4 ex-widgets prives _LegacyOptOutBody /
// _FreeWithObligatoryBody / _SeriesPlusOptionalBody / _TvePickerBody ont ete
// supprimes et remplaces par composition des composants partages :
//   - PickerSectionScaffold (wrapper responsive page-level)
//   - ObligatorySubjectCheckboxList (sous-section verrouillee + cadenas)
//   - OptionalSubjectCheckboxList (sous-section interactive)
//   - PickerValidateBar (compteur + 2 boutons)
//
// Dispatch sur `DerivedProfile.pickerMode` (Story 1.13, ADR-016) :
//   - PickerMode.derived            -> redirect immediate recap (Fatou Tle D)
//   - PickerMode.optOut             -> _buildOptOutBody (James Upper Sixth S2,
//                                     pattern Story 1.4)
//   - PickerMode.freeWithObligatory -> _buildFreeWithObligatoryBody (Mariam
//                                     Form 5, panier O-Level 2 sections)
//   - PickerMode.seriesPlusOptional -> _buildSeriesPlusOptionalBody (James S2
//                                     + ICT, A-Level transversales)
//   - PickerMode.tvePicker          -> _buildTvePickerBody (Eyong TVE AL,
//                                     3 sections TVEE)
//
// Garde in-component : si derivedProfile.canOptOut == false ET pickerMode ==
// derived, redirige immediatement vers /onboarding/profile/recap + log warn
// (subSystem + niveau, JAMAIS l'uid -- CLAUDE.md securite 4).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/catalogue/domain/models.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/picker/obligatory_subject_checkbox_list.dart';
import '../../../core/widgets/picker/optional_subject_checkbox_list.dart';
import '../../../core/widgets/picker/picker_section_scaffold.dart';
import '../../../core/widgets/picker/picker_validate_bar.dart';
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

  /// IDs des matieres optionnelles actuellement selectionnees (modes v2/v3).
  /// Initialise depuis `users/{uid}.pickedSubjects` au 1er snapshot.
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

  /// Dispatch central sur `profile.pickerMode`. Refactor Story 1.18 : appelle
  /// les builders prives qui composent les composants partages.
  Widget _dispatchByPickerMode({
    required BuildContext context,
    required DerivedProfile profile,
    required String langKey,
  }) {
    switch (profile.pickerMode) {
      case PickerMode.derived:
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
        return _PickerStreamGate(
          isStateReady: _optedOut != null,
          initFromFs: (data) {
            final initial =
                (data?['optedOutSubjects'] as List?)?.cast<String>() ??
                    const <String>[];
            _initOptedOutIfNeeded(initial);
          },
          builder: () => _buildOptOutBody(profile, langKey),
        );

      case PickerMode.freeWithObligatory:
        return _PickerStreamGate(
          isStateReady: _pickedOptional != null,
          initFromFs: (data) {
            final pickedFromFs =
                (data?['pickedSubjects'] as List?)?.cast<String>() ??
                    const <String>[];
            final obligIds =
                profile.obligatorySubjects.map((s) => s.subjectId).toSet();
            final optionalOnly = pickedFromFs
                .where((id) => !obligIds.contains(id))
                .toList(growable: false);
            _initPickedOptionalIfNeeded(optionalOnly);
          },
          builder: () => _buildFreeWithObligatoryBody(profile, langKey),
        );

      case PickerMode.seriesPlusOptional:
        return _PickerStreamGate(
          isStateReady: _pickedOptional != null,
          initFromFs: (data) {
            final pickedFromFs =
                (data?['pickedSubjects'] as List?)?.cast<String>() ??
                    const <String>[];
            final seriesIds =
                profile.obligatorySubjects.map((s) => s.subjectId).toSet();
            final transversalesOnly = pickedFromFs
                .where((id) => !seriesIds.contains(id))
                .toList(growable: false);
            _initPickedOptionalIfNeeded(transversalesOnly);
          },
          builder: () => _buildSeriesPlusOptionalBody(profile, langKey),
        );

      case PickerMode.tvePicker:
        return _PickerStreamGate(
          isStateReady: _pickedOptional != null,
          initFromFs: (data) {
            final pickedFromFs =
                (data?['pickedSubjects'] as List?)?.cast<String>() ??
                    const <String>[];
            final lockedIds = <String>{
              ...profile.professionalSubjects.map((s) => s.subjectId),
              ...profile.relatedProfessionalSubjects.map((s) => s.subjectId),
              ...profile.obligatorySubjects.map((s) => s.subjectId),
            };
            final optionalsOnly = pickedFromFs
                .where((id) => !lockedIds.contains(id))
                .toList(growable: false);
            _initPickedOptionalIfNeeded(optionalsOnly);
          },
          builder: () => _buildTvePickerBody(profile, langKey),
        );
    }
  }

  // ===================================================================
  // Body builders — composition des composants partages
  // ===================================================================

  Widget _buildOptOutBody(DerivedProfile profile, String langKey) {
    final l10n = AppLocalizations.of(context);
    final total = profile.subjects.length;
    final takingCount = total - _optedOut!.length;
    final canSave = takingCount > 0;

    // Mode opt-out : derive "picked" depuis subjects - optedOut.
    final picked = profile.subjects
        .map((s) => s.subjectId)
        .where((id) => !_optedOut!.contains(id))
        .toSet();

    return PickerSectionScaffold(
      title: l10n.onboardingOptOutTitle,
      subtitle: l10n.onboardingOptOutSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: OptionalSubjectCheckboxList(
              subjects: profile.subjects,
              picked: picked,
              onToggle: (subjectId, selected) =>
                  _onToggleOptOut(subjectId, selected),
              langKey: langKey,
              isSaving: _isSaving,
              iconResolver: subjectIconFor,
              shrinkWrap: false,
            ),
          ),
          SizedBox(height: AppSpacing.s4.h),
          PickerValidateBar(
            counterText: l10n.onboardingOptOutTakingCount(takingCount, total),
            isValid: canSave,
            isSaving: _isSaving,
            onValidate: () => _onValidateOptOut(profile),
            onCancel: () =>
                GoRouter.of(context).go('/onboarding/profile/recap'),
            validateLabel: l10n.onboardingOptOutValidateCta,
            cancelLabel: l10n.back,
          ),
        ],
      ),
    );
  }

  Widget _buildFreeWithObligatoryBody(DerivedProfile profile, String langKey) {
    final l10n = AppLocalizations.of(context);
    final obligCount = profile.obligatorySubjects.length;
    final pickedTotal = obligCount + _pickedOptional!.length;
    final min = profile.minSubjects ?? 1;
    final max = profile.maxSubjects ?? profile.subjects.length;
    final isWithinBounds = pickedTotal >= min && pickedTotal <= max;

    return PickerSectionScaffold(
      title: l10n.onboardingPickerTitle,
      subtitle: l10n.onboardingPickerSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                Text(
                  l10n.onboardingPickerObligatoryTitle,
                  style: AppTypography.h3,
                ),
                SizedBox(height: AppSpacing.s2.h),
                ObligatorySubjectCheckboxList(
                  subjects: profile.obligatorySubjects,
                  langKey: langKey,
                  isSaving: _isSaving,
                  onTapBlocked: _onTapObligatory,
                ),
                SizedBox(height: AppSpacing.s5.h),
                Text(
                  l10n.onboardingPickerOptionalTitle,
                  style: AppTypography.h3,
                ),
                SizedBox(height: AppSpacing.s2.h),
                OptionalSubjectCheckboxList(
                  subjects: profile.optionalSubjects,
                  picked: _pickedOptional!,
                  onToggle: _onToggleOptional,
                  langKey: langKey,
                  isSaving: _isSaving,
                  iconResolver: subjectIconFor,
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.s4.h),
          PickerValidateBar(
            counterText: l10n.onboardingPickerCounterLive(pickedTotal, max),
            isValid: isWithinBounds,
            isSaving: _isSaving,
            onValidate: () => _onValidatePicked(profile),
            onCancel: () =>
                GoRouter.of(context).go('/onboarding/profile/recap'),
            validateLabel: l10n.onboardingPickerValidateCta,
            cancelLabel: l10n.back,
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesPlusOptionalBody(DerivedProfile profile, String langKey) {
    final l10n = AppLocalizations.of(context);
    final seriesCount = profile.obligatorySubjects.length;
    final pickedTotal = seriesCount + _pickedOptional!.length;
    final min = profile.minSubjects ?? 1;
    final max = profile.maxSubjects ?? profile.subjects.length;
    final isWithinBounds = pickedTotal >= min && pickedTotal <= max;

    return PickerSectionScaffold(
      title: l10n.onboardingPickerTitle,
      subtitle: l10n.onboardingPickerSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                Text(
                  l10n.onboardingPickerSeriesTitle,
                  style: AppTypography.h3,
                ),
                SizedBox(height: AppSpacing.s2.h),
                ObligatorySubjectCheckboxList(
                  subjects: profile.obligatorySubjects,
                  langKey: langKey,
                  isSaving: _isSaving,
                  onTapBlocked: _onTapObligatory,
                ),
                SizedBox(height: AppSpacing.s5.h),
                Text(
                  l10n.onboardingPickerTransversalesTitle,
                  style: AppTypography.h3,
                ),
                SizedBox(height: AppSpacing.s2.h),
                OptionalSubjectCheckboxList(
                  subjects: profile.optionalSubjects,
                  picked: _pickedOptional!,
                  onToggle: _onToggleOptional,
                  langKey: langKey,
                  isSaving: _isSaving,
                  iconResolver: subjectIconFor,
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.s4.h),
          PickerValidateBar(
            counterText: l10n.onboardingPickerCounterLive(pickedTotal, max),
            isValid: isWithinBounds,
            isSaving: _isSaving,
            onValidate: () => _onValidatePicked(profile),
            onCancel: () =>
                GoRouter.of(context).go('/onboarding/profile/recap'),
            validateLabel: l10n.onboardingPickerValidateCta,
            cancelLabel: l10n.back,
          ),
        ],
      ),
    );
  }

  Widget _buildTvePickerBody(DerivedProfile profile, String langKey) {
    final l10n = AppLocalizations.of(context);
    final proCount = profile.professionalSubjects.length;
    final relatedCount = profile.relatedProfessionalSubjects.length;
    final obligCount = profile.obligatorySubjects.length;
    final pickedTotal =
        proCount + relatedCount + obligCount + _pickedOptional!.length;
    final min = profile.minSubjects ?? 1;
    final max = profile.maxSubjects ?? profile.subjects.length;
    final isWithinBounds = pickedTotal >= min && pickedTotal <= max;

    return PickerSectionScaffold(
      title: l10n.onboardingPickerTitle,
      subtitle: l10n.onboardingPickerSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                Text(
                  l10n.onboardingPickerProfessionalTitle,
                  style: AppTypography.h3,
                ),
                SizedBox(height: AppSpacing.s2.h),
                ObligatorySubjectCheckboxList(
                  subjects: profile.professionalSubjects,
                  langKey: langKey,
                  isSaving: _isSaving,
                  onTapBlocked: _onTapObligatory,
                ),
                SizedBox(height: AppSpacing.s5.h),
                Text(
                  l10n.onboardingPickerRelatedTitle,
                  style: AppTypography.h3,
                ),
                SizedBox(height: AppSpacing.s2.h),
                ObligatorySubjectCheckboxList(
                  subjects: profile.relatedProfessionalSubjects,
                  langKey: langKey,
                  isSaving: _isSaving,
                  onTapBlocked: _onTapObligatory,
                ),
                SizedBox(height: AppSpacing.s5.h),
                Text(
                  l10n.onboardingPickerOtherTitle,
                  style: AppTypography.h3,
                ),
                SizedBox(height: AppSpacing.s2.h),
                ObligatorySubjectCheckboxList(
                  subjects: profile.obligatorySubjects,
                  langKey: langKey,
                  isSaving: _isSaving,
                  onTapBlocked: _onTapObligatory,
                ),
                SizedBox(height: AppSpacing.s2.h),
                OptionalSubjectCheckboxList(
                  subjects: profile.optionalSubjects,
                  picked: _pickedOptional!,
                  onToggle: _onToggleOptional,
                  langKey: langKey,
                  isSaving: _isSaving,
                  iconResolver: subjectIconFor,
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.s4.h),
          PickerValidateBar(
            counterText: l10n.onboardingPickerCounterLive(pickedTotal, max),
            isValid: isWithinBounds,
            isSaving: _isSaving,
            onValidate: () => _onValidatePicked(profile),
            onCancel: () =>
                GoRouter.of(context).go('/onboarding/profile/recap'),
            validateLabel: l10n.onboardingPickerValidateCta,
            cancelLabel: l10n.back,
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // Handlers (preserves Stories 1.4 + 1.15 + 1.17)
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
// _PickerStreamGate — wrapper StreamBuilder factorise pour les 4 modes du
// picker. Lit `users/{uid}` via watchProfile() et appelle `initFromFs` au 1er
// event avant de rendre le `builder`. Si le state local n'est pas encore pret
// (isStateReady=false), affiche un spinner.
//
// Extrait Story 1.18 du pattern Consumer + StreamBuilder + init in
// addPostFrameCallback qui etait dupplique dans chacun des 4 ex-_XxxBody.
// ============================================================================

class _PickerStreamGate extends ConsumerWidget {
  const _PickerStreamGate({
    required this.isStateReady,
    required this.initFromFs,
    required this.builder,
  });

  /// True si `_optedOut` ou `_pickedOptional` (selon mode) est deja initialise.
  /// Si true, on rend directement `builder()` sans attendre Firestore.
  final bool isStateReady;

  /// Callback declenche au 1er event Firestore (en postFrameCallback) pour
  /// initialiser le state local depuis users/{uid}.optedOutSubjects ou
  /// users/{uid}.pickedSubjects.
  final void Function(Map<String, dynamic>? data) initFromFs;

  /// Builder du corps de la page (PickerSectionScaffold...). Appele uniquement
  /// quand le state local est pret.
  final Widget Function() builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isStateReady) {
      return builder();
    }
    final profileStream =
        ref.watch(userProfileRepositoryProvider).watchProfile();
    return StreamBuilder<Map<String, dynamic>?>(
      stream: profileStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          initFromFs(snap.data);
        });
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
