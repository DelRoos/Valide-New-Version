import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/providers.dart';
import 'widgets/exams_body.dart';

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
        loading: () => const ExamsSkeleton(),
        error: (_, _) => const ExamsEmpty(),
        data: (subjects) => subjects.isEmpty
            ? const ExamsEmpty()
            : ExamsBody(subjects: subjects),
      ),
    );
  }
}
