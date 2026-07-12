import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/cards/performance_level.dart';
import '../../../../core/widgets/picker/subject_icon_resolver.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/providers.dart';
import '../widgets/exam_school_picker_sheet.dart';
import '../widgets/exam_sujet_card.dart';

// Alias local pour lisibilité — la constante partagée vit sur AppRoutes.
const int _kAnnalesSentinel = AppRoutes.examSujetsAnnalesSequence;

// Sentinel pour les sujets sans source (option « Non renseignée » dans le picker).
const String _kUnknownSchoolId = '_unknown_school_';

// Mock — sera remplacé par Firestore (exam_sujets/{sujetId} scopé matière/séquence).
const List<_MockSujet> _kMockSujets = [
  _MockSujet(title: 'Devoir 1er trimestre', year: 2024, source: 'Lycée Général Leclerc', total: 8, done: 5, score: 78, isExam: false),
  _MockSujet(title: 'Contrôle continu', year: 2024, source: 'Collège Vogt · Yaoundé', total: 6, done: 3, score: 55, isExam: false),
  _MockSujet(title: 'Composition harmonisée', year: 2023, source: null, total: 10, done: 8, score: 88, isExam: false),
  _MockSujet(title: 'BEPC blanc', year: 2023, source: 'MINESEC · Session juin', total: 5, done: 0, score: 0, isExam: true),
  _MockSujet(title: 'Devoir surveillé', year: 2022, source: 'Lycée Bilingue Yaoundé', total: 7, done: 2, score: 32, isExam: false),
];

class ExamSujetsPage extends ConsumerStatefulWidget {
  const ExamSujetsPage({
    super.key,
    required this.sequenceNumber,
    required this.subjectId,
  });

  final int sequenceNumber;
  final String subjectId;

  @override
  ConsumerState<ExamSujetsPage> createState() => _ExamSujetsPageState();
}

class _ExamSujetsPageState extends ConsumerState<ExamSujetsPage> {
  // Filtres.
  final Set<int> _selectedYears = <int>{};
  ExamSchoolOption? _selectedSchool;

  bool get _isAnnales => widget.sequenceNumber == _kAnnalesSentinel;
  bool get _yearHasFilter => _selectedYears.isNotEmpty;

