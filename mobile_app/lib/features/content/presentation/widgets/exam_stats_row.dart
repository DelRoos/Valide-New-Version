import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Ligne stats communauté sous une [ExamSujetCard] : 3 blocs égaux
/// (pire / moyenne / meilleure) séparés par des dividers verticaux.
///
/// Notes formatées /20 (échelle scolaire camerounaise) via la clé ARB
/// `examSujetCardScoreOver20`. Clamp [0..20] + guard NaN sur toute valeur
/// entrante — le widget est robuste contre les données Firestore corrompues.
class ExamStatsRow extends StatelessWidget {
  const ExamStatsRow({
    super.key,
    required this.avgScore,
    required this.maxScore,
    required this.minScore,
  });

  final double avgScore;
  final double maxScore;
  final double minScore;

  /// Retourne la valeur numérique formatée (« N » ou « N.d »), sans le
  /// suffixe « /20 » qui vient de l'ARB au moment du rendu.
  /// Guard `isFinite` + clamp [0..20] pour résister aux données corrompues.
  static String _formatScoreValue(double s) {
    if (!s.isFinite) return '0';
    final clamped = s.clamp(0.0, 20.0);
    return clamped == clamped.roundToDouble()
        ? clamped.toStringAsFixed(0)
        : clamped.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String formatScore(double s) =>
        l10n.examSujetCardScoreOver20(_formatScoreValue(s));
    // stretch obligatoire — sans ça les _VerticalDivider (Container width:1
    // sans height) sont collapsed à height 0 par un Row default (center),
    // et deviennent invisibles à l'écran.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: _StatLabel(
                label: l10n.examSujetCardMinLabel,
                value: formatScore(minScore),
                color: AppColors.danger,
              ),
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: Center(
              child: _StatLabel(
                label: l10n.examSujetCardAvgLabel,
                value: formatScore(avgScore),
              ),
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: Center(
              child: _StatLabel(
                label: l10n.examSujetCardMaxLabel,
                value: formatScore(maxScore),
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre verticale hairline entre 2 blocs stats.
class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppBorderWidth.hairline,
      color: AppColors.border,
    );
  }
}

/// Stat au format « label 13.5/20 » : label muted discret + valeur bold
/// (colorée pour max/min, ink pour la moyenne). Rend la sémantique sans
/// icône. `Flexible` + `maxLines: 1` + `ellipsis` protègent contre
/// l'overflow sur écrans étroits avec labels FR longs.
class _StatLabel extends StatelessWidget {
  const _StatLabel({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Label toujours muted — la couleur ne s'applique qu'à la valeur pour
    // préserver la hiérarchie label neutre + valeur colorée.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTypography.eyebrow.copyWith(
              color: AppColors.muted,
              fontSize: AppFontSize.tiny,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyStrong.copyWith(
              color: color ?? AppColors.ink,
              fontSize: AppFontSize.bodySmall,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
