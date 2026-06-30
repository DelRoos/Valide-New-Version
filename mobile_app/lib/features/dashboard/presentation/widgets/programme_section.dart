import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Fake data — section programme uniquement
// ---------------------------------------------------------------------------

const _kSequenceLabel = 'Séq. 3-4';
const _kGlobalCoverage = 0.52;

class _Subject {
  const _Subject(this.name, this.icon, this.coverage, this.color);
  final String name;
  final IconData icon;
  final double coverage;
  final Color color;
}

const _kSubjects = [
  _Subject('Mathématiques', LucideIcons.calculator, 0.72, Color(0xFF2563EB)),
  _Subject('Physique-Chimie', LucideIcons.atom, 0.45, Color(0xFF7C3AED)),
  _Subject('SVT', LucideIcons.leaf, 0.30, Color(0xFF059669)),
  _Subject('Philosophie', LucideIcons.bookMarked, 0.68, Color(0xFFD97706)),
  _Subject('Français', LucideIcons.penLine, 0.55, Color(0xFFDC2626)),
];

// ---------------------------------------------------------------------------
// Section programme
// ---------------------------------------------------------------------------

class ProgrammeSection extends StatelessWidget {
  const ProgrammeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final pct = (_kGlobalCoverage * 100).round();
    final isLow = _kGlobalCoverage < 0.40;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mon programme · $_kSequenceLabel',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppFontSize.h3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.h3,
                fontWeight: FontWeight.w800,
                color: isLow ? AppColors.danger : AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.s3.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: _kGlobalCoverage,
            minHeight: 8.h,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(
              isLow ? AppColors.danger : AppColors.primary,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.s1.h),
        Text(
          isLow
              ? 'Programme peu couvert — intensifie les révisions'
              : 'Tu avances bien sur cette séquence',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppFontSize.caption,
            color: isLow ? AppColors.danger : AppColors.muted,
          ),
        ),
        SizedBox(height: AppSpacing.s4.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppElevation.soft,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s4.w,
            vertical: AppSpacing.s2.h,
          ),
          child: Column(
            children: List.generate(_kSubjects.length, (i) => Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s2.h),
              child: _SubjectRow(_kSubjects[i]),
            )),
          ),
        ),
      ],
    );
  }
}

// Utilisé uniquement par ProgrammeSection dans ce fichier — reste privé.
class _SubjectRow extends StatelessWidget {
  const _SubjectRow(this.subject);
  final _Subject subject;

  @override
  Widget build(BuildContext context) {
    final pct = (subject.coverage * 100).round();
    final isUrgent = subject.coverage < 0.30;
    final barColor = isUrgent ? AppColors.danger : subject.color;

    return Row(
      children: [
        Container(
          width: AppSpacing.s9.w,
          height: AppSpacing.s9.h,
          decoration: BoxDecoration(
            color: subject.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(subject.icon, size: AppIconSize.lg, color: subject.color),
        ),
        SizedBox(width: AppSpacing.s3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subject.name,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: FontWeight.w600,
                        color: isUrgent ? AppColors.danger : AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.caption,
                      fontWeight: FontWeight.w700,
                      color: barColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s1.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: subject.coverage,
                  minHeight: 4.h,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
