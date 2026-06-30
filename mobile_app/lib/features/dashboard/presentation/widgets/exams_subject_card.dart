import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/picker/subject_icon_resolver.dart';
import '../../../../l10n/generated/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fake exercise counts — remplacés par Firestore en Story 2.x.
// ---------------------------------------------------------------------------

const List<Color> _kPalette = [
  Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFF10B981), Color(0xFFF59E0B),
  Color(0xFFEF4444), Color(0xFF0EA5E9), Color(0xFFF97316), Color(0xFF6366F1),
];

const List<int> _kFakeTotal = [18, 24, 12, 30, 16, 22, 14, 28];
const List<int> _kFakeDone = [6, 14, 3, 22, 4, 18, 9, 12];

int _fakeTotal(int i) => _kFakeTotal[i % _kFakeTotal.length];
int _fakeDone(int i) => _kFakeDone[i % _kFakeDone.length].clamp(0, _fakeTotal(i));

// ---------------------------------------------------------------------------
// Subject exam card
// ---------------------------------------------------------------------------

class ExamsSubjectCard extends StatelessWidget {
  const ExamsSubjectCard({
    super.key,
    required this.subject,
    required this.index,
    required this.langKey,
    required this.l10n,
  });

  final Subject subject;
  final int index;
  final String langKey;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final total = _fakeTotal(index);
    final done = _fakeDone(index);
    final color = _kPalette[index % _kPalette.length];
    final label = subject.abbreviationFor(langKey) ??
        (subject.name[langKey] ?? subject.name['fr'] ?? subject.subjectId);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () =>
            GoRouter.of(context).push(AppRoutes.subject(subject.subjectId)),
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
                          l10n.examsExercisesOf(done, total),
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
                        value: done / total,
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
