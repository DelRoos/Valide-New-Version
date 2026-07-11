import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/errors/content_error_view.dart';
import '../../../../core/widgets/picker/subject_icon_resolver.dart';
import '../../../../core/widgets/segmented_tab_bar.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/providers.dart';
import '../../providers.dart';
import '../widgets/subject_header.dart';
import '../widgets/subject_loading_body.dart';
import '../widgets/subject_sequences_view.dart';

class SubjectDetailPage extends ConsumerStatefulWidget {
  const SubjectDetailPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends ConsumerState<SubjectDetailPage> {
  static const int _kInitialIndex = kMockCurrentSequence - 1;

  late final PageController _pageController;
  int _selectedIndex = _kInitialIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _kInitialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int i) {
    setState(() => _selectedIndex = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int i) {
    if (i != _selectedIndex) {
      setState(() => _selectedIndex = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final chaptersAsync = ref.watch(chaptersProvider(widget.subjectId));
    final subjectsAsync = ref.watch(userSubjectsProvider);

    final subject = subjectsAsync.maybeWhen(
      data: (list) =>
          list.where((s) => s.subjectId == widget.subjectId).firstOrNull,
      orElse: () => null,
    );
    final subjectName =
        subject?.name[langCode] ?? subject?.name['fr'] ?? widget.subjectId;
    final subjectIcon = subjectIconFor(subject?.icon ?? '');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: chaptersAsync.when(
        loading: () => SubjectLoadingBody(
          subjectName: subjectName,
          subjectIcon: subjectIcon,
          onBack: () => context.pop(),
        ),
        error: (error, _) => Column(
          children: [
            SubjectHeader(
              subjectName: subjectName,
              subjectIcon: subjectIcon,
              eyebrow: '',
              overallProgress: 0,
              rank: 0,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ContentErrorView(
                error: error,
                onRetry: () =>
                    ref.invalidate(chaptersProvider(widget.subjectId)),
              ),
            ),
          ],
        ),
        data: (chapters) {
          final currentTrim = trimesterForSequence(kMockCurrentSequence);
          final trimProgress =
              computeTrimesterProgress(chapters, kMockCurrentSequence);
          final eyebrow = l10n.subjectTrimesterEyebrow(currentTrim);
          final labels = List.generate(
            kSequencesPerYear,
            (i) => l10n.sequenceTabLabel(i + 1),
          );

          return Column(
            children: [
              SubjectHeader(
                subjectName: subjectName,
                subjectIcon: subjectIcon,
                eyebrow: eyebrow,
                overallProgress: trimProgress,
                rank: 0,
                onBack: () => context.pop(),
                bottomSlot: SegmentedTabBar(
                  labels: labels,
                  selectedIndex: _selectedIndex,
                  currentIndex: _kInitialIndex,
                  onTap: _onTabTap,
                  trackColor: Colors.white.withValues(alpha: 0.15),
                  activeBackgroundColor: AppColors.card,
                  activeTextColor: AppColors.primary,
                  inactiveTextColor: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final view = SubjectSequencesView(
                      chapters: chapters,
                      languageCode: langCode,
                      subjectId: widget.subjectId,
                      pageController: _pageController,
                      onPageChanged: _onPageChanged,
                    );
                    if (width >= 840) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: view,
                        ),
                      );
                    } else if (width >= 600) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: view,
                        ),
                      );
                    }
                    return view;
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
