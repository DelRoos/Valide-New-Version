import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/catalogue/domain/models.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import 'stream_picker_chips.dart';
import 'stream_picker_recap.dart';

/// Picker interactif pour les modes opt_out / free_with_obligatory /
/// series_plus_optional. Affiche matières obligatoires (verrouillées) et
/// matières optionnelles (bascule). CTA actif quand min ≤ total ≤ max.
class InteractiveSubjectPicker extends StatelessWidget {
  const InteractiveSubjectPicker({
    super.key,
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
                  RecapBanner(entries: recapEntries),
                  SizedBox(height: AppSpacing.s4.h),
                ],
                // Compteur + choix optionnels (action principale).
                SubjectCounterBadge(
                  total: totalSelected,
                  min: min,
                  max: max,
                ),
                if (optionalSubjects.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.s3.h),
                  SectionLabel(
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
                        ToggleChip(
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
                // Matières obligatoires en bas (lecture seule).
                if (obligatorySubjects.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.s4.h),
                  SectionLabel(
                    label: l10n.onboardingPickerObligatoryTitle,
                  ),
                  SizedBox(height: AppSpacing.s2.h),
                  Wrap(
                    spacing: AppSpacing.s2.w,
                    runSpacing: AppSpacing.s2.h,
                    children: [
                      for (final s in obligatorySubjects)
                        SubjectSummaryChip(
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
