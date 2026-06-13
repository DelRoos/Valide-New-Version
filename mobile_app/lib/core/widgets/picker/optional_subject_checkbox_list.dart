// Liste de matieres optionnelles (interactives) reutilisable.
// Extraite du pattern repete 4x dans subjects_picker_page.dart lors de la
// Story 1.18 :
//   - Story 1.4 (legacy opt-out, James : optedOut inverse)
//   - Story 1.15 (Mariam : panier O-Level)
//   - Story 1.16 (James : transversales A-Level)
//   - Story 1.17 (Eyong : Other au choix TVE)
//
// Pattern : ListView.separated(shrinkWrap, NeverScrollable) avec
// CheckboxListTile(value: picked.contains(subjectId), secondary: Icon
// subjectIconFor(s.icon), onChanged: onToggle(subjectId, selected)).
//
// Le subjectIconFor reste un helper specifique a la feature onboarding :
// pour eviter une dependance core -> feature, l'appelant fournit un
// resolver `iconResolver` au composant.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../catalogue/domain/models.dart';
import '../../theme/tokens.dart';

class OptionalSubjectCheckboxList extends StatelessWidget {
  const OptionalSubjectCheckboxList({
    super.key,
    required this.subjects,
    required this.picked,
    required this.onToggle,
    required this.langKey,
    required this.isSaving,
    required this.iconResolver,
    this.shrinkWrap = true,
  });

  /// Matieres a afficher comme optionnelles (interactives).
  final List<Subject> subjects;

  /// Ensemble des subjectIds actuellement coches.
  final Set<String> picked;

  /// Callback declenche quand l'utilisateur change l'etat d'une checkbox.
  /// `selected` = true si l'utilisateur a coche.
  final void Function(String subjectId, bool selected) onToggle;

  /// Langue d'affichage ("fr" ou "en"). Fallback fr puis subjectId si manquant.
  final String langKey;

  /// Si true, onChanged est null (CheckboxListTile disable).
  final bool isSaving;

  /// Resolver d'icone par nom Lucide (cf. _subject_icons.dart cote feature
  /// onboarding). Injecte pour eviter une dependance core -> feature.
  final IconData Function(String iconName) iconResolver;

  /// Si true (defaut), la liste calcule sa propre hauteur et delegue le scroll
  /// au parent (utile quand le composant est imbrique dans un ListView externe,
  /// pattern picker 1.15/1.16/1.17). Si false, la liste prend toute la hauteur
  /// disponible et scroll elle-meme (pattern legacy opt-out 1.4 ou wrap dans
  /// un Expanded direct).
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics:
          shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: subjects.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.s2.h),
      itemBuilder: (context, index) {
        final s = subjects[index];
        final selected = picked.contains(s.subjectId);
        final abbr = s.abbreviationFor(langKey);
        return CheckboxListTile(
          value: selected,
          onChanged: isSaving
              ? null
              : (v) => onToggle(s.subjectId, v ?? false),
          secondary: Icon(
            iconResolver(s.icon),
            color: AppColors.primary,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  s.name[langKey] ?? s.name['fr'] ?? s.subjectId,
                  style: AppTypography.bodyStrong,
                ),
              ),
              if (abbr != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.s2.w,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    abbr,
                    style: AppTypography.caption.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primary,
        );
      },
    );
  }
}
