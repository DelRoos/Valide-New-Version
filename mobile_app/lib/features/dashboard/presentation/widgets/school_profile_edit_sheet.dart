// Story A.3 — Bottom sheet multi-étapes : niveau → série → matières.
//
// Approche B (client direct). Derive les matières en mémoire depuis
// catalogueProvider (déjà chargé au boot) — 0 read Firestore supplémentaire.
// PageController interne : chaque step est une page de la PageView.

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
  final _pageCtrl = PageController();
  int _step = 0;
  late String _levelId;
  String? _streamId;
  late Set<String> _pickedSubjectIds;
  DerivedProfile? _derived;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _levelId = widget.initialLevelId;
    _streamId = widget.initialStreamId;
    _pickedSubjectIds = Set.from(widget.initialPickedSubjectIds);
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

  void _onLevelSelected(String levelId, CatalogueSnapshot snapshot) {
    _levelId = levelId;
    final streams = snapshot.series
        .where((s) => s.isActive && s.niveauId == levelId && s.filiereId == widget.trackId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (streams.length == 1) {
      _onStreamSelected(streams.first.serieId, snapshot);
      return;
    }
    // Conserver la série actuelle uniquement si compatible avec le nouveau niveau.
    if (!streams.any((s) => s.serieId == _streamId)) {
      _streamId = null;
    }
    setState(() {});
    _goTo(1);
  }

  void _onStreamSelected(String streamId, CatalogueSnapshot snapshot) {
    _streamId = streamId;
    _derived = _deriveFromSnapshot(streamId, snapshot);
    _initPickedSubjects();
    setState(() {});
    _goTo(2);
  }

  // Dérive le profil en mémoire depuis le snapshot (0 read Firestore).
  DerivedProfile? _deriveFromSnapshot(
      String streamId, CatalogueSnapshot snapshot) {
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
    if (rule == null) return null;

    final serie =
        snapshot.series.where((s) => s.serieId == streamId).firstOrNull;
    final subjectSet = rule.subjectIds.toSet();
    final subjects =
        snapshot.subjects.where((s) => subjectSet.contains(s.subjectId)).toList();
    final examTargets = snapshot.examTargets
        .where((e) => rule!.examTargetIds.contains(e.examTargetId))
        .toList();
    final obligatory = snapshot.subjects
        .where((s) => rule!.obligatorySubjectIds.contains(s.subjectId))
        .toList();
    final optional = snapshot.subjects
        .where((s) => rule!.optionalSubjectIds.contains(s.subjectId))
        .toList();

    return DerivedProfile(
      subjects: subjects,
      examTargets: examTargets,
      canOptOut: rule.canOptOut,
      pickerMode: serie?.pickerMode ?? PickerMode.derived,
      obligatorySubjects: obligatory,
      optionalSubjects: optional,
    );
  }

  void _initPickedSubjects() {
    if (_derived == null) return;
    final allIds = _derived!.subjects.map((s) => s.subjectId).toSet();
    if (_derived!.pickerMode == PickerMode.derived) {
      _pickedSubjectIds = Set.from(allIds);
      return;
    }
    // Conserver l'intersection avec les ids dérivés ; fallback = tout dériver.
    final kept = _pickedSubjectIds.intersection(allIds);
    _pickedSubjectIds = kept.isEmpty ? Set.from(allIds) : kept;
    // Les obligatoires sont toujours inclus.
    for (final s in _derived!.obligatorySubjects) {
      _pickedSubjectIds.add(s.subjectId);
    }
  }

  Future<void> _onSave() async {
    final d = _derived;
    final streamId = _streamId;
    if (d == null || streamId == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);

    final derivedIds = d.subjects.map((s) => s.subjectId).toList();
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
      loading: () =>
          const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, st) => const SizedBox.shrink(),
      data: (snapshot) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête avec bouton retour
              Row(
                children: [
                  if (_step > 0) ...[
                    GestureDetector(
                      onTap: () => _goTo(_step - 1),
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
        Text(l10n.profileEditSchoolLevelLabel,
            style: AppTypography.bodyStrong),
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
    final streams = snapshot.series
        .where((s) => s.isActive && s.niveauId == _levelId && s.filiereId == widget.trackId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

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

    final isInteractive = d.pickerMode != PickerMode.derived;
    final obligatoryIds =
        d.obligatorySubjects.map((s) => s.subjectId).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.profileEditSchoolSubjectsLabel,
            style: AppTypography.bodyStrong),
        SizedBox(height: AppSpacing.s3.h),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: AppSpacing.s2.w,
              runSpacing: AppSpacing.s2.h,
              children: d.subjects.map((s) {
                final name = s.name[locale] ?? s.name['fr'] ?? s.subjectId;
                final isPicked = _pickedSubjectIds.contains(s.subjectId);
                final isObligatory = obligatoryIds.contains(s.subjectId);
                // Les obligatoires et le mode derived ne sont pas toggleables.
                final toggleable = isInteractive && !isObligatory;
                return FilterChip(
                  label: Text(name,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPicked ? AppColors.primary : AppColors.inkSoft,
                      )),
                  selected: isPicked,
                  onSelected: toggleable
                      ? (v) => setState(() {
                            if (v) {
                              _pickedSubjectIds.add(s.subjectId);
                            } else {
                              _pickedSubjectIds.remove(s.subjectId);
                            }
                          })
                      : null,
                  selectedColor: AppColors.primarySoft,
                  backgroundColor: AppColors.bg,
                  checkmarkColor: AppColors.primary,
                  side: BorderSide(
                    color: isPicked ? AppColors.primary : AppColors.border,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.s4.h),
        AppButton.primary(
          label: _saving ? l10n.profileEditSchoolSaving : l10n.saveLabel,
          onPressed: _saving ? null : _onSave,
        ),
      ],
    );
  }
}
