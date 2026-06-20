import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/catalogue/domain/models.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/picker/subject_icon_resolver.dart';
import '../../../../../l10n/generated/app_localizations.dart';

/// Badge affichant le nombre de matières sélectionnées vs la plage min-max.
/// Vert si la sélection est valide (>= min), orange sinon.
class SubjectCounterBadge extends StatelessWidget {
  const SubjectCounterBadge({
    super.key,
    required this.total,
    required this.min,
    required this.max,
  });

  final int total;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final valid = total >= min;
    final color = valid ? AppColors.success : AppColors.warning;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3.w,
        vertical: AppSpacing.s2.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            valid ? LucideIcons.checkCircle : LucideIcons.circle,
            color: color,
            size: 14.sp,
          ),
          SizedBox(width: AppSpacing.s2.w),
          Text(
            l10n.onboardingPickerCounter(total, max),
            style: AppTypography.bodyStrong.copyWith(
              fontSize: 13.sp,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// En-tête de section avec label obligatoire et hint optionnel.
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.label, this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.bodyStrong.copyWith(
            fontSize: 13.sp,
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        if (hint != null) ...[
          SizedBox(width: AppSpacing.s2.w),
          Text(
            '· $hint',
            style: AppTypography.body.copyWith(
              fontSize: 12.sp,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ],
    );
  }
}

/// Chip à bascule pour une matière optionnelle. Plein = sélectionnée.
/// Désactivée (grisée, non tappable) quand le max est atteint et qu'elle
/// n'est pas déjà sélectionnée.
class ToggleChip extends StatelessWidget {
  const ToggleChip({
    super.key,
    required this.subject,
    required this.langKey,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Subject subject;
  final String langKey;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name =
        subject.name[langKey] ?? subject.name['fr'] ?? subject.subjectId;
    final color = selected ? AppColors.primary : AppColors.inkSoft;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s3.w,
            vertical: AppSpacing.s2.h,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? LucideIcons.checkCircle : LucideIcons.plusCircle,
                color: color,
                size: 14.sp,
              ),
              SizedBox(width: AppSpacing.s2.w),
              Text(
                name,
                style: AppTypography.bodyStrong.copyWith(
                  fontSize: 13.sp,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip affichant une matiere dans les sections "lecture seule" (derived,
/// obligatoire non-toggleable). [isObligatory] ajoute un * rouge pour
/// distinguer les matieres qui ne peuvent pas etre deselectionnes.
class SubjectSummaryChip extends StatelessWidget {
  const SubjectSummaryChip({
    super.key,
    required this.subject,
    required this.langKey,
    this.isObligatory = false,
  });

  final Subject subject;
  final String langKey;
  final bool isObligatory;

  @override
  Widget build(BuildContext context) {
    final name =
        subject.name[langKey] ?? subject.name['fr'] ?? subject.subjectId;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s3.w,
        vertical: AppSpacing.s2.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            subjectIconFor(subject.icon),
            color: AppColors.primary,
            size: 16.sp,
          ),
          SizedBox(width: AppSpacing.s2.w),
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTypography.bodyStrong.copyWith(
                fontSize: 13.sp,
                color: AppColors.primary,
              ),
            ),
          ),
          if (isObligatory) ...[
            SizedBox(width: 2.w),
            Text(
              '*',
              style: AppTypography.bodyStrong.copyWith(
                fontSize: 13.sp,
                color: AppColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
