import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';

enum PerformanceLevel { good, medium, weak }

extension PerformanceLevelX on PerformanceLevel {
  Color get color => switch (this) {
        PerformanceLevel.good => AppColors.success,
        PerformanceLevel.medium => AppColors.warning,
        PerformanceLevel.weak => AppColors.danger,
      };

  Color get softBg => switch (this) {
        PerformanceLevel.good => AppColors.successSoft,
        PerformanceLevel.medium => AppColors.warningSoft,
        PerformanceLevel.weak => AppColors.dangerSoft,
      };

  Color get inkColor => switch (this) {
        PerformanceLevel.good => AppColors.successInk,
        PerformanceLevel.medium => AppColors.warningInk,
        PerformanceLevel.weak => AppColors.dangerInk,
      };

  String label(AppLocalizations l10n) => switch (this) {
        PerformanceLevel.good => l10n.performanceLevelGood,
        PerformanceLevel.medium => l10n.performanceLevelMedium,
        PerformanceLevel.weak => l10n.performanceLevelWeak,
      };
}

// Seuils : >= 70 bon, 40-69 moyen, < 40 faible. Mock — sera basé sur
// avgQuizScore réel en Story 2.x.
PerformanceLevel performanceLevelFromScore(int score) {
  if (score >= 70) return PerformanceLevel.good;
  if (score >= 40) return PerformanceLevel.medium;
  return PerformanceLevel.weak;
}
