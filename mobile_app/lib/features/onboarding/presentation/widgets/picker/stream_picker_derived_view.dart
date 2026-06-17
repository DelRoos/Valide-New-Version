import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/catalogue/domain/models.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import 'stream_picker_chips.dart';
import 'stream_picker_recap.dart';

/// Résout la clé de groupe Firestore ('lv2', 'lv3'...) vers son libellé
/// localisé pour l'en-tête de section inline.
String _resolveGroupLabel(AppLocalizations l10n, String groupKey) {
  return switch (groupKey) {
    'lv2' => l10n.onboardingGroupLv2,
    'lv3' => l10n.onboardingGroupLv3,
    'olevel_options' => l10n.onboardingGroupOlevelOptions,
    'alevel_options' => l10n.onboardingGroupAlevelOptions,
    _ => l10n.onboardingGroupGeneric,
  };
}

/// Preview read-only des matieres pour les modes `derived` et `tvePicker`.
/// L'utilisateur ne peut pas modifier ; il peut choisir des variantes de
/// groupes (LV2/LV3) affichées directement inline sans bottomsheet.
class DerivedPreview extends StatelessWidget {
  const DerivedPreview({
    super.key,
    required this.recapEntries,
    required this.ungroupedSubjects,
    required this.groups,
    required this.picksByGroup,
    required this.langKey,
    required this.validateLabel,
    required this.isValid,
    required this.isLoading,
    required this.onGroupPick,
    required this.onValidate,
  });

  final List<({String label, String value, IconData icon})> recapEntries;
  final List<Subject> ungroupedSubjects;
  final Map<String, List<Subject>> groups;
  final Map<String, String> picksByGroup;
  final String langKey;
  final String validateLabel;
  final bool isValid;
  final bool isLoading;
  final void Function(String groupKey, String? subjectId) onGroupPick;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            // s2.w (8dp) : respire pour Transform.scale(1.01) + BoxShadow
            // des SelectionCards sans doubler le s5.w du PickerSectionScaffold.
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.s2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.s3.h),
                // Récap EN PREMIER — contexte immédiat avant de voir les choix.
                if (recapEntries.isNotEmpty) ...[
                  RecapBanner(entries: recapEntries),
                  SizedBox(height: AppSpacing.s4.h),
                ],
                // Choix interactifs (groupes LV2/LV3) ensuite.
                for (final entry in groups.entries) ...[
                  SectionLabel(
                    label: _resolveGroupLabel(l10n, entry.key),
                    hint: l10n.onboardingGroupPickHint,
                  ),
                  SizedBox(height: AppSpacing.s2.h),
                  Wrap(
                    spacing: AppSpacing.s2.w,
                    runSpacing: AppSpacing.s2.h,
                    children: [
                      for (final variant in entry.value)
                        ToggleChip(
                          subject: variant,
                          langKey: langKey,
                          selected:
                              picksByGroup[entry.key] == variant.subjectId,
                          enabled: true,
                          onTap: () => onGroupPick(
                            entry.key,
                            picksByGroup[entry.key] == variant.subjectId
                                ? null
                                : variant.subjectId,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s4.h),
                ],
                // Autres matières (lecture seule) en bas.
                if (ungroupedSubjects.isNotEmpty)
                  Wrap(
                    spacing: AppSpacing.s2.w,
                    runSpacing: AppSpacing.s2.h,
                    children: [
                      for (final subject in ungroupedSubjects)
                        SubjectSummaryChip(
                          subject: subject,
                          langKey: langKey,
                        ),
                    ],
                  ),
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
