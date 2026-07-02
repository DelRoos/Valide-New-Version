// Story A.3 — Bottom sheet multi-étapes : niveau → série → matières.
//
// Approche B (client direct). Dérive les matières en mémoire depuis
// catalogueProvider (déjà chargé au boot) — 0 read Firestore supplémentaire.
// PageController interne : chaque step est une page de la PageView.
//
// 5 modes picker (identiques à l'onboarding) :
//   derived, tvePicker → DerivedPreviewStep (groupes + chips read-only).
//   optOut, freeWithObligatory, seriesPlusOptional → InteractiveStep
//     (compteur + optionnelles toggleables + obligatoires locked).
//
// UX : si l'utilisateur a déjà une classe (initialStreamId non vide),
// on ouvre directement sur l'étape matières (step 2). Il peut revenir
// en arrière pour changer de niveau/série.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/catalogue/providers.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/cards/selection_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/domain/profile_failure.dart';
import '../../../onboarding/providers.dart';

class SchoolProfileEditSheet extends ConsumerStatefulWidget {
  const SchoolProfileEditSheet({
    super.key,
    required this.subSystem,
    required this.trackId,
    required this.initialLevelId,
    required this.initialStreamId,
    required this.initialPickedSubjectIds,
  });

  final String subSystem;
  final String trackId;
  final String initialLevelId;
  final String initialStreamId;
  final List<String> initialPickedSubjectIds;

  static Future<void> show(
    BuildContext context, {
    required String subSystem,
    required String trackId,
    required String levelId,
    required String streamId,
    required List<String> pickedSubjectIds,
  }) {
    return AppBottomSheet.show<void>(
      context,
      child: SchoolProfileEditSheet(
        subSystem: subSystem,
        trackId: trackId,
        initialLevelId: levelId,
        initialStreamId: streamId,
        initialPickedSubjectIds: pickedSubjectIds,
      ),
    );
  }

  @override
  ConsumerState<SchoolProfileEditSheet> createState() =>
      _SchoolProfileEditSheetState();
}

