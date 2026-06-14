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
import '../../../../core/widgets/feedback/onboarding_loader.dart';
import '../../../../core/widgets/picker/picker_section_scaffold.dart';
import '../../../../core/widgets/picker/subject_icon_resolver.dart';
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
  /// Audit 2026-06-13 — Pick utilisateur par groupe de variantes (LV2 etc.).
  /// Cle = `Subject.group`, valeur = subjectId du variant choisi. Reset au
  /// changement de streamId (en pratique, le PageView ne ressuscite pas
  /// l'etat donc OK).
  final Map<String, String> _picksByGroup = <String, String>{};

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
        loading: () =>
            OnboardingLoader(label: l10n.onboardingLoaderLabel),
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

    // Audit BUG-01 2026-06-13 — Cas 0 : streamId null + aucune serie trouvee
    // pour ce niveau. Avant ce PR, le code tombait dans Cas 3 -> derive() avec
    // streamId=null -> noMatchingRule -> ErrorRetryView "Chargement impossible"
    // (suggere un probleme reseau alors que c'est un probleme de seed
    // catalogue). On affiche maintenant un message explicite avec retry sur
    // le catalogue.
    if (state.streamId == null &&
        streams.isEmpty &&
        state.levelRequiresPicker == true) {
      return _StreamPickerEmpty(
        title: l10n.onboardingStreamPickerEmptyTitle,
        body: l10n.onboardingStreamPickerEmptyBody,
        retryLabel: l10n.onboardingStreamPickerEmptyRetry,
        onRetry: () => ref.invalidate(catalogueProvider),
      );
    }

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
      return OnboardingLoader(label: l10n.onboardingLoaderLabel);
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
      loading: () => OnboardingLoader(label: l10n.onboardingLoaderLabel),
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
    final allSubjects = _allSubjectsFor(profile);

    // Audit 2026-06-13 — Unification de TOUS les pickerModes en preview chips
    // read-only (decision produit : "on ne choisit pas les matieres, on
    // affiche tout de la specialite") + exception variantes (LV2 = choix
    // d'une langue parmi allemand/espagnol/italien/latin).
    //
    // `_groupsIn` extrait les groupes (>= 2 variantes meme `subject.group`).
    // `ungrouped` = matieres autonomes (chip simple). `groups` = mini-pickers.
    final groups = _groupsIn(allSubjects);
    final ungrouped =
        allSubjects.where((s) => s.group == null).toList(growable: false);

    // CTA actif uniquement si chaque groupe a un pick.
    final allGroupsPicked =
        groups.keys.every(_picksByGroup.containsKey);

    return _DerivedPreview(
      ungroupedSubjects: ungrouped,
      groups: groups,
      picksByGroup: _picksByGroup,
      langKey: langKey,
      validateLabel: l10n.onboardingPickerValidate,
      isValid: allGroupsPicked,
      onGroupPick: (groupKey, subjectId) {
        setState(() => _picksByGroup[groupKey] = subjectId);
      },
      onValidate: () {
        final picked = <String>[
          ...ungrouped.map((s) => s.subjectId),
          ..._picksByGroup.values,
        ];
        notifier.setStreamAndSubjects(
          streamId: state.streamId,
          pickedSubjects: picked,
        );
      },
    );
  }

  /// Detecte les groupes de variantes dans la liste : retourne
  /// `{groupKey: [variants]}` pour chaque groupe ayant >= 2 variantes. Un
  /// groupe avec 1 seule variante est traite comme une matiere autonome
  /// (pas de picker, juste un chip simple) — evite un bottomsheet inutile.
  Map<String, List<Subject>> _groupsIn(List<Subject> subjects) {
    final result = <String, List<Subject>>{};
    for (final s in subjects) {
      final g = s.group;
      if (g != null) {
        result.putIfAbsent(g, () => <Subject>[]).add(s);
      }
    }
    result.removeWhere((_, variants) => variants.length < 2);
    return result;
  }

  /// Aggrege toutes les matieres d'un profil derive, quel que soit le
  /// pickerMode. Resultat = matieres a afficher dans le resume chips.
  ///
  /// Mode derived : `profile.subjects` (deja agregées).
  /// Mode freeWithObligatory / seriesPlusOptional : obligatoires + optionnelles.
  /// Mode tvePicker : pro + related + other.
  /// Mode optOut (legacy) : `profile.subjects`.
  List<Subject> _allSubjectsFor(DerivedProfile p) {
    return switch (p.pickerMode) {
      PickerMode.derived => p.subjects,
      PickerMode.optOut => p.subjects,
      PickerMode.freeWithObligatory => [
          ...p.obligatorySubjects,
          ...p.optionalSubjects,
        ],
      PickerMode.seriesPlusOptional => [
          ...p.obligatorySubjects,
          ...p.optionalSubjects,
        ],
      PickerMode.tvePicker => [
          ...p.professionalSubjects,
          ...p.relatedProfessionalSubjects,
          ...p.otherSubjects,
        ],
    };
  }

}

