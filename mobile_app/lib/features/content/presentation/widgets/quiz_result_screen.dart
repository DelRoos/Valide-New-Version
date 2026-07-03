import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.isFr,
    required this.onReplay,
    required this.onBack,
    required this.onReview,
  });

  final int score;
  final int total;
  final bool isFr;
  final VoidCallback onReplay;
  final VoidCallback onBack;
  final VoidCallback onReview;

  /// Couleur de fond pour le score donné — utilisée aussi par le Scaffold parent.
  static Color bgFor(int pct) {
    if (pct >= 80) return AppColors.successSoft;
    if (pct >= 60) return AppColors.primarySoft;
    if (pct >= 40) return AppColors.warningSoft;
    return AppColors.dangerSoft;
  }

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final (Color accent, Color accentSoft, Color accentInk, IconData icon, String headline) =
        switch (pct) {
      >= 80 => (
          AppColors.success,
          AppColors.successSoft,
          AppColors.successInk,
          Icons.emoji_events_rounded,
          isFr ? 'Excellent !' : 'Excellent!',
        ),
      >= 60 => (
          AppColors.primary,
          AppColors.primarySoft,
          AppColors.primary,
          Icons.school_rounded,
          isFr ? 'Bon travail !' : 'Good job!',
        ),
      >= 40 => (
          AppColors.warning,
          AppColors.warningSoft,
          AppColors.warningInk,
          Icons.menu_book_rounded,
          isFr ? 'Continue d\'étudier' : 'Keep studying',
        ),
      _ => (
          AppColors.danger,
          AppColors.dangerSoft,
          AppColors.dangerInk,
          Icons.refresh_rounded,
          isFr ? 'Revois le cours !' : 'Review the lesson!',
        ),
    };

    return ColoredBox(
      color: accentSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Score centré ────────────────────────────────────────────
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.s6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: AppSpacing.s16,
                      height: AppSpacing.s16,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: AppIconSize.xl6, color: accent),
                    ),
                    SizedBox(height: AppSpacing.s4),
                    Text(
                      headline,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.h2,
                        fontWeight: FontWeight.w800,
                        color: accentInk,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.s5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: AppFontSize.display,
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                        ),
                        Text(
                          ' / $total',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: AppFontSize.h2,
                            fontWeight: FontWeight.w600,
                            color: accentInk.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.s2),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.s3,
                        vertical: AppSpacing.s1,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        isFr ? '$pct% de réponses correctes' : '$pct% correct',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: AppFontSize.bodySmall,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── CTAs fixes en bas ───────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s2,
              AppSpacing.s4,
              AppSpacing.s4 + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: onReview,
                  icon: Icon(
                    Icons.list_alt_rounded,
                    size: AppIconSize.md,
                    color: accentInk,
                  ),
                  label: Text(
                    isFr ? 'Voir mes réponses' : 'Review answers',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w600,
                      color: accentInk,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, AppSpacing.s12),
                    side: BorderSide(
                      color: accent.withValues(alpha: 0.4),
                      width: AppBorderWidth.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.s3),
                ElevatedButton(
                  onPressed: onReplay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    minimumSize: Size(double.infinity, AppSpacing.s12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isFr ? 'Rejouer' : 'Play again',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.s1),
                TextButton(
                  onPressed: onBack,
                  style: TextButton.styleFrom(
                    minimumSize: Size(double.infinity, AppSpacing.s10),
                  ),
                  child: Text(
                    isFr ? 'Retour au cours' : 'Back to lesson',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w500,
                      color: accentInk.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
