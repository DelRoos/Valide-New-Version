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
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/catalogue/providers.dart';
import '../../../../core/firebase/providers.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/cards/selection_card.dart';
import '../../../../core/widgets/feedback/error_retry_view.dart';
import '../../../../core/widgets/feedback/onboarding_loader.dart';
import '../../../../core/widgets/picker/picker_section_scaffold.dart';
import '../../../../core/widgets/picker/subject_icon_resolver.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/sub_system.dart';
import '../../providers.dart';
import '../state/onboarding_notifier.dart';
import '../state/onboarding_providers.dart';
import '../state/onboarding_state.dart';

class StreamSubjectsPickerStepBody extends ConsumerStatefulWidget {
  const StreamSubjectsPickerStepBody({super.key});

  @override
  ConsumerState<StreamSubjectsPickerStepBody> createState() =>
      _StreamSubjectsPickerStepBodyState();
}

class _StreamSubjectsPickerStepBodyState
    extends ConsumerState<StreamSubjectsPickerStepBody> {
  /// Pick utilisateur par groupe de variantes (LV2 etc.).
  /// Cle = `Subject.group`, valeur = subjectId du variant choisi.
  final Map<String, String> _picksByGroup = <String, String>{};

  /// IDs des matières optionnelles sélectionnées (modes opt_out /
  /// free_with_obligatory / series_plus_optional). Reset quand le streamId
  /// change.
  final Set<String> _selectedOptionalIds = <String>{};

  /// Dernier streamId vu — permet de détecter un changement de série pour
  /// vider `_selectedOptionalIds` sans appeler setState pendant build.
  String? _lastStreamId;

  /// Vrai pendant le flux auth anonyme + flush Firestore déclenché par le
  /// CTA "Commencer à réviser". Désactive le bouton pour éviter les double-taps.
  bool _isStartingRevision = false;

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
    //
    // Audit 2026-06-15 — Guard affine : `streams.isEmpty` seul est trop large.
    // Les niveaux sans serie (6e-3e) ont des regles avec `matchSerie=null` qui
    // font reussir derive() via Cas 3. Ne montrer _StreamPickerEmpty que si
    // aucune regle `matchSerie=null` n'existe pour ce profil ; sinon Cas 3 OK.
    // Cas problematique vise : francophone+technique+seconde (0 series, 0 regles
    // matchSerie=null) -> derive() echoue toujours -> afficher etat vide.
    if (state.streamId == null && streams.isEmpty) {
      final subSystemId = state.subSystem?.id ?? '';
      final trackId = state.trackId ?? '';
      final levelId = state.levelId ?? '';
      final hasNullSerieRule = snapshot.derivationRules.any((r) =>
          r.isActive &&
          r.matchSubSystem == subSystemId &&
          (r.matchFiliere == '*' || r.matchFiliere == trackId) &&
          r.matchNiveau == levelId &&
          r.matchSerie == null);
      if (!hasNullSerieRule) {
        // Aucune regle ne peut matcher sans serie -> etat vide explicite.
        return _StreamPickerEmpty(
          title: l10n.onboardingStreamPickerEmptyTitle,
          body: l10n.onboardingStreamPickerEmptyBody,
          changeLevelLabel: l10n.onboardingStreamPickerEmptyChangeLevel,
          retryLabel: l10n.onboardingStreamPickerEmptyRetry,
          // Audit 2026-06-14 — CTA primaire = revenir step 3 (level choice).
          onChangeLevel: () => notifier.back(),
          onRetry: () => ref.invalidate(catalogueProvider),
        );
      }
      // hasNullSerieRule = true : Cas 3 gerera derive(serie=null) (ex. 6e-3e).
    }

    // Cas 1 : streamId null + plusieurs streams -> picker de serie.
    if (state.streamId == null && streams.length > 1) {
      return _StreamPicker(
        streams: streams,
        langKey: langKey,
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
    final recapEntries =
        _recapEntriesFor(snapshot, state, profile, langKey, l10n);

    // Modes interactifs : l'eleve choisit ses matieres optionnelles.
    if (profile.pickerMode == PickerMode.optOut ||
        profile.pickerMode == PickerMode.freeWithObligatory ||
        profile.pickerMode == PickerMode.seriesPlusOptional) {
      // Reset de la selection quand la serie change (sans setState : mutation
      // directe avant construction de l'arbre, safe dans build()).
      if (state.streamId != _lastStreamId) {
        _lastStreamId = state.streamId;
        _selectedOptionalIds.clear();
        _picksByGroup.clear();
      }

      final minS = profile.minSubjects ?? profile.obligatorySubjects.length;
      final maxS = profile.maxSubjects ??
          (profile.obligatorySubjects.length + profile.optionalSubjects.length);
      final totalSelected =
          profile.obligatorySubjects.length + _selectedOptionalIds.length;
      final isValid = totalSelected >= minS && totalSelected <= maxS;

      return _InteractiveSubjectPicker(
        recapEntries: recapEntries,
        obligatorySubjects: profile.obligatorySubjects,
        optionalSubjects: profile.optionalSubjects,
        selectedOptionalIds: _selectedOptionalIds,
        totalSelected: totalSelected,
        min: minS,
        max: maxS,
        langKey: langKey,
        isValid: isValid && !_isStartingRevision,
        isLoading: _isStartingRevision,
        validateLabel: l10n.onboardingStartRevising,
        onToggleOptional: (subjectId) {
          setState(() {
            if (_selectedOptionalIds.contains(subjectId)) {
              _selectedOptionalIds.remove(subjectId);
            } else if (totalSelected < maxS) {
              _selectedOptionalIds.add(subjectId);
            }
          });
        },
        onValidate: () {
          final picked = <String>[
            ...profile.obligatorySubjects.map((s) => s.subjectId),
            ..._selectedOptionalIds,
          ];
          _startRevising(streamId: state.streamId, pickedSubjects: picked);
        },
      );
    }

    // Modes read-only (derived / tvePicker) : chips recap sans choix.
    final allSubjects = _allSubjectsFor(profile);
    final groups = _groupsIn(allSubjects);
    final ungrouped =
        allSubjects.where((s) => s.group == null).toList(growable: false);
    final allGroupsPicked = groups.keys.every(_picksByGroup.containsKey);

    return _DerivedPreview(
      recapEntries: recapEntries,
      ungroupedSubjects: ungrouped,
      groups: groups,
      picksByGroup: _picksByGroup,
      langKey: langKey,
      validateLabel: l10n.onboardingStartRevising,
      isValid: allGroupsPicked && !_isStartingRevision,
      isLoading: _isStartingRevision,
      onGroupPick: (groupKey, subjectId) {
        setState(() {
          if (subjectId == null) {
            _picksByGroup.remove(groupKey);
          } else {
            _picksByGroup[groupKey] = subjectId;
          }
        });
      },
      onValidate: () {
        final picked = <String>[
          ...ungrouped.map((s) => s.subjectId),
          ..._picksByGroup.values,
        ];
        _startRevising(streamId: state.streamId, pickedSubjects: picked);
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

  /// Construit la liste des entrees a afficher dans le recap header du
  /// step 4 : Section -> Filiere -> Niveau -> Serie -> Examen vise.
  /// Resout les IDs vers leur nom localise via le snapshot catalogue + le
  /// profile derive (pour examTargets). Chaque entree = record
  /// (label, value) pour un affichage en 2 colonnes.
  List<({String label, String value, IconData icon})> _recapEntriesFor(
    CatalogueSnapshot snapshot,
    dynamic state,
    DerivedProfile profile,
    String langKey,
    AppLocalizations l10n,
  ) {
    final entries = <({String label, String value, IconData icon})>[];
    final subSystem = state.subSystem;
    if (subSystem != null) {
      entries.add((
        label: l10n.onboardingRecapLabelSection,
        value: subSystem == SubSystem.francophone
            ? l10n.subsystemFrancophone
            : l10n.subsystemAnglophone,
        icon: LucideIcons.globe,
      ));
    }
    final trackId = state.trackId;
    if (trackId != null) {
      final f = snapshot.filieres.where((f) => f.filiereId == trackId);
      if (f.isNotEmpty) {
        entries.add((
          label: l10n.onboardingRecapLabelTrack,
          value: f.first.name[langKey] ?? f.first.name.values.first,
          icon: LucideIcons.layers,
        ));
      }
    }
    final levelId = state.levelId;
    if (levelId != null) {
      final n = snapshot.niveaux.where((n) => n.niveauId == levelId);
      if (n.isNotEmpty) {
        entries.add((
          label: l10n.onboardingRecapLabelLevel,
          value: n.first.name[langKey] ?? n.first.name.values.first,
          icon: LucideIcons.graduationCap,
        ));
      }
    }
    final streamId = state.streamId;
    if (streamId != null) {
      final s = snapshot.series.where((s) => s.serieId == streamId);
      if (s.isNotEmpty) {
        entries.add((
          label: l10n.onboardingRecapLabelStream,
          value: s.first.name[langKey] ?? s.first.name.values.first,
          icon: LucideIcons.bookmark,
        ));
      }
    }
    // Audit 2026-06-14 — Ajout de l'examen vise au recap (BAC D, BEPC,
    // Probatoire G1, GCE A-Level...). Plusieurs examens possibles par
    // niveau (ex: Premiere D -> Probatoire D ; Terminale D -> BAC D). On
    // joint avec ' / ' si multiple.
    final activeExams = profile.examTargets
        .where((e) => e.isActive)
        .map((e) => e.name[langKey] ?? e.name.values.first)
        .toList(growable: false);
    if (activeExams.isNotEmpty) {
      entries.add((
        label: l10n.onboardingRecapLabelExam,
        value: activeExams.join(' / '),
        icon: LucideIcons.award,
      ));
    }
    return entries;
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

  /// CTA "Commencer à réviser" — crée un compte anonyme + flush Firestore
  /// + navigue vers /dashboard sans passer par le step 5 (auth choice).
  ///
  /// Flux : signInAnonymously() si besoin -> flush (state local) ->
  /// router.go('/dashboard'). On NE touche PAS au notifier Riverpod ici car
  /// derivedProfileV2Provider watch onboardingNotifierProvider — tout changement
  /// relance le FutureProvider -> OnboardingLoader plein écran au lieu du
  /// spinner sur le bouton.
  Future<void> _startRevising({
    String? streamId,
    required List<String> pickedSubjects,
  }) async {
    if (_isStartingRevision || !mounted) return;
    setState(() => _isStartingRevision = true);

    final auth = ref.read(firebaseAuthProvider);
    final flushService = ref.read(onboardingFlushServiceProvider);
    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context);

    try {
      final current = auth.currentUser;
      if (current == null) {
        await auth.signInAnonymously();
        AppLogger.i('stream.step4 guest signInAnonymously OK');
      } else {
        AppLogger.i(
          'stream.step4 guest reuse session uid=${current.uid.substring(0, 6)}...',
        );
      }
      if (!mounted) return;

      // Construire le state de flush localement sans modifier onboardingNotifierProvider
      // (evite de relancer derivedProfileV2Provider -> loader plein ecran).
      final baseState = ref.read(onboardingNotifierProvider);
      final state = baseState.copyWith(
        streamId: streamId,
        pickedSubjects: pickedSubjects,
        authProvider: OnboardingAuthProvider.guest,
        isVisitor: true,
      );
      final result = await flushService.flush(state);
      if (!mounted) return;

      result.fold(
        (failure) {
          AppLogger.w(
            'stream.step4 guest flush failed code=${failure.code} '
            'message="${failure.message}"',
          );
          setState(() => _isStartingRevision = false);
        },
        (_) {
          AppLogger.i('stream.step4 guest flush OK -> /dashboard');
          router.go('/dashboard');
        },
      );
    } catch (e, st) {
      AppLogger.w('stream.step4 guest failed: $e', error: e);
      AppLogger.w('stream.step4 guest stack: $st');
      if (mounted) {
        setState(() => _isStartingRevision = false);
        // Affiche un message d'erreur minimal — l'ecran reste visible.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGenericTitle)),
        );
      }
    }
  }

}

/// Résout la clé de groupe Firestore ('lv2', 'lv3'...) vers son libellé
/// localisé pour l'en-tête de section inline.
String _resolveGroupLabel(AppLocalizations l10n, String groupKey) {
  return switch (groupKey) {
    'lv2' => l10n.onboardingGroupLv2,
    'lv3' => l10n.onboardingGroupLv3,
    'olevel_options' => l10n.onboardingGroupOlevelOptions,
    'alevel_options' => l10n.onboardingGroupAlevelOptions,
    _ => l10n.onboardingGroupGeneric,
  };
}

/// Preview read-only des matieres pour le mode `derived` (Terminale D,
/// Premiere C, ...). L'utilisateur ne peut pas modifier ; il confirme avec
/// le CTA "Continuer" pour avancer au step 5.
///
/// Audit 2026-06-13 — Layout RESUME (chips) au lieu de la liste verticale
/// de tiles. Les chips wrap naturellement sur 3-4 lignes en phone.
///
/// Audit 2026-06-14 — Groupes (LV2, LV3...) affichés directement inline
/// sans bottomsheet. Améliore la découvrabilité : l'élève voit les variantes
/// directement sans avoir à tapper un bouton "Choisir LV2".
class _DerivedPreview extends StatelessWidget {
  const _DerivedPreview({
    required this.recapEntries,
    required this.ungroupedSubjects,
    required this.groups,
    required this.picksByGroup,
    required this.langKey,
    required this.validateLabel,
    required this.isValid,
    required this.isLoading,
    required this.onGroupPick,
    required this.onValidate,
  });

  final List<({String label, String value, IconData icon})> recapEntries;
  final List<Subject> ungroupedSubjects;
  final Map<String, List<Subject>> groups;
  final Map<String, String> picksByGroup;
  final String langKey;
  final String validateLabel;
  final bool isValid;
  final bool isLoading;
  final void Function(String groupKey, String? subjectId) onGroupPick;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            // s2.w (8dp) : respire pour Transform.scale(1.01) + BoxShadow
            // des SelectionCards sans doubler le s5.w du PickerSectionScaffold.
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.s2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.s3.h),
                // Récap EN PREMIER — contexte immédiat avant de voir les choix.
                if (recapEntries.isNotEmpty) ...[
                  _RecapBanner(entries: recapEntries),
                  SizedBox(height: AppSpacing.s4.h),
                ],
                // Choix interactifs (groupes LV2/LV3) ensuite.
                for (final entry in groups.entries) ...[
                  _SectionLabel(
                    label: _resolveGroupLabel(l10n, entry.key),
                    hint: l10n.onboardingGroupPickHint,
                  ),
                  SizedBox(height: AppSpacing.s2.h),
                  Wrap(
                    spacing: AppSpacing.s2.w,
                    runSpacing: AppSpacing.s2.h,
                    children: [
                      for (final variant in entry.value)
                        _ToggleChip(
                          subject: variant,
                          langKey: langKey,
                          selected:
                              picksByGroup[entry.key] == variant.subjectId,
                          enabled: true,
                          onTap: () => onGroupPick(
                            entry.key,
                            picksByGroup[entry.key] == variant.subjectId
                                ? null
                                : variant.subjectId,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s4.h),
                ],
                // Autres matières (lecture seule) en bas.
                if (ungroupedSubjects.isNotEmpty)
                  Wrap(
                    spacing: AppSpacing.s2.w,
                    runSpacing: AppSpacing.s2.h,
                    children: [
                      for (final subject in ungroupedSubjects)
                        _SubjectSummaryChip(
                          subject: subject,
                          langKey: langKey,
                        ),
                    ],
                  ),
                SizedBox(height: AppSpacing.s8.h),
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
                child: isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.card,
                        ),
                      )
                    : Text(
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

/// Picker interactif pour les modes opt_out / free_with_obligatory /
/// series_plus_optional. Affiche :
///   - Matières obligatoires en chips verrouillées (toujours incluses).
///   - Matières optionnelles en chips à bascule (tap pour sélectionner).
///   - Badge compteur "X / Y sélectionnées".
///   - CTA actif quand min ≤ total ≤ max.
class _InteractiveSubjectPicker extends StatelessWidget {
  const _InteractiveSubjectPicker({
    required this.recapEntries,
    required this.obligatorySubjects,
    required this.optionalSubjects,
    required this.selectedOptionalIds,
    required this.totalSelected,
    required this.min,
    required this.max,
    required this.langKey,
    required this.isValid,
    required this.isLoading,
    required this.validateLabel,
    required this.onToggleOptional,
    required this.onValidate,
  });

  final List<({String label, String value, IconData icon})> recapEntries;
  final List<Subject> obligatorySubjects;
  final List<Subject> optionalSubjects;
  final Set<String> selectedOptionalIds;
  final int totalSelected;
  final int min;
  final int max;
  final String langKey;
  final bool isValid;
  final bool isLoading;
  final String validateLabel;
  final void Function(String subjectId) onToggleOptional;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canAddMore = totalSelected < max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.s2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.s3.h),
                // Récap EN PREMIER — contexte avant les choix.
                if (recapEntries.isNotEmpty) ...[
                  _RecapBanner(entries: recapEntries),
                  SizedBox(height: AppSpacing.s4.h),
                ],
                // Compteur + choix optionnels (action principale).
                _SubjectCounterBadge(
                  total: totalSelected,
                  min: min,
                  max: max,
                ),
                if (optionalSubjects.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.s3.h),
                  _SectionLabel(
                    label: l10n.onboardingPickerOptionalTitle,
                    hint: l10n.onboardingPickerChooseUpTo(
                      max - obligatorySubjects.length,
                    ),
                  ),
                  SizedBox(height: AppSpacing.s2.h),
                  Wrap(
                    spacing: AppSpacing.s2.w,
                    runSpacing: AppSpacing.s2.h,
                    children: [
                      for (final s in optionalSubjects)
                        _ToggleChip(
                          subject: s,
                          langKey: langKey,
                          selected: selectedOptionalIds.contains(s.subjectId),
                          enabled: selectedOptionalIds.contains(s.subjectId) ||
                              canAddMore,
                          onTap: () => onToggleOptional(s.subjectId),
                        ),
                    ],
                  ),
                ],
                // Autres matières obligatoires en bas (lecture seule).
                if (obligatorySubjects.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.s4.h),
                  _SectionLabel(
                    label: l10n.onboardingPickerObligatoryTitle,
                  ),
                  SizedBox(height: AppSpacing.s2.h),
                  Wrap(
                    spacing: AppSpacing.s2.w,
                    runSpacing: AppSpacing.s2.h,
                    children: [
                      for (final s in obligatorySubjects)
                        _SubjectSummaryChip(
                          subject: s,
                          langKey: langKey,
                          isObligatory: true,
                        ),
                    ],
                  ),
                ],
                SizedBox(height: AppSpacing.s8.h),
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
                child: isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.card,
                        ),
                      )
                    : Text(
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

/// Badge affichant le nombre de matières sélectionnées vs la plage min-max.
/// Vert si la sélection est valide (>= min), orange sinon.
class _SubjectCounterBadge extends StatelessWidget {
  const _SubjectCounterBadge({
    required this.total,
    required this.min,
    required this.max,
  });

  final int total;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final valid = total >= min;
    final color = valid ? AppColors.success : AppColors.warning;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3.w,
        vertical: AppSpacing.s2.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            valid ? LucideIcons.checkCircle : LucideIcons.circle,
            color: color,
            size: 14.sp,
          ),
          SizedBox(width: AppSpacing.s2.w),
          Text(
            l10n.onboardingPickerCounter(total, max),
            style: AppTypography.bodyStrong.copyWith(
              fontSize: 13.sp,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// En-tête de section avec label obligatoire et hint optionnel.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.bodyStrong.copyWith(
            fontSize: 13.sp,
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        if (hint != null) ...[
          SizedBox(width: AppSpacing.s2.w),
          Text(
            '· $hint',
            style: AppTypography.body.copyWith(
              fontSize: 12.sp,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ],
    );
  }
}

/// Chip à bascule pour une matière optionnelle. Plein = sélectionnée.
/// Désactivée (grisée, non tappable) quand le max est atteint et qu'elle
/// n'est pas déjà sélectionnée.
class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.subject,
    required this.langKey,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Subject subject;
  final String langKey;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name =
        subject.name[langKey] ?? subject.name['fr'] ?? subject.subjectId;
    final color = selected ? AppColors.primary : AppColors.inkSoft;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s3.w,
            vertical: AppSpacing.s2.h,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? LucideIcons.checkCircle : LucideIcons.plusCircle,
                color: color,
                size: 14.sp,
              ),
              SizedBox(width: AppSpacing.s2.w),
              Text(
                name,
                style: AppTypography.bodyStrong.copyWith(
                  fontSize: 13.sp,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Audit 2026-06-14 — Banner recap affichant le parcours du user
/// (Section / Filiere / Niveau / Serie) au-dessus des chips matieres.
/// Layout 2 colonnes par ligne : label gris a gauche (fixed width), valeur
/// bold a droite. Un row par entree. Refactor du layout precedent (parts
/// joints en string avec ` · `) qui rendait mal des le wrap.
class _RecapBanner extends StatelessWidget {
  const _RecapBanner({required this.entries});

  final List<({String label, String value, IconData icon})> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s4.w,
        vertical: AppSpacing.s4.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < entries.length; i += 2) ...[
            if (i > 0) SizedBox(height: AppSpacing.s4.h),
            if (i + 1 < entries.length)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _RecapCell(entry: entries[i])),
                  SizedBox(width: AppSpacing.s4.w),
                  Expanded(child: _RecapCell(entry: entries[i + 1])),
                ],
              )
            else
              _RecapCell(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _RecapCell extends StatelessWidget {
  const _RecapCell({required this.entry});

  final ({String label, String value, IconData icon}) entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(entry.icon, size: 11.sp, color: AppColors.inkSoft),
            SizedBox(width: AppSpacing.s1.w),
            Text(
              entry.label.toUpperCase(),
              style: AppTypography.body.copyWith(
                fontSize: 10.sp,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          entry.value,
          style: AppTypography.bodyStrong.copyWith(
            fontSize: 14.sp,
            color: AppColors.ink,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

/// Chip affichant une matiere dans les sections "lecture seule" (derived,
/// obligatoire non-toggleable). [isObligatory] ajoute un * rouge pour
/// distinguer les matieres qui ne peuvent pas etre deselectionnes.
class _SubjectSummaryChip extends StatelessWidget {
  const _SubjectSummaryChip({
    required this.subject,
    required this.langKey,
    this.isObligatory = false,
  });

  final Subject subject;
  final String langKey;
  final bool isObligatory;

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
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTypography.bodyStrong.copyWith(
                fontSize: 13.sp,
                color: AppColors.primary,
              ),
            ),
          ),
          if (isObligatory) ...[
            SizedBox(width: 2.w),
            Text(
              '*',
              style: AppTypography.bodyStrong.copyWith(
                fontSize: 13.sp,
                color: AppColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Stream picker : liste verticale de SelectionCard pour choisir une serie.
/// Tap card = commit immediat (setStreamIdDraft) + transition vers la vue
/// derivee. Pas de CTA Continuer intermediaire — coherent avec l'auto-avance
/// des steps 0/2/3.
class _StreamPicker extends StatelessWidget {
  const _StreamPicker({
    required this.streams,
    required this.langKey,
    required this.onConfirm,
  });

  final List<Serie> streams;
  final String langKey;
  final void Function(String streamId) onConfirm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.s3.h),
          for (final stream in streams) ...[
            SelectionCard(
              title: stream.name[langKey] ?? stream.name.values.first,
              description: stream.descriptionFor(langKey),
              selected: false,
              variant: SelectionCardVariant.standard,
              showRadio: false,
              onTap: () => onConfirm(stream.serieId),
            ),
            SizedBox(height: AppSpacing.s2.h),
          ],
          SizedBox(height: AppSpacing.s4.h),
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
