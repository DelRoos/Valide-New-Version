import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../onboarding/providers.dart';
import '../../providers.dart';
import '../widgets/chapter_header.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final isFr = langCode == 'fr';

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
    final subjectAbbrev =
        subject?.abbreviationFor(langCode) ?? widget.subjectId.toUpperCase();

    final tabLabels = [
      isFr ? 'Leçons' : 'Lessons',
      'Quiz',
      isFr ? 'Exercices' : 'Exercises',
      'Fiche',
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
                isFr: isFr,
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
                  icon: Icons.quiz_outlined,
                  label: isFr
                      ? 'Quiz bientôt disponibles'
                      : 'Quizzes coming soon',
                ),
                _PlaceholderTab(
                  icon: Icons.edit_note_outlined,
                  label: isFr
                      ? 'Exercices bientôt disponibles'
                      : 'Exercises coming soon',
                ),
                _PlaceholderTab(
                  icon: Icons.description_outlined,
                  label: isFr
                      ? 'Fiche de révision bientôt disponible'
                      : 'Study sheet coming soon',
                ),
              ],
            ),
          ),
        ],
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