/// Preview read-only des matieres pour le mode `derived` (Terminale D,
/// Premiere C, ...). L'utilisateur ne peut pas modifier ; il confirme avec
/// le CTA "Continuer" pour avancer au step 5.
///
/// Audit 2026-06-13 — Layout RESUME (chips) au lieu de la liste verticale
/// de tiles. Justification : Terminale D = 11 matieres, l'ancienne liste
/// occupait ~600 dp + scroll obligatoire en phone. Le user demande "une
/// forme de resume" : voir TOUT en un coup d'oeil. Les chips wrap
/// naturellement sur 3-4 lignes en phone, 2 lignes en tablet, et
/// transmettent le message "voici les matieres" sans demander d'action.
class _DerivedPreview extends StatelessWidget {
  const _DerivedPreview({
    required this.ungroupedSubjects,
    required this.groups,
    required this.picksByGroup,
    required this.langKey,
    required this.validateLabel,
    required this.isValid,
    required this.onGroupPick,
    required this.onValidate,
  });

  /// Matieres autonomes (sans `group`). Rendues comme chips simples.
  final List<Subject> ungroupedSubjects;

  /// Groupes de variantes (`{groupKey: [variants]}`). Chaque groupe affiche
  /// UN chip (placeholder si pas pick, variant pick sinon) + bottomsheet
  /// d'edition au tap.
  final Map<String, List<Subject>> groups;

  /// Pick utilisateur par groupe (cle = groupKey, valeur = subjectId pick).
  final Map<String, String> picksByGroup;

  final String langKey;
  final String validateLabel;

  /// Active le CTA Valider. False tant que tous les groupes ne sont pas pick.
  final bool isValid;

  final void Function(String groupKey, String subjectId) onGroupPick;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.s2.w,
                  runSpacing: AppSpacing.s2.h,
                  children: [
                    for (final subject in ungroupedSubjects)
                      _SubjectSummaryChip(
                        subject: subject,
                        langKey: langKey,
                      ),
                    for (final entry in groups.entries)
                      _GroupChip(
                        groupKey: entry.key,
                        variants: entry.value,
                        pickedId: picksByGroup[entry.key],
                        langKey: langKey,
                        onPick: (subjectId) =>
                            onGroupPick(entry.key, subjectId),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.s8.h),
              ],
            ),
          ),
        ),
        // Audit 2026-06-13 — SafeArea(top: false) : sur Android Q+ et iPhone
        // avec gesture nav, le CTA collait a la barre systeme. Le top reste
        // false parce que le scaffold parent gere deja le top via le shell.
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.s4.w),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isValid ? onValidate : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.4),
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s4.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                child: Text(
                  validateLabel,
                  style: AppTypography.bodyStrong.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.card,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip representant un groupe de variantes (LV2 / LV3...).
///
/// Etats :
///   - non pick : bordure pointillee, label "Choisir LV2", chevron-down.
///     Tap -> bottomsheet de selection.
///   - pick : chip plein style normal avec le nom du variant pick. Tap ->
///     bottomsheet pour re-choisir.
class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.groupKey,
    required this.variants,
    required this.pickedId,
    required this.langKey,
    required this.onPick,
  });

  final String groupKey;
  final List<Subject> variants;
  final String? pickedId;
  final String langKey;
  final void Function(String subjectId) onPick;

  @override
  Widget build(BuildContext context) {
    final pickedVariant = pickedId == null
        ? null
        : variants.firstWhere(
            (s) => s.subjectId == pickedId,
            orElse: () => variants.first,
          );
    final hasPick = pickedVariant != null;
    final label = hasPick
        ? (pickedVariant.name[langKey] ??
            pickedVariant.name['fr'] ??
            pickedVariant.subjectId)
        : 'Choisir ${groupKey.toUpperCase()}';
    final icon = hasPick
        ? subjectIconFor(pickedVariant.icon)
        : LucideIcons.plusCircle;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: () => _openSheet(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s3.w,
          vertical: AppSpacing.s2.h,
        ),
        decoration: BoxDecoration(
          color: hasPick ? AppColors.primarySoft : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: hasPick
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.primary.withValues(alpha: 0.5),
            width: hasPick ? 1 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 16.sp),
            SizedBox(width: AppSpacing.s2.w),
            Text(
              label,
              style: AppTypography.bodyStrong.copyWith(
                fontSize: 13.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: AppSpacing.s1.w),
            Icon(
              LucideIcons.chevronDown,
              color: AppColors.primary,
              size: 14.sp,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl2),
        ),
      ),
      builder: (sheetCtx) => _GroupPickerSheet(
        groupKey: groupKey,
        variants: variants,
        pickedId: pickedId,
        langKey: langKey,
      ),
    );
    if (result != null) onPick(result);
  }
}