  /// Années uniques disponibles, triées desc (plus récente en premier).
  List<int> get _availableYears {
    final years = _kMockSujets.map((s) => s.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  void _toggleYear(int year) {
    setState(() {
      if (_selectedYears.contains(year)) {
        _selectedYears.remove(year);
      } else {
        _selectedYears.add(year);
      }
    });
  }

  /// Options école dérivées des mocks pour peupler le picker sheet.
  List<ExamSchoolOption> _schoolOptions(AppLocalizations l10n) {
    final seen = <String?>{};
    for (final s in _kMockSujets) {
      seen.add(s.source);
    }
    final list = <ExamSchoolOption>[];
    for (final name in seen) {
      if (name == null) {
        list.add(ExamSchoolOption(
          id: _kUnknownSchoolId,
          label: l10n.examSujetsFilterSchoolUnknown,
        ));
      } else {
        list.add(ExamSchoolOption(id: name, label: name));
      }
    }
    list.sort((a, b) => a.label.compareTo(b.label));
    return list;
  }

  List<_MockSujet> get _filteredSujets {
    return _kMockSujets.where((s) {
      if (_selectedYears.isNotEmpty && !_selectedYears.contains(s.year)) {
        return false;
      }
      if (_selectedSchool != null) {
        if (_selectedSchool!.id == _kUnknownSchoolId) {
          if (s.source != null) return false;
        } else if (s.source != _selectedSchool!.id) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _openSchoolPicker(AppLocalizations l10n) {
    return showExamSchoolPickerSheet(
      context: context,
      options: _schoolOptions(l10n),
      selected: _selectedSchool,
      onSchoolSelected: (opt) {
        if (!mounted) return;
        setState(() => _selectedSchool = opt);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final subjectsAsync = ref.watch(userSubjectsProvider);

    final subject = subjectsAsync.maybeWhen(
      data: (list) =>
          list.where((s) => s.subjectId == widget.subjectId).firstOrNull,
      orElse: () => null,
    );
    // Fallback intelligent pour les 3 états AsyncValue :
    // - data + match : nom localisé de la matière
    // - loading : placeholder discret « … » pour éviter d'afficher l'ID brut
    // - error / data sans match : fallback sur widget.subjectId brut
    //   (mieux qu'un écran vide, l'utilisateur voit qu'il y a un souci de contexte)
    final subjectName = subject?.name[langCode] ??
        subject?.name['fr'] ??
        (subjectsAsync.isLoading ? '…' : widget.subjectId);
    final subjectIcon = subjectIconFor(subject?.icon ?? '');

    final eyebrow = _isAnnales
        ? l10n.examsFolderExamTitle
        : l10n.examSujetsHeaderEyebrow(widget.sequenceNumber);

    final filtered = _filteredSujets;
    final totalExos = filtered.fold<int>(0, (s, e) => s + e.total);
    final doneExos =
        filtered.fold<int>(0, (s, e) => s + e.done.clamp(0, e.total));
    final overallProgress = totalExos == 0 ? 0.0 : doneExos / totalExos;
    final years = _availableYears;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _Header(
            eyebrow: eyebrow,
            subjectName: subjectName,
            subjectIcon: subjectIcon,
            summary: l10n.examSujetsSummary(doneExos, totalExos),
            progress: overallProgress,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.s4.w,
                  AppSpacing.s4.h,
                  AppSpacing.s4.w,
                  AppSpacing.s8.h,
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtre année — chips multi-sélection + chip « Tous » en tête.
                  _FilterSection(
                    label: l10n.examSujetsFilterYearLabel,
                    child: _YearChipsRow(
                      years: years,
                      selected: _selectedYears,
                      allLabel: l10n.examSujetsFilterAll,
                      onToggle: _toggleYear,
                      onClearAll: () =>
                          setState(() => _selectedYears.clear()),
                    ),
                  ),
                  SizedBox(height: AppSpacing.s3.h),

                  // Filtre école — bouton pill qui ouvre le picker sheet.
                  _FilterSection(
                    label: l10n.examSujetsFilterSchoolLabel,
                    child: _SchoolFilterButton(
                      label: _selectedSchool?.label ??
                          l10n.examSujetsFilterSchoolAllChip,
                      isActive: _selectedSchool != null,
                      onTap: () => _openSchoolPicker(l10n),
                      onClear: _selectedSchool != null
                          ? () => setState(() => _selectedSchool = null)
                          : null,
                    ),
                  ),
                  SizedBox(height: AppSpacing.s4.h),

                  if (filtered.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.s6.h),
                      child: _EmptyState(label: l10n.examSujetsEmpty),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.examSujetsSectionTitle(filtered.length),
                            style: AppTypography.h3
                                .copyWith(fontSize: AppFontSize.h3),
                          ),
                        ),
                        if (_selectedSchool != null || _yearHasFilter)
                          _ResetFiltersButton(onTap: () => setState(() {
                                _selectedYears.clear();
                                _selectedSchool = null;
                              })),
                      ],
                    ),
                    SizedBox(height: AppSpacing.s3.h),
                    ...List.generate(filtered.length, (i) {
                      final s = filtered[i];
                      return Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.s3.h),
                        child: ExamSujetCard(
                          title: '${s.title} ${s.year}',
                          year: s.year,
                          source: s.source,
                          exosDone: s.done.clamp(0, s.total),
                          exosTotal: s.total,
                          level: performanceLevelFromScore(s.score),
                          // Mode annales (folder Sujets d'examen) : tout est
                          // examen. Sinon : dépend du champ mock.
                          isExam: _isAnnales || s.isExam,
                          onTap: () {
                            if (subject == null) return;
                            GoRouter.of(context).push(
                              '/subject/${subject.subjectId}',
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockSujet {
  const _MockSujet({
    required this.title,
    required this.year,
    required this.source,
    required this.total,
    required this.done,
    required this.score,
    required this.isExam,
  });

  final String title;
  final int year;
  final String? source;
  final int total;
  final int done;
  final int score;
  final bool isExam;
}

// ── Filter widgets ────────────────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.eyebrow.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: AppFontSize.eyebrow,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: AppSpacing.s2.h),
        child,
      ],
    );
  }
}

class _YearChipsRow extends StatelessWidget {
  const _YearChipsRow({
    required this.years,
    required this.selected,
    required this.onToggle,
    required this.onClearAll,
    required this.allLabel,
  });

  final List<int> years;
  final Set<int> selected;
  final ValueChanged<int> onToggle;
  final VoidCallback onClearAll;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    // Cas dégénéré : une seule année → aucun sens d'afficher un filtre
    // (« Toutes » + 1 chip redondants).
    if (years.length <= 1) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PillChip(
            label: allLabel,
            selected: selected.isEmpty,
            onTap: onClearAll,
          ),
          for (final year in years) ...[
            SizedBox(width: AppSpacing.s2.w),
            _PillChip(
              label: '$year',
              selected: selected.contains(year),
              onTap: () => onToggle(year),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip pill réutilisable pour les filtres inline (année + toutes).
class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : AppColors.card;
    final borderColor = selected ? AppColors.primary : AppColors.border;
    final textColor = selected ? Colors.white : AppColors.ink;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s3.w,
            vertical: AppSpacing.s1.h + 2,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: borderColor, width: AppBorderWidth.hairline),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppTypography.bodyStrong.copyWith(
              fontSize: AppFontSize.bodySmall,
              color: textColor,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SchoolFilterButton extends StatelessWidget {
  const _SchoolFilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? AppColors.primarySoft : AppColors.card;
    final borderColor = isActive ? AppColors.primary : AppColors.border;
    final textColor = isActive ? AppColors.primary : AppColors.ink;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor, width: AppBorderWidth.hairline),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zone principale — ouvre le picker.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.pill),
                bottomLeft: Radius.circular(AppRadius.pill),
                topRight: onClear == null
                    ? Radius.circular(AppRadius.pill)
                    : Radius.zero,
                bottomRight: onClear == null
                    ? Radius.circular(AppRadius.pill)
                    : Radius.zero,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3.w,
                  vertical: AppSpacing.s2.h,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.school,
                      size: AppIconSize.md,
                      color: textColor,
                    ),
                    SizedBox(width: AppSpacing.s2.w),
                    Flexible(
                      child: Text(
                        label,
                        style: AppTypography.bodyStrong.copyWith(
                          fontSize: AppFontSize.bodySmall,
                          color: textColor,
                          fontWeight:
                              isActive ? FontWeight.w800 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onClear == null) ...[
                      SizedBox(width: AppSpacing.s1.w),
                      Icon(
                        LucideIcons.chevronDown,
                        size: AppIconSize.md,
                        color: textColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Zone clear — cible tap distincte et visible.
          if (onClear != null)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: borderColor.withValues(alpha: 0.5),
                    width: AppBorderWidth.hairline,
                  ),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onClear,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(AppRadius.pill),
                    bottomRight: Radius.circular(AppRadius.pill),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.s3.w,
                      vertical: AppSpacing.s2.h,
                    ),
                    child: Icon(
                      LucideIcons.x,
                      size: AppIconSize.md,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResetFiltersButton extends StatelessWidget {
  const _ResetFiltersButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(LucideIcons.rotateCcw,
          size: AppIconSize.md, color: AppColors.muted),
      label: Text(
        AppLocalizations.of(context).examSujetsResetFilters,
        style: AppTypography.bodyStrong.copyWith(
          color: AppColors.muted,
          fontSize: AppFontSize.bodySmall,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s2.w),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.eyebrow,
    required this.subjectName,
    required this.subjectIcon,
    required this.summary,
    required this.progress,
    required this.onBack,
  });

  final String eyebrow;
  final String subjectName;
  final IconData subjectIcon;
  final String summary;
  final double progress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s2.w,
            AppSpacing.s1.h,
            AppSpacing.s4.w,
            AppSpacing.s4.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.s2.w),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.card,
                        size: AppIconSize.xl,
                      ),
                    ),
                  ),
                  Container(
                    width: AppSpacing.s10.w,
                    height: AppSpacing.s10.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      subjectIcon,
                      color: AppColors.card,
                      size: AppIconSize.xl2,
                    ),
                  ),
                  SizedBox(width: AppSpacing.s3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          eyebrow,
                          style: AppTypography.eyebrow.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w700,
                            fontSize: AppFontSize.eyebrow,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          subjectName,
                          style: AppTypography.h2.copyWith(
                            fontSize: AppFontSize.h3,
                            fontWeight: FontWeight.w900,
                            color: AppColors.card,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s3.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.warning,
                  ),
                  minHeight: AppDimension.progressBarMed,
                ),
              ),
              SizedBox(height: AppSpacing.s1.h + 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  summary,
                  textAlign: TextAlign.right,
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: AppFontSize.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.bookOpen,
              size: AppIconSize.xl9,
              color: AppColors.muted,
            ),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              label,
              style: AppTypography.body.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
