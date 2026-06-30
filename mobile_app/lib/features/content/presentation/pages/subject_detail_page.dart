import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/errors/content_error_view.dart';
import '../../../../core/widgets/picker/subject_icon_resolver.dart';
import '../../../onboarding/providers.dart';
import '../../providers.dart';
import '../widgets/chapter_list.dart';
import '../widgets/subject_header.dart';
import '../widgets/subject_loading_body.dart';

class SubjectDetailPage extends ConsumerWidget {
  const SubjectDetailPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = Localizations.localeOf(context).languageCode;
    final isFr = langCode == 'fr';
    final chaptersAsync = ref.watch(chaptersProvider(subjectId));
    final subjectsAsync = ref.watch(userSubjectsProvider);

    final subject = subjectsAsync.maybeWhen(
      data: (list) => list.where((s) => s.subjectId == subjectId).firstOrNull,
      orElse: () => null,
    );
    final subjectName =
        subject?.name[langCode] ?? subject?.name['fr'] ?? subjectId;
    final subjectIcon = subjectIconFor(subject?.icon ?? '');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: chaptersAsync.when(
        loading: () => SubjectLoadingBody(
          subjectName: subjectName,
          subjectIcon: subjectIcon,
          isFr: isFr,
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
              isFr: isFr,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ContentErrorView(
                error: error,
                onRetry: () => ref.invalidate(chaptersProvider(subjectId)),
              ),
            ),
          ],
        ),
        data: (chapters) {
          final overallProgress = chapters.isEmpty
              ? 0
              : (chapters
                          .map((c) => c.progressPercent)
                          .fold(0, (s, p) => s + p) /
                      chapters.length)
                  .round();
          final eyebrow = '${chapters.length} ${isFr ? 'CHAPITRES' : 'CHAPTERS'}';

          return Column(
            children: [
              SubjectHeader(
                subjectName: subjectName,
                subjectIcon: subjectIcon,
                eyebrow: eyebrow,
                overallProgress: overallProgress,
                rank: 0,
                isFr: isFr,
                onBack: () => context.pop(),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final list = ChapterList(
                      chapters: chapters,
                      languageCode: langCode,
                      subjectId: subjectId,
                    );
                    if (width >= 840) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: list,
                        ),
                      );
                    } else if (width >= 600) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: list,
                        ),
                      );
                    }
                    return list;
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
