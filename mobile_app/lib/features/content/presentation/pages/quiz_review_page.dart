import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../widgets/quiz_review_screen.dart';
import 'quiz_extra.dart';

class QuizReviewPage extends StatelessWidget {
  const QuizReviewPage({super.key, required this.extra});

  final QuizResultExtra extra;

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: QuizReviewScreen(
          questions: extra.questions,
          answers: extra.answers,
          score: extra.score,
          isFr: isFr,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
