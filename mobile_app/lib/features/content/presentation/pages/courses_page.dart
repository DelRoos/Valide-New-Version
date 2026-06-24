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
import '../../../dashboard/data/fake/dashboard_fake_data.dart';
import '../../../onboarding/providers.dart';

// Palette de couleurs cyclique pour identifier visuellement chaque matière.
const List<Color> _kSubjectPalette = [
  Color(0xFF3B82F6), // bleu
  Color(0xFF8B5CF6), // violet
  Color(0xFF10B981), // vert émeraude
  Color(0xFFF59E0B), // ambre
  Color(0xFFEF4444), // rouge rose
  Color(0xFF0EA5E9), // ciel
  Color(0xFFF97316), // orange
  Color(0xFF6366F1), // indigo
];

Color _subjectColor(int index) => _kSubjectPalette[index % _kSubjectPalette.length];

class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final subjectsAsync = ref.watch(userSubjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          l10n.coursesPageTitle,
          style: AppTypography.h2.copyWith(fontSize: AppFontSize.h2),
        ),
      ),
      body: subjectsAsync.when(
        loading: () => const _CoursesLoadingSkeleton(),
        error: (_, _) => _CoursesEmpty(l10n: l10n),
        data: (subjects) {
          if (subjects.isEmpty) return _CoursesEmpty(l10n: l10n);
          return _CoursesContent(
            subjects: subjects,
            languageCode: languageCode,
            l10n: l10n,
          );
        },
      ),
    );
  }
}

// ── Main content ─────────────────────────────────────────────────────────────

class _CoursesContent extends StatelessWidget {
  const _CoursesContent({
    required this.subjects,
    required this.languageCode,
    required this.l10n,
  });

  final List<Subject> subjects;
  final String languageCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Banner recommandation
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s4.w,
              AppSpacing.s2.h,
              AppSpacing.s4.w,
              AppSpacing.s5.h,
            ),
            child: _RecommendationBanner(
              languageCode: languageCode,
              l10n: l10n,
            ),
          ),
        ),
        // Grille matières
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s4.w,
            0,
            AppSpacing.s4.w,
            AppSpacing.s8.h,
          ),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => SubjectGridCard(subject: subjects[i], index: i),
              childCount: subjects.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.s3.w,
              mainAxisSpacing: AppSpacing.s3.h,
              childAspectRatio: 0.77,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Recommendation banner ─────────────────────────────────────────────────────

class _RecommendationBanner extends StatelessWidget {
  const _RecommendationBanner({
    required this.languageCode,
    required this.l10n,
  });

  final String languageCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final title = kFakeRecommendation.title(languageCode);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.all(AppSpacing.s5.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chip "Recommandé"
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.s2.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: AppIconSize.xs,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              l10n.dashboardRecommendedTitle,
                              style: AppTypography.eyebrow.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: AppFontSize.eyebrow,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.s3.h),
                      // Titre leçon
                      Text(
                        title,
                        style: AppTypography.bodyStrong.copyWith(
                          fontSize: AppFontSize.body,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSpacing.s4.h),
                      // CTA
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.s4.w,
                          vertical: AppSpacing.s2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.play,
                              size: AppIconSize.sm,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: AppSpacing.s1.w),
                            Text(
                              l10n.coursesStartLesson,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: AppFontSize.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.s4.w),
                // Icône décorative
                Container(
                  width: 64.w,
                  height: 64.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Icon(
                    LucideIcons.bookOpen,
                    size: AppIconSize.xl5,
                    color: Colors.white.withValues(alpha: 0.9),
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

// ── Subject grid card (public — partagé avec DashboardSubjectsArea) ───────────

class SubjectGridCard extends StatelessWidget {
  const SubjectGridCard({
    super.key,
    required this.subject,
    required this.index,
  });

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
              // Header coloré avec icône
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
              // Info bas : nom + progression
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
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$pct%',
                                style: AppTypography.eyebrow.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: AppFontSize.eyebrow,
                                ),
                              ),
                            ],
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

class _CoursesLoadingSkeleton extends StatelessWidget {
  const _CoursesLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s4.w,
              AppSpacing.s2.h,
              AppSpacing.s4.w,
              AppSpacing.s5.h,
            ),
            child: Container(
              height: 160.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1400.ms, color: AppColors.bg),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s4.w,
            0,
            AppSpacing.s4.w,
            AppSpacing.s8.h,
          ),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _SkeletonCard(color: _subjectColor(i)),
              childCount: 6,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.s3.w,
              mainAxisSpacing: AppSpacing.s3.h,
              childAspectRatio: 0.77,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
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
                color: color.withValues(alpha: 0.10),
                child: Center(
                  child: Container(
                    width: AppSpacing.s12,
                    height: AppSpacing.s12,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
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
                      width: 72.w,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1400.ms, color: AppColors.bg),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 11.h,
                          width: 30.w,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          height: 5.h,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
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
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _CoursesEmpty extends StatelessWidget {
  const _CoursesEmpty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
