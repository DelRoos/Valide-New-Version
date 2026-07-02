import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/picker/subject_icon_resolver.dart';
import '../../../onboarding/providers.dart';
import 'school_profile_edit_sheet.dart';

// Palette cyclique — cohérente avec SubjectGridCard.
const List<Color> _kPalette = [
  Color(0xFF3B82F6),
  Color(0xFF8B5CF6),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF0EA5E9),
  Color(0xFFF97316),
  Color(0xFF6366F1),
];

Color _colorAt(int i) => _kPalette[i % _kPalette.length];

class ProgrammeSection extends ConsumerWidget {
  const ProgrammeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = Localizations.localeOf(context).languageCode;

    final profileData = ref.watch(profileDataProvider).maybeWhen(
          data: (d) => d,
          orElse: () => null,
        );

    final subjectsAsync = ref.watch(userSubjectsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mon programme',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppFontSize.h3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            if (profileData != null) ...[
              SizedBox(width: AppSpacing.s1.w),
              GestureDetector(
                onTap: () => SchoolProfileEditSheet.show(
                  context,
                  subSystem: (profileData['subSystem'] as String?) ?? '',
                  trackId: (profileData['trackId'] as String?) ?? '',
                  levelId: (profileData['levelId'] as String?) ?? '',
                  streamId: (profileData['streamId'] as String?) ?? '',
                  pickedSubjectIds: List<String>.from(
                      profileData['pickedSubjects'] as List? ?? []),
                ),
                child: Icon(
                  LucideIcons.pencil,
                  size: AppIconSize.sm,
                  color: AppColors.muted,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: AppSpacing.s3.h),
        subjectsAsync.when(
          loading: () => const _SubjectListSkeleton(),
          error: (_, _) => const SizedBox.shrink(),
          data: (subjects) {
            if (subjects.isEmpty) return const SizedBox.shrink();
            return Container(
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
                children: List.generate(
                  subjects.length,
                  (i) => Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.s2.h),
                    child: _SubjectRow(
                      subject: subjects[i],
                      index: i,
                      lang: lang,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SubjectListSkeleton extends StatelessWidget {
  const _SubjectListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: List.generate(
          4,
          (_) => Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s2.h),
            child: Row(
              children: [
                Container(
                  width: AppSpacing.s9.w,
                  height: AppSpacing.s9.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                SizedBox(width: AppSpacing.s3.w),
                Expanded(
                  child: Container(
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.subject,
    required this.index,
    required this.lang,
  });

  final Subject subject;
  final int index;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final color = _colorAt(index);
    final name = subject.name[lang] ?? subject.name['fr'] ?? subject.subjectId;

    return Row(
      children: [
        Container(
          width: AppSpacing.s9.w,
          height: AppSpacing.s9.h,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            subjectIconFor(subject.icon),
            size: AppIconSize.lg,
            color: color,
          ),
        ),
        SizedBox(width: AppSpacing.s3.w),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppFontSize.bodySmall,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
