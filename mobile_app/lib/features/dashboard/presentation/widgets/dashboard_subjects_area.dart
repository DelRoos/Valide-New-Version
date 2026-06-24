// Zone matières du dashboard — grille 2×2 max 4 items.
//
// Design : header coloré par matière (palette cyclique) + icône + nom + barre
// de progression colorée. Identique au SubjectGridCard de CoursesPage.
// "Voir tout" navigue vers /courses.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/picker/subject_icon_resolver.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/providers.dart';
import '../../data/fake/dashboard_fake_data.dart';

const int _kMaxSubjectsOnHome = 4;

// Même palette que CoursesPage — cohérence visuelle cross-tabs.
const List<Color> _kSubjectPalette = [
  Color(0xFF3B82F6),
  Color(0xFF8B5CF6),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF0EA5E9),
  Color(0xFFF97316),
  Color(0xFF6366F1),
];

Color _subjectColor(int index) =>
    _kSubjectPalette[index % _kSubjectPalette.length];

class DashboardSubjectsArea extends ConsumerWidget {
  const DashboardSubjectsArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(userSubjectsProvider);
    return subjectsAsync.when(
      loading: () => const _SkeletonGrid(),
      error: (_, _) => const _EmptyDashboard(),
      data: (subjects) {
        if (subjects.isEmpty) return const _EmptyDashboard();
        return _SubjectsList(subjects: subjects);
      },
    );
  }
}

// ── Grid avec header ─────────────────────────────────────────────────────────

class _SubjectsList extends StatelessWidget {
  const _SubjectsList({required this.subjects});

  final List<Subject> subjects;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displaySubjects = subjects.take(_kMaxSubjectsOnHome).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.dashboardMySubjectsTitle,
              style: AppTypography.h3.copyWith(fontSize: AppFontSize.h3),
            ),
            if (subjects.length > _kMaxSubjectsOnHome)
              TextButton(
                onPressed: () => GoRouter.of(context).go('/courses'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.s2.w,
                    vertical: AppSpacing.s1.h,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.dashboardSeeAll,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: AppFontSize.caption,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.s3.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.s3.w,
            mainAxisSpacing: AppSpacing.s3.h,
            childAspectRatio: 0.77,
          ),
          itemCount: displaySubjects.length,
          itemBuilder: (_, i) => _SubjectGridCard(
            subject: displaySubjects[i],
            index: i,
          ),
        ),
      ],
    );
  }
}

// ── Subject grid card ────────────────────────────────────────────────────────

class _SubjectGridCard extends StatelessWidget {
  const _SubjectGridCard({required this.subject, required this.index});

  final Subject subject;
  final int index;

  @override
  Widget build(BuildContext context) {
    final langKey = Localizations.localeOf(context).languageCode;
    final pct = fakeProgressAt(index).clamp(0, 100);
    final abbr = subject.abbreviationFor(langKey);
    final name =
        subject.name[langKey] ?? subject.name['fr'] ?? subject.subjectId;
    final label = abbr ?? name;
    final color = _subjectColor(index);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppElevation.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: () =>
              GoRouter.of(context).push('/subject/${subject.subjectId}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 10,
                child: Container(
                  color: color.withValues(alpha: 0.10),
                  child: Center(
                    child: Container(
                      width: AppSpacing.s12,
                      height: AppSpacing.s12,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Icon(
                        subjectIconFor(subject.icon),
                        size: AppIconSize.xl4,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 8,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s3.w,
                    AppSpacing.s3.h,
                    AppSpacing.s3.w,
                    AppSpacing.s3.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: AppTypography.bodyStrong.copyWith(
                          fontSize: AppFontSize.bodySmall,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$pct%',
                            style: AppTypography.eyebrow.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: AppFontSize.eyebrow,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor:
                                  color.withValues(alpha: 0.12),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(color),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading skeleton ─────────────────────────────────────────────────────────

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120.w,
          height: 22.h,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(
              duration: 1400.ms,
              color: AppColors.bg,
            ),
        SizedBox(height: AppSpacing.s3.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.s3.w,
            mainAxisSpacing: AppSpacing.s3.h,
            childAspectRatio: 0.77,
          ),
          itemCount: _kMaxSubjectsOnHome,
          itemBuilder: (_, i) {
            final color = _subjectColor(i);
            return Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppElevation.soft,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 10,
                      child: Container(
                        color: color.withValues(alpha: 0.08),
                        child: Center(
                          child: Container(
                            width: AppSpacing.s12,
                            height: AppSpacing.s12,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .shimmer(duration: 1400.ms, color: AppColors.bg),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.s3.w,
                          AppSpacing.s3.h,
                          AppSpacing.s3.w,
                          AppSpacing.s3.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 14.h,
                              width: 64.w,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(
                                    duration: 1400.ms, color: AppColors.bg),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 11.h,
                                  width: 28.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.border,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Container(
                                  height: 5.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.border,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.pill),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.bookOpen,
              size: AppIconSize.xl9,
              color: AppColors.muted,
            ),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              l10n.dashboardEmptyStateText,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s5.h),
            AppButton.primary(
              label: l10n.dashboardEmptyStateCta,
              onPressed: () => GoRouter.of(context).go('/onboarding/v2'),
            ),
          ],
        ),
      ),
    );
  }
}
