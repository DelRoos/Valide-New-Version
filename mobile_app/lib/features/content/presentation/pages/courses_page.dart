import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/providers.dart';
import '../widgets/courses_content.dart';
import '../widgets/courses_empty.dart';
import '../widgets/courses_loading_skeleton.dart';

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
        loading: () => const CoursesLoadingSkeleton(),
        error: (_, _) => CoursesEmpty(l10n: l10n),
        data: (subjects) {
          if (subjects.isEmpty) return CoursesEmpty(l10n: l10n);
          return CoursesContent(
            subjects: subjects,
            languageCode: languageCode,
            l10n: l10n,
          );
        },
      ),
    );
  }
}
