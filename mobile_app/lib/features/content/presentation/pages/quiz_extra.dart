import '../../domain/entities/quiz_question_entity.dart';

/// Données passées via GoRouter state.extra entre QuizPage → QuizResultPage → QuizReviewPage.
class QuizResultExtra {
  const QuizResultExtra({
    required this.score,
    required this.total,
    required this.questions,
    required this.answers,
  });

  final int score;
  final int total;
  final List<QuizQuestionEntity> questions;
  final List<int?> answers;
}
