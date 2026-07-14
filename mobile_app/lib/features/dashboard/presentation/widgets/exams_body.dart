import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'exams_countdown_banner.dart';
import 'exams_folder_card.dart';
import 'exams_matiere_picker_sheet.dart';

// Hauteur nominale du banner countdown existant (pour dimensionner le
// skeleton en conservant le layout à l'identique pendant le chargement).
const double _kBannerH = 180;
// Hauteur d'une card folder — mesurée à l'œil pour matcher exactement le
// rendu produit après build (titre + progress bar + padding s4).
const double _kFolderSkeletonH = 96;

// Mock — sera remplacé par un provider Firestore côté séquence pédagogique
// courante + config exam target de l'utilisateur en Story 2.x.
const int _kSequencesPerYear = 6;
const int _kMockCurrentSequence = 1;
const bool _kMockShowExamFolder = true; // vraie logique : levelId ∈ classes d'examen

// Mock progression par séquence : (done, total) — sera calculé depuis
// Firestore (compte sujets par séquence × avancement user).
// Invariant : chaque liste doit contenir exactement kSequencesPerYear entrées.
const List<int> _kMockSujetsTotal = [18, 24, 15, 20, 22, 16];
const List<int> _kMockSujetsDone = [12, 8, 3, 15, 0, 5];
const int _kMockAnnalesTotal = 12;
const int _kMockAnnalesDone = 4;

// Palette pour les folders séquences (teintes distinctes, sans conflit
// sémantique avec les niveaux perf). Les 2 premières couleurs reprennent
// des tokens AppColors existants pour éviter la duplication.
const List<Color> _kFolderPalette = [
  AppColors.primary, // bleu — séquence courante par défaut
  Color(0xFF8B5CF6), // violet
  AppColors.sky,     // sky
  Color(0xFFF97316), // orange
  Color(0xFF10B981), // émeraude
  Color(0xFF6366F1), // indigo
];

// ── Body ─────────────────────────────────────────────────────────────────────

class ExamsBody extends StatelessWidget {
  const ExamsBody({super.key, required this.subjects});

  final List<Subject> subjects;

  @override
  Widget build(BuildContext context) {
    // Invariants — évite un RangeError silencieux si les mocks divergent
    // à la maintenance. Retire les asserts quand Firestore est branché.
    assert(_kMockSujetsTotal.length == _kSequencesPerYear,
        '_kMockSujetsTotal doit contenir $_kSequencesPerYear entrées (1 par séquence).');
    assert(_kMockSujetsDone.length == _kSequencesPerYear,
        '_kMockSujetsDone doit contenir $_kSequencesPerYear entrées (1 par séquence).');

    final l10n = AppLocalizations.of(context);
    final langKey = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: AppSpacing.s2.h,
        bottom: AppSpacing.s8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4.w),
            child: ExamsCountdownBanner(l10n: l10n),
          ),
          SizedBox(height: AppSpacing.s5.h),

          // 6 folders séquences.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4.w),
            child: Column(
              children: List.generate(_kSequencesPerYear, (i) {
                final seqNumber = i + 1;
                final isCurrent = i == (_kMockCurrentSequence - 1);
                final color = _kFolderPalette[i % _kFolderPalette.length];
                final total = _kMockSujetsTotal[i];
                final done = _kMockSujetsDone[i].clamp(0, total);
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.s3.h),
                  child: ExamsFolderCard(
                    title: l10n.examsFolderSequenceTitle(seqNumber),
                    progressLabel: l10n.examsFolderSujetsOf(done, total),
                    progressValue: total == 0 ? 0 : done / total,
                    leading: Text(
                      'S$seqNumber',
                      style: AppTypography.bodyStrong.copyWith(
                        color: color,
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    leadingColor: color,
                    currentChipLabel:
                        isCurrent ? l10n.examsFolderSequenceCurrent : null,
                    onTap: () {
                      if (subjects.isEmpty) return;
                      showExamsMatierePickerSheet(
                        context: context,
                        sequenceNumber: seqNumber,
                        subjects: subjects,
                        langKey: langKey,
                      );
                    },
                  ),
                );
              }),
            ),
          ),

          // Folder « Sujets d'examen » — pour les classes d'examen (3e/Tle/GCE).
          if (_kMockShowExamFolder) ...[
            SizedBox(height: AppSpacing.s3.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4.w),
              child: Text(
                l10n.examsFolderExamSectionTitle,
                style: AppTypography.h3.copyWith(fontSize: AppFontSize.h3),
              ),
            ),
            SizedBox(height: AppSpacing.s3.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4.w),
              child: ExamsFolderCard(
                title: l10n.examsFolderExamTitle,
                progressLabel: l10n.examsFolderAnnalesOf(
                  _kMockAnnalesDone,
                  _kMockAnnalesTotal,
                ),
                progressValue: _kMockAnnalesTotal == 0
                    ? 0
                    : _kMockAnnalesDone / _kMockAnnalesTotal,
                leading: Icon(
                  LucideIcons.graduationCap,
                  size: AppIconSize.xl2,
                  color: AppColors.warning,
                ),
                leadingColor: AppColors.warning,
                onTap: () {
                  if (subjects.isEmpty) return;
                  // Sentinel « Annales officielles » — la page reçoit ce
                  // sequenceNumber et bascule en mode annales.
                  showExamsMatierePickerSheet(
                    context: context,
                    sequenceNumber: AppRoutes.examSujetsAnnalesSequence,
                    subjects: subjects,
                    langKey: langKey,
                    eyebrowLabel: l10n.examsFolderExamTitle,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class ExamsSkeleton extends StatelessWidget {
  const ExamsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s4.w, AppSpacing.s2.h, AppSpacing.s4.w, AppSpacing.s8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBlock(height: _kBannerH.h, radius: AppRadius.xl),
          SizedBox(height: AppSpacing.s5.h),
          ...List.generate(6, (i) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s3.h),
            child: _shimmerBlock(
              height: _kFolderSkeletonH.h,
              radius: AppRadius.lg,
              color: AppColors.card,
            ),
          )),
        ],
      ),
    );
  }

  Widget _shimmerBlock({
    double? width,
    required double height,
    required double radius,
    Color color = AppColors.border,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: AppColors.bg);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class ExamsEmpty extends StatelessWidget {
  const ExamsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bookMarked,
                size: AppIconSize.xl9, color: AppColors.muted),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              AppLocalizations.of(context).dashboardEmptyStateText,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
