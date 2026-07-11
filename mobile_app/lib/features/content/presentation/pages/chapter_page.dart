import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/providers.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../dashboard/presentation/widgets/account_upgrade_sheet.dart'
    show showAccountUpgradeDialog;
import '../../../onboarding/providers.dart';
import '../../providers.dart';
import '../widgets/chapter_header.dart';
import '../widgets/fiche_summary_sheet.dart';
import '../widgets/lesson_content_tab.dart';

class ChapterPage extends ConsumerStatefulWidget {
  const ChapterPage({
    super.key,
    required this.subjectId,
    required this.chapterId,
  });

  final String subjectId;
  final String chapterId;

  @override
  ConsumerState<ChapterPage> createState() => _ChapterPageState();
}

class _ChapterPageState extends ConsumerState<ChapterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _openSummary(String languageCode) {
    if (_isNavigating) return;
    _isNavigating = true;
    showFicheSummarySheet(
      context: context,
      subjectId: widget.subjectId,
      chapterId: widget.chapterId,
      languageCode: languageCode,
    ).whenComplete(() {
      if (mounted) _isNavigating = false;
    });
  }

  void _startExercise() {
    if (_isNavigating) return;
    _isNavigating = true;
    final isAnonymous =
        ref.read(firebaseAuthProvider).currentUser?.isAnonymous ?? true;
    if (isAnonymous) {
      showAccountUpgradeDialog(
        context,
        onAccountLinked: () => context.push(
          AppRoutes.chapterQuiz(widget.subjectId, widget.chapterId),
        ),
      ).whenComplete(() {
        if (mounted) _isNavigating = false;
      });
    } else {
      context
          .push(AppRoutes.chapterQuiz(widget.subjectId, widget.chapterId))
          .whenComplete(() {
        if (mounted) _isNavigating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);

    final chaptersAsync = ref.watch(chaptersProvider(widget.subjectId));
    final subjectsAsync = ref.watch(userSubjectsProvider);

    final chapter = chaptersAsync.maybeWhen(
      data: (list) =>
          list.where((c) => c.chapterId == widget.chapterId).firstOrNull,
      orElse: () => null,
    );
    final chapterTitle = chapter?.titleFor(langCode) ?? widget.chapterId;
    final chapterOrder = chapter?.order ?? 0;
    final progressPercent = chapter?.progressPercent ?? 0;
    final studentCount = chapter?.studentCount ?? 0;

    final subject = subjectsAsync.maybeWhen(
      data: (list) =>
          list.where((s) => s.subjectId == widget.subjectId).firstOrNull,
      orElse: () => null,
    );
    final subjectAbbrev = subject?.abbreviationFor(langCode) ??
        subject?.name[langCode] ??
        subject?.name['fr'] ??
        widget.subjectId;

    final tabLabels = [
      l10n.chapterTabLessons,
      l10n.chapterTabExercises,
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Material(
            color: AppColors.card,
            child: SafeArea(
              bottom: false,
              child: ChapterHeader(
                chapterOrder: chapterOrder,
                chapterTitle: chapterTitle,
                subjectAbbrev: subjectAbbrev,
                progressPercent: progressPercent,
                tabLabels: tabLabels,
                selectedTabIndex: _tabController.index,
                onTabTap: _tabController.animateTo,
                onBack: () => context.pop(),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LessonsTab(
                  chapterId: widget.chapterId,
                  subjectId: widget.subjectId,
                  languageCode: langCode,
                  progressPercent: progressPercent,
                  studentCount: studentCount,
                ),
                _PlaceholderTab(
                  icon: Icons.edit_note_outlined,
                  label: l10n.chapterExercisesComingSoon,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ChapterActionButton(
              label: l10n.chapterFabSummary,
              icon: Icons.menu_book_outlined,
              onTap: () => _openSummary(langCode),
              backgroundColor: AppColors.card,
              foregroundColor: AppColors.primary,
              elevation: 2,
            ),
            SizedBox(height: AppSpacing.s2.h),
            _ChapterActionButton(
              label: l10n.chapterFabPractice,
              icon: Icons.play_arrow_rounded,
              onTap: _startExercise,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.card,
              elevation: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterActionButton extends StatelessWidget {
  const _ChapterActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.elevation,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      elevation: elevation,
      shadowColor: AppColors.ink.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s4.w,
            vertical: AppSpacing.s2.h,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSize.md, color: foregroundColor),
              SizedBox(width: AppSpacing.s2.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.xl8, color: AppColors.mute2),
          SizedBox(height: AppSpacing.s3),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppFontSize.body,
              color: AppColors.muted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
