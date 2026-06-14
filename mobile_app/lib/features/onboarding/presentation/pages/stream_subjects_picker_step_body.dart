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
        changeLevelLabel: l10n.onboardingStreamPickerEmptyChangeLevel,
        retryLabel: l10n.onboardingStreamPickerEmptyRetry,
        // Audit 2026-06-14 — CTA primaire = revenir step 3 (level choice).
        // Couvre le cas le plus frequent : draft persiste avec levelId qui
        // ne matche plus le catalogue actuel (Phase 7 deactivation, seed
        // change). `back()` ramene step 4 -> 3 sans toucher au draft amont,
        // l'utilisateur re-selectionne un niveau valide.
        onChangeLevel: () => notifier.back(),
        onRetry: () => ref.invalidate(catalogueProvider),
      );
    }

    // Cas 1 : streamId null + plusieurs streams -> picker de serie.
    if (state.streamId == null && streams.length > 1) {
      return _StreamPicker(
        streams: streams,
        langKey: langKey,
        continueLabel: l10n.onboardingContinue,
        // Audit 2026-06-14 — Le commit (setStreamIdDraft) se fait au tap
        // CTA Continuer du picker, plus au tap card. Permet a l'user de
        // changer d'avis avant validation.
        onConfirm: notifier.setStreamIdDraft,
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
    return _buildDerivedView(snapshot, notifier, langKey, l10n);
  }

  Widget _buildDerivedView(
    CatalogueSnapshot snapshot,
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
        (profile) => _renderForMode(snapshot, profile, notifier, langKey, l10n),
      ),
      loading: () => OnboardingLoader(label: l10n.onboardingLoaderLabel),
      error: (_, _) => ErrorRetryView(
        onRetry: () => ref.invalidate(catalogueProvider),
        kind: ErrorRetryKind.offline,
      ),
    );
  }

  Widget _renderForMode(
    CatalogueSnapshot snapshot,
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

    // Audit 2026-06-14 — Step 4 = resume des choix amont (section -> filiere
    // -> niveau -> serie quand applicable) AVANT les chips matieres. Donne le
    // contexte de ce que le user vient de configurer.
    final recapParts = _recapPartsFor(snapshot, state, langKey);

    return _DerivedPreview(
      recapParts: recapParts,
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

  /// Construit la liste des libelles a afficher dans le recap header du
  /// step 4 : Section -> Filiere -> Niveau -> Serie (quand applicable).
  /// Resout les IDs vers leur nom localise via le snapshot catalogue.
  List<String> _recapPartsFor(
    CatalogueSnapshot snapshot,
    dynamic state,
    String langKey,
  ) {
    final parts = <String>[];
    final subSystem = state.subSystem;
    if (subSystem != null) {
      parts.add(subSystem == SubSystem.francophone
          ? 'Francophone'
          : 'Anglophone');
    }
    final trackId = state.trackId;
    if (trackId != null) {
      final f = snapshot.filieres.where((f) => f.filiereId == trackId);
      if (f.isNotEmpty) {
        parts.add(f.first.name[langKey] ?? f.first.name.values.first);
      }
    }
    final levelId = state.levelId;
    if (levelId != null) {
      final n = snapshot.niveaux.where((n) => n.niveauId == levelId);
      if (n.isNotEmpty) {
        parts.add(n.first.name[langKey] ?? n.first.name.values.first);
      }
    }
    final streamId = state.streamId;
    if (streamId != null) {
      final s = snapshot.series.where((s) => s.serieId == streamId);
      if (s.isNotEmpty) {
        parts.add(s.first.name[langKey] ?? s.first.name.values.first);
      }
    }
    return parts;
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
    required this.recapParts,
    required this.ungroupedSubjects,
    required this.groups,
    required this.picksByGroup,
    required this.langKey,
    required this.validateLabel,
    required this.isValid,
    required this.onGroupPick,
    required this.onValidate,
  });

  /// Libelles du recap (Section / Filiere / Niveau / Serie) affiches au-
  /// dessus des chips. Vide -> pas de recap rendu.
  final List<String> recapParts;

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
                if (recapParts.isNotEmpty) ...[
                  _RecapBanner(parts: recapParts),
                  SizedBox(height: AppSpacing.s4.h),
                ],
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
/// Audit 2026-06-14 — Banner recap affichant le parcours du user
/// (Section -> Filiere -> Niveau -> Serie) au-dessus des chips matieres.
/// Rendu en card primary tinted, separateur ` . ` entre les segments.
class _RecapBanner extends StatelessWidget {
  const _RecapBanner({required this.parts});

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3.w,
        vertical: AppSpacing.s3.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.bookOpen,
            size: 16.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: AppSpacing.s2.w),
          Expanded(
            child: Text(
              parts.join('  ·  '),
              style: AppTypography.body.copyWith(
                fontSize: 13.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
/// Audit 2026-06-14 — Picker serie avec selection visuelle + CTA Continuer.
///
/// Avant ce refactor : tap card -> `setStreamIdDraft` immediat -> re-render
/// auto vers la derived view. Pas de moment "j'ai choisi mais je peux
/// changer". Apres : tap card = highlight local uniquement ; le commit ne
/// se fait qu'au tap CTA Continuer. Pattern coherent avec step 2 (track)
/// et step 3 (level).
class _StreamPicker extends StatefulWidget {
  const _StreamPicker({
    required this.streams,
    required this.langKey,
    required this.continueLabel,
    required this.onConfirm,
  });

  final List<Serie> streams;
  final String langKey;
  final String continueLabel;
  final void Function(String streamId) onConfirm;

  @override
  State<_StreamPicker> createState() => _StreamPickerState();
}

class _StreamPickerState extends State<_StreamPicker> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final stream in widget.streams) ...[
                  SelectionCard(
                    title: stream.name[widget.langKey] ??
                        stream.name.values.first,
                    description: stream.descriptionFor(widget.langKey),
                    selected: _selectedId == stream.serieId,
                    variant: SelectionCardVariant.standard,
                    showRadio: false,
                    onTap: () => setState(() => _selectedId = stream.serieId),
                  ),
                  SizedBox(height: AppSpacing.s2.h),
                ],
                SizedBox(height: AppSpacing.s4.h),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.s4.w),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedId == null
                    ? null
                    : () => widget.onConfirm(_selectedId!),
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
                  widget.continueLabel,
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
    required this.changeLevelLabel,
    required this.retryLabel,
    required this.onChangeLevel,
    required this.onRetry,
  });

  final String title;
  final String body;
  final String changeLevelLabel;
  final String retryLabel;
  final VoidCallback onChangeLevel;
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
            // CTA primaire : revenir au level choice — couvre le cas le
            // plus frequent (draft stale apres seed change).
            FilledButton.icon(
              onPressed: onChangeLevel,
              icon: const Icon(LucideIcons.arrowLeft, size: 18),
              label: Text(changeLevelLabel),
            ),
            SizedBox(height: AppSpacing.s2.h),
            // CTA secondaire : retry catalogue (utile uniquement si seed gap
            // vient juste d'etre comble cote backend).
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
