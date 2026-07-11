import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../catalogue/domain/models.dart';
import '../../theme/tokens.dart';
import '../picker/subject_icon_resolver.dart';
import 'subject_palette.dart';

class SubjectProgressListCard extends StatelessWidget {
  const SubjectProgressListCard({
    super.key,
    required this.subject,
    required this.index,
    required this.langKey,
    required this.progressLabel,
    required this.progressValue,
    required this.onTap,
  });

  final Subject subject;
  final int index;
  final String langKey;
  final String progressLabel;
  final double progressValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = subjectColorAt(index);
    final label = subject.abbreviationFor(langKey) ??
        (subject.name[langKey] ?? subject.name['fr'] ?? subject.subjectId);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppElevation.soft,
          ),
          padding: EdgeInsets.all(AppSpacing.s4.w),
          child: Row(
            children: [
              Container(
                width: AppSpacing.s12,
                height: AppSpacing.s12,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  subjectIconFor(subject.icon),
                  size: AppIconSize.xl3,
                  color: color,
                ),
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
                            label,
                            style: AppTypography.bodyStrong.copyWith(
                              fontSize: AppFontSize.bodySmall,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: AppSpacing.s2.w),
                        Text(
                          progressLabel,
                          style: AppTypography.eyebrow.copyWith(
                            color: AppColors.muted,
                            fontSize: AppFontSize.eyebrow,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.s2.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.s3.w),
              Icon(
                LucideIcons.chevronRight,
                size: AppIconSize.md,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