/// Bottomsheet de selection d'une variante d'un groupe (LV2 / LV3...).
class _GroupPickerSheet extends StatelessWidget {
  const _GroupPickerSheet({
    required this.groupKey,
    required this.variants,
    required this.pickedId,
    required this.langKey,
  });

  final String groupKey;
  final List<Subject> variants;
  final String? pickedId;
  final String langKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.s5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              'Choisis ta ${groupKey.toUpperCase()}',
              style: AppTypography.h3.copyWith(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s4.h),
            for (final variant in variants) ...[
              _GroupVariantTile(
                variant: variant,
                langKey: langKey,
                selected: variant.subjectId == pickedId,
                onTap: () => Navigator.of(context).pop(variant.subjectId),
              ),
              SizedBox(height: AppSpacing.s2.h),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupVariantTile extends StatelessWidget {
  const _GroupVariantTile({
    required this.variant,
    required this.langKey,
    required this.selected,
    required this.onTap,
  });

  final Subject variant;
  final String langKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = variant.name[langKey] ??
        variant.name['fr'] ??
        variant.subjectId;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.s3.w),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              subjectIconFor(variant.icon),
              color: AppColors.primary,
              size: 20.sp,
            ),
            SizedBox(width: AppSpacing.s3.w),
            Expanded(
              child: Text(
                name,
                style: AppTypography.bodyStrong.copyWith(
                  fontSize: 15.sp,
                  color: selected ? AppColors.primary : AppColors.ink,
                ),
              ),
            ),
            if (selected)
              Icon(LucideIcons.check,
                  color: AppColors.primary, size: 18.sp),
          ],
        ),
      ),
    );
  }
}

/// Chip compact resume d'une matiere : icone + nom court. Sert le mode
/// derived ou aucune interaction n'est possible : juste une vue d'ensemble.
///
/// Pas d'abbreviation ni de cadenas — le but est de minimiser le bruit
/// visuel pour qu'on voit les 11 matieres d'un coup. L'abbreviation reste
/// utile dans les modes picker (CheckboxListTile) ou la liste est longue
/// et identifiee par tap. Cf. audit 2026-06-13.
class _SubjectSummaryChip extends StatelessWidget {
  const _SubjectSummaryChip({required this.subject, required this.langKey});

  final Subject subject;
  final String langKey;

  @override
  Widget build(BuildContext context) {
    final name =
        subject.name[langKey] ?? subject.name['fr'] ?? subject.subjectId;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3.w,
        vertical: AppSpacing.s2.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            subjectIconFor(subject.icon),
            color: AppColors.primary,
            size: 16.sp,
          ),
          SizedBox(width: AppSpacing.s2.w),
          Text(
            name,
            style: AppTypography.bodyStrong.copyWith(
              fontSize: 13.sp,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
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
              description: stream.descriptionFor(langKey),
              selected: false,
              variant: SelectionCardVariant.standard,
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

/// Audit BUG-01 2026-06-13 — Fallback affiche quand `streams.isEmpty` pour
/// un niveau qui requiert pourtant un picker (`levelRequiresPicker == true`).
/// Cas typique : seed catalogue Firestore desync (les series Terminale FR
/// n'ont pas ete poussees au projet live). Avant ce widget, le code tombait
/// dans `_buildDerivedView` -> `derive()` -> noMatchingRule -> ErrorRetryView
/// "Chargement impossible" (message qui suggere a tort un probleme reseau).
class _StreamPickerEmpty extends StatelessWidget {
  const _StreamPickerEmpty({
    required this.title,
    required this.body,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String body;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.searchX,
              size: 48.sp,
              color: AppColors.inkSoft,
            ),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              title,
              style: AppTypography.h3.copyWith(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s3.h),
            Text(
              body,
              style: AppTypography.body.copyWith(
                color: AppColors.inkSoft,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s5.h),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
