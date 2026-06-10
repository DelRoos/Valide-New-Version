// Liste de matieres obligatoires (verrouillees + cadenas) reutilisable.
// Extraite du pattern repete 3x dans subjects_picker_page.dart (Stories 1.15,
// 1.16, 1.17 + sous-sections du mode TVE 1.17) lors de la Story 1.18.
//
// Pattern : ListView.separated(shrinkWrap, NeverScrollable) avec
// CheckboxListTile(value: true, secondary: Icon LucideIcons.lock,
// onChanged: tap declenche onTapBlocked -> typiquement toast warning).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../catalogue/domain/models.dart';
import '../../theme/tokens.dart';

class ObligatorySubjectCheckboxList extends StatelessWidget {
  const ObligatorySubjectCheckboxList({
    super.key,
    required this.subjects,
    required this.langKey,
    required this.isSaving,
    required this.onTapBlocked,
  });

  /// Matieres a afficher comme obligatoires (verrouillees + cadenas).
  final List<Subject> subjects;

  /// Langue d'affichage ("fr" ou "en"). Fallback fr puis subjectId si manquant.
  final String langKey;

  /// Si true, onChanged est null (CheckboxListTile disable).
  final bool isSaving;

  /// Callback appele quand l'utilisateur tap (tentative de decocher) une
  /// matiere obligatoire. Typiquement : toast warning + log warn.
  final void Function(String subjectId) onTapBlocked;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.s2.h),
      itemBuilder: (context, index) {
        final s = subjects[index];
        return CheckboxListTile(
          value: true,
          onChanged: isSaving ? null : (_) => onTapBlocked(s.subjectId),
          secondary: Icon(
            LucideIcons.lock,
            color: AppColors.primary,
            size: 18.sp,
          ),
          title: Text(
            s.name[langKey] ?? s.name['fr'] ?? s.subjectId,
            style: AppTypography.bodyStrong,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primary,
        );
      },
    );
  }
}
