import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/catalogue/domain/models.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/picker/subject_icon_resolver.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/providers.dart';

// Fake exercise counts — remplacés par Firestore en Story 2.x.
const List<int> _kFakeTotal = [18, 24, 12, 30, 16, 22, 14, 28];
const List<int> _kFakeDone = [6, 14, 3, 22, 4, 18, 9, 12];
int _fakeTotal(int i) => _kFakeTotal[i % _kFakeTotal.length];
int _fakeDone(int i) => _kFakeDone[i % _kFakeDone.length].clamp(0, _fakeTotal(i));

const List<Color> _kPalette = [
  Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFF10B981), Color(0xFFF59E0B),
  Color(0xFFEF4444), Color(0xFF0EA5E9), Color(0xFFF97316), Color(0xFF6366F1),
];

class ExamsTabPage extends ConsumerWidget {
  const ExamsTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
          l10n.examsPageTitle,
          style: AppTypography.h2.copyWith(fontSize: AppFontSize.h2),
        ),
      ),
      body: subjectsAsync.when(
        loading: () => const _ExamsSkeleton(),
        error: (_, _) => const _ExamsEmpty(),
        data: (subjects) => subjects.isEmpty
            ? const _ExamsEmpty()
            : _ExamsBody(subjects: subjects),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _ExamsBody extends StatelessWidget {
  const _ExamsBody({required this.subjects});

  final List<Subject> subjects;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langKey = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s4.w, AppSpacing.s2.h, AppSpacing.s4.w, AppSpacing.s8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CountdownBanner(l10n: l10n),
          SizedBox(height: AppSpacing.s6.h),
          Text(
            l10n.examsSectionTitle,
            style: AppTypography.h3.copyWith(fontSize: AppFontSize.h3),
          ),
          SizedBox(height: AppSpacing.s3.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjects.length,
            separatorBuilder: (_, _) => SizedBox(height: AppSpacing.s3.h),
            itemBuilder: (_, i) => _SubjectExamCard(
              subject: subjects[i],
              index: i,
              langKey: langKey,
              l10n: l10n,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Countdown banner ──────────────────────────────────────────────────────────

class _CountdownBanner extends StatelessWidget {
  const _CountdownBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF0891B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              bottom: -24,
              child: Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 24,
              top: -30,
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.s5.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chip exam
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.s3.w, vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            l10n.examsCountdownChip,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: AppFontSize.caption,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.s3.h),
                        Text(
                          l10n.examsCountdownHeadline,
                          style: AppTypography.h2.copyWith(
                            color: Colors.white,
                            fontSize: AppFontSize.h2,
                          ),
                        ),
                        SizedBox(height: AppSpacing.s1.h),
                        Text(
                          l10n.examsCountdownSubtitle,
                          style: AppTypography.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: AppFontSize.bodySmall,
                          ),
                        ),
                        SizedBox(height: AppSpacing.s4.h),
                        Text(
                          l10n.examsCountdownPrepared(35),
                          style: AppTypography.eyebrow.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                            fontSize: AppFontSize.eyebrow,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: 0.35,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.s5.w),
                  // Countdown chiffre
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '4',
                        style: AppTypography.display.copyWith(
                          color: Colors.white,
                          fontSize: 48.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        l10n.examsCountdownMonths,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: AppFontSize.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subject exam card ─────────────────────────────────────────────────────────

class _SubjectExamCard extends StatelessWidget {
  const _SubjectExamCard({
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
            GoRouter.of(context).push('/subject/${subject.subjectId}'),
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

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _ExamsSkeleton extends StatelessWidget {
  const _ExamsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s4.w, AppSpacing.s2.h, AppSpacing.s4.w, AppSpacing.s8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180.h,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ).animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1400.ms, color: AppColors.bg),
          SizedBox(height: AppSpacing.s6.h),
          Container(
            width: 140.w, height: 22.h,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ).animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1400.ms, color: AppColors.bg),
          SizedBox(height: AppSpacing.s3.h),
          ...List.generate(4, (i) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s3.h),
            child: Container(
              height: 72.h,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppElevation.soft,
              ),
            ).animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1400.ms, color: AppColors.bg),
          )),
        ],
      ),
    );
  }
}

class _ExamsEmpty extends StatelessWidget {
  const _ExamsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bookMarked,
                size: AppIconSize.xl9, color: AppColors.muted),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              AppLocalizations.of(context).dashboardEmptyStateText,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
