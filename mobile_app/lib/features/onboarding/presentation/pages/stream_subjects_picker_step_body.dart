// Story E1bis-3 — Step body 4 du shell onboarding refonte.
//
// STREAM + SUBJECTS PICKER. Lit `derivedProfileV2Provider` (E1bis-3) qui
// derive depuis le state OnboardingNotifier puis dispatch sur
// `DerivedProfile.pickerMode` (5 modes).
//
// Version MVP : utilise les composants Story 1.18
// (PickerSectionScaffold + Obligatory/OptionalSubjectCheckboxList +
// PickerCounterBadge + PickerValidateBar). Le pre-remplissage Firestore
// est reporte E1bis-4 (post-auth). Le selecteur de serie pour les modes
// avec choix multiple est reporte E1bis-3b (ici V1 utilise la serie
// matchee par DerivationRule).
//
// Modes geres :
//   - derived            : auto-skip via setStreamAndSubjects + next()
//   - optOut             : matieres derivees + opt-out par checkbox optionnel
//   - freeWithObligatory : obligatoires lockees + optionnelles libres
//   - seriesPlusOptional : matieres serie (lock) + transversales optionnelles
//   - tvePicker          : pro + related (lock) + other (optionnel)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/onboarding/catalogue_error_retry.dart';
import '../../../../core/widgets/picker/obligatory_subject_checkbox_list.dart';
import '../../../../core/widgets/picker/optional_subject_checkbox_list.dart';
import '../../../../core/widgets/picker/picker_section_scaffold.dart';
import '../../../../core/widgets/picker/picker_validate_bar.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/sub_system.dart';
import '../state/onboarding_notifier.dart';
import '../state/onboarding_providers.dart';

class StreamSubjectsPickerStepBody extends ConsumerStatefulWidget {
  const StreamSubjectsPickerStepBody({super.key});

  @override
  ConsumerState<StreamSubjectsPickerStepBody> createState() =>
      _StreamSubjectsPickerStepBodyState();
}

class _StreamSubjectsPickerStepBodyState
    extends ConsumerState<StreamSubjectsPickerStepBody> {
  final Set<String> _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final derivedAsync = ref.watch(derivedProfileV2Provider);
    final langKey = state.subSystem == SubSystem.anglophone ? 'en' : 'fr';

    return derivedAsync.when(
      data: (either) => either.fold(
        (_) => const CatalogueErrorRetry(),
        (profile) => _renderForMode(profile, notifier, langKey, l10n),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const CatalogueErrorRetry(),
    );
  }

  Widget _renderForMode(
    DerivedProfile profile,
    OnboardingNotifier notifier,
    String langKey,
    AppLocalizations l10n,
  ) {
    // Mode derived : flush direct + skip step 4 -> step 5.
    if (profile.pickerMode == PickerMode.derived) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        notifier.setStreamAndSubjects(
          streamId: null,
          pickedSubjects:
              profile.subjects.map((s) => s.subjectId).toList(),
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    final obligatorySubjects = _obligatorySubjectsFor(profile);
    final optionalSubjects = _optionalSubjectsFor(profile);
    final selectedCount =
        _picked.length + obligatorySubjects.length;
    final min = profile.minSubjects ?? obligatorySubjects.length;
    final max = profile.maxSubjects ?? profile.subjects.length;
    final isValid = selectedCount >= min && selectedCount <= max;

    return PickerSectionScaffold(
      title: l10n.onboardingStreamSubjectsTitle,
      subtitle: l10n.onboardingStreamSubjectsSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (obligatorySubjects.isNotEmpty) ...[
                    _SectionTitle(text: l10n.onboardingPickerObligatoryTitle),
                    ObligatorySubjectCheckboxList(
                      subjects: obligatorySubjects,
                      langKey: langKey,
                      isSaving: false,
                      onTapBlocked: (_) {},
                    ),
                    SizedBox(height: AppSpacing.s4.h),
                  ],
                  if (optionalSubjects.isNotEmpty) ...[
                    _SectionTitle(text: l10n.onboardingPickerOptionalTitle),
                    OptionalSubjectCheckboxList(
                      subjects: optionalSubjects,
                      picked: _picked,
                      onToggle: _onToggle,
                      langKey: langKey,
                      isSaving: false,
                      iconResolver: _iconResolver,
                    ),
                    SizedBox(height: AppSpacing.s4.h),
                  ],
                  SizedBox(height: AppSpacing.s8.h),
                ],
              ),
            ),
          ),
          PickerValidateBar(
            counterText:
                '$selectedCount/$max ${l10n.onboardingPickerObligatoryTitle.toLowerCase()}',
            isValid: isValid,
            isSaving: false,
            onValidate: () =>
                _onValidate(notifier, profile, obligatorySubjects),
            onCancel: () => Navigator.of(context).maybePop(),
            validateLabel: l10n.onboardingPickerValidate,
            cancelLabel: l10n.onboardingContinue,
          ),
        ],
      ),
    );
  }

  /// Matieres lockees selon le mode.
  List<Subject> _obligatorySubjectsFor(DerivedProfile p) {
    return switch (p.pickerMode) {
      PickerMode.optOut => const <Subject>[],
      PickerMode.freeWithObligatory => p.obligatorySubjects,
      PickerMode.seriesPlusOptional => p.obligatorySubjects,
      PickerMode.tvePicker => [
          ...p.professionalSubjects,
          ...p.relatedProfessionalSubjects,
        ],
      PickerMode.derived => const <Subject>[],
    };
  }

  /// Matieres optionnelles selon le mode.
  List<Subject> _optionalSubjectsFor(DerivedProfile p) {
    return switch (p.pickerMode) {
      PickerMode.optOut => p.subjects,
      PickerMode.freeWithObligatory => p.optionalSubjects,
      PickerMode.seriesPlusOptional => p.optionalSubjects,
      PickerMode.tvePicker => p.otherSubjects,
      PickerMode.derived => const <Subject>[],
    };
  }

  void _onToggle(String subjectId, bool selected) {
    setState(() {
      if (selected) {
        _picked.add(subjectId);
      } else {
        _picked.remove(subjectId);
      }
    });
  }

  IconData _iconResolver(String iconName) {
    // Fallback simple : icone livre. Le legacy fait un mapping plus riche
    // (Lucide via name) qu'on reportera en E1bis-3b si besoin.
    return LucideIcons.bookOpen;
  }

  void _onValidate(
    OnboardingNotifier notifier,
    DerivedProfile profile,
    List<Subject> obligatorySubjects,
  ) {
    final allPicked = <String>{
      ...obligatorySubjects.map((s) => s.subjectId),
      ..._picked,
    };
    notifier.setStreamAndSubjects(
      streamId: null,
      pickedSubjects: allPicked.toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s4.w,
        vertical: AppSpacing.s2.h,
      ),
      child: Text(
        text,
        style: AppTypography.h3.copyWith(fontSize: 15.sp),
      ),
    );
  }
}

