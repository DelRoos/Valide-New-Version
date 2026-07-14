import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/cards/performance_level.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'exam_stats_row.dart';

// Dimensions du preview façon « mini feuille de sujet ».
const double _kPreviewWidth = 56;
const double _kPreviewHeight = 72;
const double _kPreviewHeaderStripHeight = 10;

// Couleur PDF-like — utilisée quand le sujet est une épreuve officielle
// (BEPC blanc, BAC blanc, annale MINESEC).
const Color _kPdfRed = Color(0xFFDC2626);

/// Card sujet (ancien examen) sur la page « Sujets · Matière · Séq N ».
///
/// Layout façon « past papers app » : badge preview (icône document + année)
/// à gauche, titre du sujet + source (établissement / session) au centre,
/// niveau perf + progression exos.
class ExamSujetCard extends StatelessWidget {
  const ExamSujetCard({
    super.key,
    required this.title,
    required this.year,
    required this.exosDone,
    required this.exosTotal,
    required this.level,
    required this.onTap,
    required this.participants,
    required this.avgScore,
    required this.maxScore,
    required this.minScore,
    this.source,
    this.isExam = false,
  });

  final String title;
  final int year;
  final int exosDone;
  final int exosTotal;
  final PerformanceLevel level;

  /// Établissement / session d'origine du sujet, si connu.
  /// Ex : « Lycée Général Leclerc », « MINESEC · Session juin ».
  final String? source;

  /// `true` = sujet est une épreuve officielle (BEPC blanc, BAC blanc, annale
  /// MINESEC). Rend le preview façon PDF rouge avec un tampon « EXAMEN »
  /// au centre.
  final bool isExam;

  // Stats communauté (agrégat calculé côté Firestore en Story 2.x, mock
  // aujourd'hui). Notes sur /20 (échelle scolaire camerounaise).
  final int participants;
  final double avgScore;
  final double maxScore;
  final double minScore;

  final VoidCallback onTap;

  bool get _isNew => exosDone == 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final barColor = _isNew ? AppColors.primary : level.color;
    final progress = exosTotal == 0 ? 0.0 : exosDone / exosTotal;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.mid,
      ),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.s3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _PaperPreview(year: year, isExam: isExam),
                    SizedBox(width: AppSpacing.s3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: AppTypography.bodyStrong.copyWith(
                                    fontSize: AppFontSize.bodySmall,
                                    color: AppColors.ink,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: AppSpacing.s2.w),
                              if (_isNew)
                                _NewChip(label: l10n.examSujetCardMetaNew)
                              else
                                _LevelDot(color: level.color),
                            ],
                          ),
                          if (source != null && source!.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              source!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.muted,
                                fontSize: AppFontSize.caption,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          SizedBox(height: AppSpacing.s2.h),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  barColor.withValues(alpha: 0.12),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(barColor),
                              minHeight: AppDimension.progressBarMed,
                            ),
                          ),
                          SizedBox(height: AppSpacing.s1.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.users,
                                    size: AppIconSize.sm,
                                    color: AppColors.muted,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    l10n.examSujetCardParticipantsCount(
                                        participants),
                                    style: AppTypography.eyebrow.copyWith(
                                      color: AppColors.muted,
                                      fontSize: AppFontSize.eyebrow,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                l10n.examsExercisesOf(exosDone, exosTotal),
                                style: AppTypography.eyebrow.copyWith(
                                  color: AppColors.muted,
                                  fontSize: AppFontSize.eyebrow,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.s2.w),
                    Icon(
                      LucideIcons.chevronRight,
                      size: AppIconSize.md,
                      color: AppColors.muted,
                    ),
                  ],
                ),
                // Ligne stats — n'affiche pas la Row 0/20 · 0/20 · 0/20 quand
                // aucun participant n'a traité le sujet (contradiction avec
                // le message « Aucun participant » de la ligne au-dessus).
                if (participants > 0) ...[
                  SizedBox(height: AppSpacing.s3.h),
                  Container(
                    padding: EdgeInsets.only(top: AppSpacing.s2.h),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.border,
                          width: AppBorderWidth.hairline,
                        ),
                      ),
                    ),
                    child: ExamStatsRow(
                      avgScore: avgScore,
                      maxScore: maxScore,
                      minScore: minScore,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Preview façon « mini feuille de sujet ».
///
/// - `isExam == false` (défaut) : silhouette gris/blanc neutre pour les devoirs
///   d'école, contrôles, compositions internes.
/// - `isExam == true` : silhouette rouge façon PDF avec tampon « EXAMEN »
///   au centre. Réservé aux épreuves officielles (BEPC blanc, BAC blanc,
///   annales MINESEC).
class _PaperPreview extends StatelessWidget {
  const _PaperPreview({required this.year, required this.isExam});

  final int year;
  final bool isExam;

  @override
  Widget build(BuildContext context) {
    final borderColor = isExam ? _kPdfRed : AppColors.border;
    final stripColor = isExam
        ? _kPdfRed
        : AppColors.mute2.withValues(alpha: 0.55);
    final badgeBg = isExam ? _kPdfRed.withValues(alpha: 0.12) : AppColors.bg;
    final badgeText = isExam ? _kPdfRed : AppColors.muted;

    return Container(
      width: _kPreviewWidth.w,
      height: _kPreviewHeight.h,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: borderColor, width: AppBorderWidth.hairline),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        // Compense l'épaisseur de la bordure externe pour éviter l'artefact
        // visuel 0.5 dp sur le header rouge du preview.
        borderRadius:
            BorderRadius.circular(AppRadius.sm - AppBorderWidth.hairline),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: _kPreviewHeaderStripHeight.h,
                  color: stripColor,
                ),
                SizedBox(height: AppSpacing.s1.h + 2),
                _TextLine(width: 32.w),
                SizedBox(height: 3.h),
                _TextLine(width: 40.w),
                SizedBox(height: 3.h),
                _TextLine(width: 26.w),
                SizedBox(height: 3.h),
                _TextLine(width: 36.w),
              ],
            ),
            if (isExam)
              Positioned.fill(
                top: _kPreviewHeaderStripHeight.h,
                child: Center(
                  child: Transform.rotate(
                    angle: -0.18, // ~-10 degrés — feel « tampon »
                    child: Text(
                      AppLocalizations.of(context).examSujetCardExamLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.eyebrow.copyWith(
                        color: _kPdfRed,
                        fontWeight: FontWeight.w900,
                        fontSize: AppFontSize.tiny,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 3.w,
              bottom: 3.h,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.h,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  // Format « 'YY » pour les années >= 100. Fallback affichage
                  // complet pour les valeurs anormales (mocks/deep link).
                  year >= 100 ? "'${year % 100}" : "'$year",
                  style: AppTypography.eyebrow.copyWith(
                    color: badgeText,
                    fontWeight: FontWeight.w900,
                    fontSize: AppFontSize.tiny,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini-ligne grise qui simule une ligne de texte dans le preview du sujet.
class _TextLine extends StatelessWidget {
  const _TextLine({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s1.w + 2),
      child: Container(
        width: width,
        height: 2.h,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
    );
  }
}

class _LevelDot extends StatelessWidget {
  const _LevelDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _NewChip extends StatelessWidget {
  const _NewChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s2.w,
        vertical: 3.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.eyebrow.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: AppFontSize.tiny,
        ),
      ),
    );
  }
}


