// Story E1bis-3 — Step body 4 du shell onboarding refonte.
//
// STREAM + SUBJECTS PICKER. Flow :
//   1. Si streamId null + plusieurs series disponibles -> stream picker
//      (liste de cards SelectionCard avec noms de series du Firestore).
//   2. Si streamId null + une seule serie -> auto-pick (setStreamIdDraft).
//   3. Si streamId pose OU niveau sans serie -> derive() -> dispatch sur
//      DerivedProfile.pickerMode (5 modes : derived / optOut /
//      freeWithObligatory / seriesPlusOptional / tvePicker).
//
// Le PickerSectionScaffold englobe tout (titre + sous-titre toujours
// visibles, meme en loading/error — fix runtime 2026-06-13 : avant ca
// l'ecran d'erreur cachait le titre).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/catalogue/providers.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/cards/selection_card.dart';
import '../../../../core/widgets/feedback/error_retry_view.dart';
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
    final catalogueAsync = ref.watch(catalogueProvider);
    final langKey = state.subSystem == SubSystem.anglophone ? 'en' : 'fr';

    // Titre dynamique : "Choisis ta serie" si on doit en choisir une,
    // "Quelles matieres ?" sinon. Le scaffold garde le titre meme en
    // loading/error.
    final showingStreamPicker = state.streamId == null;
    final title = showingStreamPicker
        ? l10n.onboardingPickerSeriesTitle
        : l10n.onboardingStreamSubjectsTitle;
    final subtitle =
        showingStreamPicker ? null : l10n.onboardingStreamSubjectsSubtitle;

    return PickerSectionScaffold(
      title: title,
      subtitle: subtitle,
      child: catalogueAsync.when(
        data: (snapshot) => _buildContent(
          snapshot: snapshot,
          state: state,
          notifier: notifier,
          langKey: langKey,
          l10n: l10n,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorRetryView(
          onRetry: () => ref.invalidate(catalogueProvider),
          kind: ErrorRetryKind.offline,
        ),
      ),
    );
  }

  Widget _buildContent({
    required CatalogueSnapshot snapshot,
    required dynamic state,
    required OnboardingNotifier notifier,
    required String langKey,
    required AppLocalizations l10n,
  }) {
    final streams = snapshot.series
        .where((s) =>
            s.isActive &&
            s.niveauId == state.levelId &&
            (state.trackId == null || s.filiereId == state.trackId))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Cas 1 : streamId null + plusieurs streams -> picker de serie.
    if (state.streamId == null && streams.length > 1) {
      return _StreamPicker(
        streams: streams,
        langKey: langKey,
        onSelected: notifier.setStreamIdDraft,
      );
    }

    // Cas 2 : streamId null + exactement 1 stream -> auto-pick + re-derive.
    if (state.streamId == null && streams.length == 1) {
      final only = streams.first.serieId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) notifier.setStreamIdDraft(only);
      });
      return const Center(child: CircularProgressIndicator());
    }

    // Cas 3 : streamId pose OU niveau sans serie -> derive + dispatch.
    return _buildDerivedView(notifier, langKey, l10n);
  }

  Widget _buildDerivedView(
    OnboardingNotifier notifier,
    String langKey,
    AppLocalizations l10n,
  ) {
    final derivedAsync = ref.watch(derivedProfileV2Provider);
    return derivedAsync.when(
      data: (either) => either.fold(
        (_) => ErrorRetryView(
          onRetry: () => ref.invalidate(catalogueProvider),
          kind: ErrorRetryKind.generic,
        ),
        (profile) => _renderForMode(profile, notifier, langKey, l10n),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => ErrorRetryView(
        onRetry: () => ref.invalidate(catalogueProvider),
        kind: ErrorRetryKind.offline,
      ),
    );
  }

  Widget _renderForMode(
    DerivedProfile profile,
    OnboardingNotifier notifier,
    String langKey,
    AppLocalizations l10n,
  ) {
    final state = ref.read(onboardingNotifierProvider);

    // Mode derived : flush direct + skip step 4 -> step 5.
    if (profile.pickerMode == PickerMode.derived) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        notifier.setStreamAndSubjects(
          streamId: state.streamId,
          pickedSubjects:
              profile.subjects.map((s) => s.subjectId).toList(),
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    final obligatorySubjects = _obligatorySubjectsFor(profile);
    final optionalSubjects = _optionalSubjectsFor(profile);
    final selectedCount = _picked.length + obligatorySubjects.length;
    final min = profile.minSubjects ?? obligatorySubjects.length;
    final max = profile.maxSubjects ?? profile.subjects.length;
    final isValid = selectedCount >= min && selectedCount <= max;

    return Column(
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
          onValidate: () => _onValidate(notifier, profile, obligatorySubjects),
          onCancel: () => Navigator.of(context).maybePop(),
          validateLabel: l10n.onboardingPickerValidate,
          cancelLabel: l10n.onboardingContinue,
        ),
      ],
    );
  }

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

  IconData _iconResolver(String iconName) => LucideIcons.bookOpen;

  void _onValidate(
    OnboardingNotifier notifier,
    DerivedProfile profile,
    List<Subject> obligatorySubjects,
  ) {
    final state = ref.read(onboardingNotifierProvider);
    final allPicked = <String>{
      ...obligatorySubjects.map((s) => s.subjectId),
      ..._picked,
    };
    notifier.setStreamAndSubjects(
      streamId: state.streamId,
      pickedSubjects: allPicked.toList(),
    );
  }
}

/// Stream picker : liste verticale de SelectionCard pour choisir une serie.
class _StreamPicker extends StatelessWidget {
  const _StreamPicker({
    required this.streams,
    required this.langKey,
    required this.onSelected,
  });

  final List<Serie> streams;
  final String langKey;
  final void Function(String streamId) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final stream in streams) ...[
            SelectionCard(
              title: stream.name[langKey] ?? stream.name.values.first,
              selected: false,
              variant: SelectionCardVariant.compact,
              showRadio: false,
              onTap: () => onSelected(stream.serieId),
            ),
            SizedBox(height: AppSpacing.s2.h),
          ],
          SizedBox(height: AppSpacing.s8.h),
        ],
      ),
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