class _SchoolProfileEditSheetState
    extends ConsumerState<SchoolProfileEditSheet> {
  late final PageController _pageCtrl;
  int _step = 0;
  late String _levelId;
  String? _streamId;
  late Set<String> _pickedSubjectIds;
  // Clé = Subject.group, valeur = subjectId choisi (groupes exclusifs LV2/LV3).
  final Map<String, String> _picksByGroup = {};
  DerivedProfile? _derived;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _levelId = widget.initialLevelId;
    _streamId =
        widget.initialStreamId.isNotEmpty ? widget.initialStreamId : null;
    _pickedSubjectIds = Set.from(widget.initialPickedSubjectIds);
    // Si l'utilisateur a déjà une série, ouvrir directement sur l'étape matières (step 2).
    final startStep = _streamId != null ? 2 : 0;
    _step = startStep;
    _pageCtrl = PageController(initialPage: startStep);
    AppLogger.d(
      'SchoolProfileEditSheet.initState: subSystem=${widget.subSystem} trackId=${widget.trackId} '
      'levelId=$_levelId streamId=$_streamId pickedSubjects=${_pickedSubjectIds.length} startStep=$startStep',
    );
    if (_streamId != null) {
      final snapshot = ref.read(catalogueProvider).value;
      if (snapshot != null) {
        _derived = _deriveFromSnapshot(_streamId, snapshot);
        _initPickedSubjects();
        AppLogger.d(
          '  → derived at init: subjects=${_derived?.subjects.length ?? 0} '
          'pickerMode=${_derived?.pickerMode}',
        );
      }
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageCtrl.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  List<Serie> _compatibleStreams(String levelId, CatalogueSnapshot snapshot) {
    return snapshot.series
        .where((s) =>
            s.isActive &&
            s.niveauId == levelId &&
            (widget.trackId.isEmpty || s.filiereId == widget.trackId))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  bool _requiresStreamPicker(List<Serie> streams) {
    return streams.length > 1 ||
        streams.any((s) => s.pickerMode != PickerMode.derived);
  }

  void _onLevelSelected(String levelId, CatalogueSnapshot snapshot) {
    AppLogger.d(
      'SchoolProfileEditSheet._onLevelSelected: levelId=$levelId '
      'trackId=${widget.trackId} subSystem=${widget.subSystem}',
    );
    _levelId = levelId;
    final streams = _compatibleStreams(levelId, snapshot);
    AppLogger.d(
      '  → streams.length=${streams.length} '
      'ids=${streams.map((s) => s.serieId).toList()}',
    );

    if (!_requiresStreamPicker(streams)) {
      if (streams.isNotEmpty) {
        _onStreamSelected(streams.first.serieId, snapshot);
      } else {
        // Niveaux collège/Form 1-5 : aucune série, règle matchSerie=null.
        AppLogger.d('  → niveau sans série → dérive avec streamId=null → goTo(2)');
        _streamId = null;
        _derived = _deriveFromSnapshot(null, snapshot);
        AppLogger.d(
          '  → derived=${_derived != null} subjects=${_derived?.subjects.length ?? 0}',
        );
        _initPickedSubjects();
        setState(() {});
        _goTo(2);
      }
      return;
    }
    if (!streams.any((s) => s.serieId == _streamId)) _streamId = null;
    AppLogger.d('  → pickerRequired → goTo(1)');
    setState(() {});
    _goTo(1);
  }

  void _onStreamSelected(String streamId, CatalogueSnapshot snapshot) {
    AppLogger.d(
      'SchoolProfileEditSheet._onStreamSelected: streamId=$streamId levelId=$_levelId',
    );
    _streamId = streamId;
    _derived = _deriveFromSnapshot(streamId, snapshot);
    AppLogger.d(
      '  → derived=${_derived != null} subjects=${_derived?.subjects.length ?? 0} '
      'pickerMode=${_derived?.pickerMode}',
    );
    _initPickedSubjects();
    setState(() {});
    _goTo(2);
  }

  // Dérive le profil en mémoire depuis le catalogue (0 read Firestore).
  // streamId == null pour les niveaux sans série (collège, Form 1-5).
  DerivedProfile? _deriveFromSnapshot(
      String? streamId, CatalogueSnapshot snapshot) {
    AppLogger.d(
      'SchoolProfileEditSheet._deriveFromSnapshot: '
      'subSystem=${widget.subSystem} trackId=${widget.trackId} '
      'levelId=$_levelId streamId=$streamId '
      'rulesTotal=${snapshot.derivationRules.length}',
    );
    DerivationRule? rule;
    for (final r in snapshot.derivationRules) {
      if (!r.isActive) continue;
      if (r.matchSubSystem != widget.subSystem) continue;
      if (r.matchFiliere != '*' && r.matchFiliere != widget.trackId) continue;
      if (r.matchNiveau != _levelId) continue;
      if (r.matchSerie != streamId) continue;
      rule = r;
      break;
    }
    if (rule == null) {
      AppLogger.w(
        'SchoolProfileEditSheet._deriveFromSnapshot: no rule matched — '
        'subSystem=${widget.subSystem} trackId=${widget.trackId} '
        'levelId=$_levelId streamId=$streamId',
      );
      for (final r in snapshot.derivationRules.where((r) => r.isActive).take(3)) {
        AppLogger.d(
          '  rule sample: subSystem=${r.matchSubSystem} filiere=${r.matchFiliere} '
          'niveau=${r.matchNiveau} serie=${r.matchSerie}',
        );
      }
      return null;
    }

    final serie =
        snapshot.series.where((s) => s.serieId == streamId).firstOrNull;
    final subjectSet = rule.subjectIds.toSet();
    final subjects = snapshot.subjects
        .where((s) => subjectSet.contains(s.subjectId))
        .toList();
    final examTargets = snapshot.examTargets
        .where((e) => rule!.examTargetIds.contains(e.examTargetId))
        .toList();
    final obligatory = snapshot.subjects
        .where((s) => rule!.obligatorySubjectIds.contains(s.subjectId))
        .toList();
    final optional = snapshot.subjects
        .where((s) => rule!.optionalSubjectIds.contains(s.subjectId))
        .toList();
    // Champs tvePicker — portés par Serie (vides pour les niveaux sans série).
    final professional = snapshot.subjects
        .where((s) =>
            serie?.professionalSubjectIds.contains(s.subjectId) ?? false)
        .toList();
    final relatedProfessional = snapshot.subjects
        .where((s) =>
            serie?.relatedProfessionalSubjectIds.contains(s.subjectId) ?? false)
        .toList();
    final other = snapshot.subjects
        .where((s) =>
            serie?.otherSubjectIds.contains(s.subjectId) ?? false)
        .toList();

    return DerivedProfile(
      subjects: subjects,
      examTargets: examTargets,
      canOptOut: rule.canOptOut,
      pickerMode: serie?.pickerMode ?? PickerMode.derived,
      obligatorySubjects: obligatory,
      optionalSubjects: optional,
      minSubjects: serie?.minSubjects,
      maxSubjects: serie?.maxSubjects,
      professionalSubjects: professional,
      relatedProfessionalSubjects: relatedProfessional,
      otherSubjects: other,
    );
  }

  // Agrège toutes les matières selon le mode — miroir de l'onboarding.
  List<Subject> _allSubjectsFor(DerivedProfile p) {
    return switch (p.pickerMode) {
      PickerMode.derived || PickerMode.optOut => p.subjects,
      PickerMode.freeWithObligatory ||
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

  // Initialise _pickedSubjectIds selon le pickerMode.
  void _initPickedSubjects() {
    final d = _derived;
    if (d == null) return;
    _picksByGroup.clear();
    switch (d.pickerMode) {
      case PickerMode.derived:
        _initDerivedPicks(d.subjects);
      case PickerMode.tvePicker:
        _initDerivedPicks(_allSubjectsFor(d));
      case PickerMode.optOut:
        // Par défaut tout coché ; conserver l'intersection si l'utilisateur
        // avait déjà fait des choix pour ce niveau.
        final allIds = d.subjects.map((s) => s.subjectId).toSet();
        final kept = _pickedSubjectIds.intersection(allIds);
        _pickedSubjectIds = kept.isEmpty ? Set.from(allIds) : kept;
        _pickedSubjectIds.addAll(
            d.obligatorySubjects.map((s) => s.subjectId));
      case PickerMode.freeWithObligatory:
      case PickerMode.seriesPlusOptional:
        final optionalIds =
            d.optionalSubjects.map((s) => s.subjectId).toSet();
        _pickedSubjectIds = _pickedSubjectIds.intersection(optionalIds);
        _pickedSubjectIds.addAll(
            d.obligatorySubjects.map((s) => s.subjectId));
    }
  }

  // Pour derived/tvePicker : non-groupées toujours cochées, groupes conservés.
  void _initDerivedPicks(List<Subject> subjects) {
    final allIds = subjects.map((s) => s.subjectId).toSet();
    final groups = _groupsIn(subjects);
    final groupIds = groups.values
        .expand((variants) => variants.map((s) => s.subjectId))
        .toSet();
    final newPicked = allIds.difference(groupIds);
    for (final entry in groups.entries) {
      final gIds = entry.value.map((s) => s.subjectId).toSet();
      final overlap = _pickedSubjectIds.intersection(gIds);
      if (overlap.isNotEmpty) {
        final pick = overlap.first;
        _picksByGroup[entry.key] = pick;
        newPicked.add(pick);
      }
    }
    _pickedSubjectIds = newPicked;
  }

  Future<void> _onSave() async {
    final d = _derived;
    if (d == null) return;
    final streamId = _streamId ?? '';
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);

    final allSubjects = _allSubjectsFor(d);
    final derivedIds = allSubjects.map((s) => s.subjectId).toList();
    final examIds = d.examTargets.map((e) => e.examTargetId).toList();
    final optedOut =
        derivedIds.where((id) => !_pickedSubjectIds.contains(id)).toList();

    final result = await ref
        .read(userProfileRepositoryProvider)
        .updateSchoolProfile(
          trackId: widget.trackId,
          levelId: _levelId,
          streamId: streamId,
          derivedSubjects: derivedIds,
          examTargets: examIds,
          pickedSubjects: _pickedSubjectIds.toList(),
          optedOutSubjects: optedOut,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (f) {
        AppLogger.w(
            'SchoolProfileEditSheet.save: kind=${f.kind.name} msg=${f.message}');
        final msg = switch (f.kind) {
          ProfileFailureKind.permissionDenied ||
          ProfileFailureKind.notAuthenticated =>
            l10n.errorPermissionDenied,
          ProfileFailureKind.networkUnavailable => l10n.errorNetworkUnavailable,
          ProfileFailureKind.unknown => l10n.errorFirestoreUnknown,
        };
        AppToast.show(context, message: msg, tone: ToastTone.error);
      },
      (_) {
        AppToast.show(context, message: l10n.profileEditSuccess);
        Navigator.of(context, rootNavigator: true).maybePop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final catalogueAsync = ref.watch(catalogueProvider);

    return catalogueAsync.when(
      loading: () => const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, st) => const SizedBox.shrink(),
      data: (snapshot) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (_step > 0) ...[
                    GestureDetector(
                      onTap: () {
                        if (_step == 2 &&
                            !_requiresStreamPicker(
                                _compatibleStreams(_levelId, snapshot))) {
                          _goTo(0);
                        } else {
                          _goTo(_step - 1);
                        }
                      },
                      child: Icon(LucideIcons.arrowLeft,
                          size: AppIconSize.md, color: AppColors.ink),
                    ),
                    SizedBox(width: AppSpacing.s2.w),
                  ],
                  Expanded(
                    child: Text(l10n.profileEditSchoolTitle,
                        style: AppTypography.h3),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s3.h),
              SizedBox(
                height: 380.h,
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildLevelStep(snapshot, locale, l10n),
                    _buildStreamStep(snapshot, locale, l10n),
                    _buildSubjectsStep(locale, l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelStep(
      CatalogueSnapshot snapshot, String locale, AppLocalizations l10n) {
    final levels = snapshot.niveaux
        .where((n) =>
            n.isActive &&
            n.subSystem == widget.subSystem &&
            n.filiereIds.contains(widget.trackId))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.profileEditSchoolLevelLabel, style: AppTypography.bodyStrong),
        SizedBox(height: AppSpacing.s3.h),
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final cols = constraints.maxWidth >= 840 ? 3 : 2;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: AppSpacing.s2.w,
                  mainAxisSpacing: AppSpacing.s2.h,
                  mainAxisExtent: 52.h,
                ),
                itemCount: levels.length,
                itemBuilder: (_, i) {
                  final n = levels[i];
                  final name = n.name[locale] ?? n.name['fr'] ?? n.niveauId;
                  return SelectionCard(
                    title: name,
                    selected: _levelId == n.niveauId,
                    variant: SelectionCardVariant.compact,
                    showRadio: false,
                    maxLines: 2,
                    onTap: () => _onLevelSelected(n.niveauId, snapshot),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStreamStep(
      CatalogueSnapshot snapshot, String locale, AppLocalizations l10n) {
    final streams = _compatibleStreams(_levelId, snapshot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.profileEditSchoolStreamLabel,
            style: AppTypography.bodyStrong),
        SizedBox(height: AppSpacing.s3.h),
        Expanded(
          child: ListView.separated(
            itemCount: streams.length,
            separatorBuilder: (ctx, i) => SizedBox(height: AppSpacing.s2.h),
            itemBuilder: (_, i) {
              final s = streams[i];
              final name = s.name[locale] ?? s.name['fr'] ?? s.serieId;
              final desc = s.description[locale] ?? s.description['fr'];
              return SelectionCard(
                title: name,
                description: desc,
                selected: _streamId == s.serieId,
                variant: SelectionCardVariant.compact,
                showRadio: false,
                onTap: () => _onStreamSelected(s.serieId, snapshot),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsStep(String locale, AppLocalizations l10n) {
    final d = _derived;
    if (d == null) return const SizedBox.shrink();
    return switch (d.pickerMode) {
      PickerMode.optOut ||
      PickerMode.freeWithObligatory ||
      PickerMode.seriesPlusOptional =>
        _buildInteractiveStep(d, locale, l10n),
      PickerMode.derived ||
      PickerMode.tvePicker =>
        _buildDerivedPreviewStep(d, locale, l10n),
    };
  }

  // Modes interactifs : optOut / freeWithObligatory / seriesPlusOptional.
  // Compteur + optionnelles toggleables (canAddMore si max non atteint) +
  // obligatoires locked. CTA désactivé si hors bornes min/max.
  Widget _buildInteractiveStep(
      DerivedProfile d, String locale, AppLocalizations l10n) {
    final optionalIds = d.optionalSubjects.map((s) => s.subjectId).toSet();
    final selectedOptionalCount =
        _pickedSubjectIds.intersection(optionalIds).length;
    final totalSelected =
        d.obligatorySubjects.length + selectedOptionalCount;
    final maxS =
        d.maxSubjects ?? (d.obligatorySubjects.length + d.optionalSubjects.length);
    final minS = d.minSubjects ?? d.obligatorySubjects.length;
    final canAddMore = totalSelected < maxS;
    final isValid = totalSelected >= minS && totalSelected <= maxS;

    final sectionStyle = AppTypography.caption.copyWith(
      color: AppColors.inkSoft,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.profileEditSchoolSubjectsLabel,
                  style: AppTypography.bodyStrong),
            ),
            Text(
              l10n.onboardingPickerCounter(totalSelected, maxS),
              style: AppTypography.caption
                  .copyWith(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.s3.h),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.optionalSubjects.isNotEmpty) ...[
                  Text(l10n.onboardingPickerOptionalTitle,
                      style: sectionStyle),
                  SizedBox(height: AppSpacing.s2.h),
                  Wrap(
                    spacing: AppSpacing.s2.w,
                    runSpacing: AppSpacing.s2.h,
                    children: d.optionalSubjects
                        .map((s) => _chipFor(s, locale,
                            toggleable: true, canAddMore: canAddMore))
                        .toList(),
                  ),
                  SizedBox(height: AppSpacing.s4.h),
                ],
                if (d.obligatorySubjects.isNotEmpty) ...[
                  Text(l10n.onboardingPickerObligatoryTitle,
                      style: sectionStyle),
                  SizedBox(height: AppSpacing.s2.h),
                  Wrap(
                    spacing: AppSpacing.s2.w,
                    runSpacing: AppSpacing.s2.h,
                    children: d.obligatorySubjects
                        .map((s) => _chipFor(s, locale))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.s4.h),
        AppButton.primary(
          label: _saving ? l10n.profileEditSchoolSaving : l10n.saveLabel,
          onPressed: (isValid && !_saving) ? _onSave : null,
        ),
      ],
    );
  }

  // Modes lecture : derived / tvePicker.
  // Groupes LV2/LV3 avec sélection exclusive ; non-groupés read-only.
  // tvePicker : sections Pro / Related / Other. CTA désactivé tant que
  // tous les groupes ne sont pas résolus.
  Widget _buildDerivedPreviewStep(
      DerivedProfile d, String locale, AppLocalizations l10n) {
    final allSubjects = _allSubjectsFor(d);
    final groups = _groupsIn(allSubjects);
    final groupSubjectIds = groups.values
        .expand((variants) => variants.map((s) => s.subjectId))
        .toSet();
    final allGroupsPicked = groups.keys.every(_picksByGroup.containsKey);
    final isTve = d.pickerMode == PickerMode.tvePicker;

    final sectionStyle = AppTypography.caption.copyWith(
      color: AppColors.inkSoft,
      fontWeight: FontWeight.w600,
    );

    List<Subject> ungrouped(List<Subject> src) =>
        src.where((s) => !groupSubjectIds.contains(s.subjectId)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.profileEditSchoolSubjectsLabel,
            style: AppTypography.bodyStrong),
        SizedBox(height: AppSpacing.s3.h),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Groupes exclusifs (LV2/LV3) — communs aux deux modes.
                for (final entry in groups.entries) ...[
                  Text(_resolveGroupLabel(entry.key, l10n),
                      style: sectionStyle),
                  SizedBox(height: AppSpacing.s1.h),
                  Text(
                    l10n.onboardingGroupPickHint,
                    style: AppTypography.meta
                        .copyWith(color: AppColors.inkSoft),
                  ),
                  SizedBox(height: AppSpacing.s2.h),
                  Wrap(
                    spacing: AppSpacing.s2.w,
                    runSpacing: AppSpacing.s2.h,
                    children: entry.value
                        .map((s) => _groupChipFor(s, locale, entry.key))
                        .toList(),
                  ),
                  SizedBox(height: AppSpacing.s4.h),
                ],
                // tvePicker : sections Pro / Related / Other.
                if (isTve) ...[
                  if (ungrouped(d.professionalSubjects).isNotEmpty) ...[
                    Text(l10n.onboardingPickerProfessionalTitle,
                        style: sectionStyle),
                    SizedBox(height: AppSpacing.s2.h),
                    Wrap(
                      spacing: AppSpacing.s2.w,
                      runSpacing: AppSpacing.s2.h,
                      children: ungrouped(d.professionalSubjects)
                          .map((s) => _chipFor(s, locale))
                          .toList(),
                    ),
                    SizedBox(height: AppSpacing.s4.h),
                  ],
                  if (ungrouped(d.relatedProfessionalSubjects).isNotEmpty) ...[
                    Text(l10n.onboardingPickerRelatedTitle,
                        style: sectionStyle),
                    SizedBox(height: AppSpacing.s2.h),
                    Wrap(
                      spacing: AppSpacing.s2.w,
                      runSpacing: AppSpacing.s2.h,
                      children: ungrouped(d.relatedProfessionalSubjects)
                          .map((s) => _chipFor(s, locale))
                          .toList(),
                    ),
                    SizedBox(height: AppSpacing.s4.h),
                  ],
                  if (ungrouped(d.otherSubjects).isNotEmpty) ...[
                    Text(l10n.onboardingPickerOtherTitle,
                        style: sectionStyle),
                    SizedBox(height: AppSpacing.s2.h),
                    Wrap(
                      spacing: AppSpacing.s2.w,
                      runSpacing: AppSpacing.s2.h,
                      children: ungrouped(d.otherSubjects)
                          .map((s) => _chipFor(s, locale))
                          .toList(),
                    ),
                  ],
                ],
                // derived : liste plate non-groupée.
                if (!isTve)
                  Wrap(
                    spacing: AppSpacing.s2.w,
                    runSpacing: AppSpacing.s2.h,
                    children: ungrouped(d.subjects)
                        .map((s) => _chipFor(s, locale))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.s4.h),
        AppButton.primary(
          label: _saving ? l10n.profileEditSchoolSaving : l10n.saveLabel,
          onPressed: (allGroupsPicked && !_saving) ? _onSave : null,
        ),
      ],
    );
  }

  // Chip matière — read-only si toggleable=false, toggleable sinon.
  // canAddMore=false → le onTap ne peut qu'enlever (pas ajouter).
  Widget _chipFor(
    Subject s,
    String locale, {
    bool toggleable = false,
    bool canAddMore = true,
  }) {
    final name = s.name[locale] ?? s.name['fr'] ?? s.subjectId;
    final isPicked = _pickedSubjectIds.contains(s.subjectId);
    final isOn = isPicked || !toggleable;

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3.w,
        vertical: AppSpacing.s2.h,
      ),
      decoration: BoxDecoration(
        color: isOn ? AppColors.primarySoft : AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isOn
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border,
          width: isOn ? AppBorderWidth.bold : AppBorderWidth.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (toggleable) ...[
            Icon(
              isPicked ? LucideIcons.checkCircle : LucideIcons.plusCircle,
              color: isPicked ? AppColors.primary : AppColors.inkSoft,
              size: AppIconSize.sm,
            ),
            SizedBox(width: AppSpacing.s1.w),
          ],
          Flexible(
            child: Text(
              name,
              style: AppTypography.bodyStrong.copyWith(
                fontSize: AppFontSize.bodySmall,
                color: isOn ? AppColors.primary : AppColors.inkSoft,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (!toggleable) return content;

    return GestureDetector(
      onTap: () => setState(() {
        if (isPicked) {
          _pickedSubjectIds.remove(s.subjectId);
        } else if (canAddMore) {
          _pickedSubjectIds.add(s.subjectId);
        }
      }),
      child: content,
    );
  }

  // Chip avec sélection exclusive par groupe (LV2/LV3).
  Widget _groupChipFor(Subject s, String locale, String groupKey) {
    final name = s.name[locale] ?? s.name['fr'] ?? s.subjectId;
    final isPicked = _picksByGroup[groupKey] == s.subjectId;

    return GestureDetector(
      onTap: () => setState(() {
        final prev = _picksByGroup[groupKey];
        if (prev != null) _pickedSubjectIds.remove(prev);
        if (isPicked) {
          _picksByGroup.remove(groupKey);
        } else {
          _picksByGroup[groupKey] = s.subjectId;
          _pickedSubjectIds.add(s.subjectId);
        }
      }),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s3.w,
          vertical: AppSpacing.s2.h,
        ),
        decoration: BoxDecoration(
          color: isPicked ? AppColors.primarySoft : AppColors.bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isPicked
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.border,
            width: isPicked ? AppBorderWidth.bold : AppBorderWidth.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPicked ? LucideIcons.checkCircle : LucideIcons.plusCircle,
              color: isPicked ? AppColors.primary : AppColors.inkSoft,
              size: AppIconSize.sm,
            ),
            SizedBox(width: AppSpacing.s1.w),
            Flexible(
              child: Text(
                name,
                style: AppTypography.bodyStrong.copyWith(
                  fontSize: AppFontSize.bodySmall,
                  color: isPicked ? AppColors.primary : AppColors.inkSoft,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Subject>> _groupsIn(List<Subject> subjects) {
    final result = <String, List<Subject>>{};
    for (final s in subjects) {
      final g = s.group;
      if (g != null) result.putIfAbsent(g, () => []).add(s);
    }
    return Map.fromEntries(result.entries.where((e) => e.value.length >= 2));
  }

  String _resolveGroupLabel(String groupKey, AppLocalizations l10n) {
    return switch (groupKey) {
      'lv2' => l10n.onboardingGroupLv2,
      'lv3' => l10n.onboardingGroupLv3,
      _ => groupKey.toUpperCase(),
    };
  }
}
