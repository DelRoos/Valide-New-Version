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
import 'package:go_router/go_router.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/catalogue/providers.dart';
import '../../../../core/firebase/providers.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/widgets/feedback/error_retry_view.dart';
import '../../../../core/widgets/feedback/onboarding_loader.dart';
import '../../../../core/widgets/picker/picker_section_scaffold.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/sub_system.dart';
import '../../providers.dart';
import '../state/onboarding_notifier.dart';
import '../state/onboarding_providers.dart';
import '../state/onboarding_state.dart';
import '../widgets/picker/stream_picker_derived_view.dart';
import '../widgets/picker/stream_picker_interactive.dart';
import '../widgets/picker/stream_picker_recap_helper.dart';
import '../widgets/picker/stream_picker_selector.dart';

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
    required OnboardingState state,
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
    // font reussir derive() via Cas 3. Ne montrer StreamPickerEmpty que si
    // aucune regle `matchSerie=null` n'existe pour ce profil ; sinon Cas 3 OK.
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
        return StreamPickerEmpty(
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
      return StreamPicker(
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
        buildRecapEntries(snapshot, state, profile, langKey, l10n);

    // Utilisateur deja authentifie (chemin "J'ai un compte" -> step 5 -> step 2)
    // : on utilise setStreamAndSubjects qui transitionne vers step 6 sans flush
    // guest. L'ecriture Firestore se fera au step 9 (SuccessCelebrationStepBody).
    // Chemin visiteur : _startRevising flush en direct + /dashboard.
    final isAuthenticated = state.authProvider != null &&
        state.authProvider != OnboardingAuthProvider.guest;
    final ctaLabel =
        isAuthenticated ? l10n.onboardingContinue : l10n.onboardingStartRevising;

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

      return InteractiveSubjectPicker(
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
        validateLabel: ctaLabel,
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
          if (isAuthenticated) {
            notifier.setStreamAndSubjects(
              streamId: state.streamId,
              pickedSubjects: picked,
            );
          } else {
            _startRevising(streamId: state.streamId, pickedSubjects: picked);
          }
        },
      );
    }

    // Modes read-only (derived / tvePicker) : chips recap sans choix.
    final allSubjects = _allSubjectsFor(profile);
    final groups = _groupsIn(allSubjects);
    final ungrouped =
        allSubjects.where((s) => s.group == null).toList(growable: false);
    final allGroupsPicked = groups.keys.every(_picksByGroup.containsKey);

    return DerivedPreview(
      recapEntries: recapEntries,
      ungroupedSubjects: ungrouped,
      groups: groups,
      picksByGroup: _picksByGroup,
      langKey: langKey,
      validateLabel: ctaLabel,
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
        if (isAuthenticated) {
          notifier.setStreamAndSubjects(
            streamId: state.streamId,
            pickedSubjects: picked,
          );
        } else {
          _startRevising(streamId: state.streamId, pickedSubjects: picked);
        }
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
          // Sync le state notifier avec les sujets confirmes. Sans ca,
          // pickedSubjects reste [] dans le notifier et le path upgrade
          // dashboard -> "Creer mon compte" -> step 9 flush ecraserait
          // Firestore avec une liste vide.
          ref.read(onboardingNotifierProvider.notifier).commitSubjectsForGuest(
                streamId: streamId,
                pickedSubjects: pickedSubjects,
              );
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
