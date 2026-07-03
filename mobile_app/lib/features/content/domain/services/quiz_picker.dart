import 'dart:math';

import '../entities/quiz_question_entity.dart';

const _kQuestionsPerNotion = 2;
const _kMaxLessonSession = 15;
const _kMaxChapterSession = 20;

abstract final class QuizPicker {
  static List<QuizQuestionEntity> pickLessonSession(
    List<QuizQuestionEntity> questions,
  ) =>
      _pick(questions, _kMaxLessonSession);

  static List<QuizQuestionEntity> pickChapterSession(
    List<QuizQuestionEntity> questions,
  ) =>
      _pick(questions, _kMaxChapterSession);

  static List<QuizQuestionEntity> _pick(
    List<QuizQuestionEntity> questions,
    int max,
  ) {
    if (questions.isEmpty) return [];

    final Map<String, List<QuizQuestionEntity>> groups = {};
    for (final q in questions) {
      groups.putIfAbsent(q.notionId ?? '_none_', () => []).add(q);
    }

    final rng = Random();
    final keys = groups.keys.toList()..shuffle(rng);
    final picked = <QuizQuestionEntity>[];
    for (final key in keys) {
      final pool = [...groups[key]!]..shuffle(rng);
      picked.addAll(pool.take(_kQuestionsPerNotion));
    }

    if (picked.length > max) picked.shuffle(rng);
    return picked.length > max ? picked.sublist(0, max) : picked;
  }
}
