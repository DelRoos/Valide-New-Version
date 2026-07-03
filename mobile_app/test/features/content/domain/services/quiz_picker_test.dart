import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/content/domain/entities/quiz_question_entity.dart';
import 'package:valide_school/features/content/domain/services/quiz_picker.dart';

// Helper pour construire une question de test rapidement.
QuizQuestionEntity _q(
  String id, {
  String? notionId,
  int correctIndex = 0,
}) =>
    QuizQuestionEntity(
      id: id,
      notionId: notionId,
      textFr: 'Q $id',
      textEn: 'Q $id',
      optionsFr: ['A', 'B', 'C', 'D'],
      optionsEn: ['A', 'B', 'C', 'D'],
      correctIndex: correctIndex,
    );

void main() {
  group('QuizPicker', () {
    test('pool vide → retourne liste vide', () {
      expect(QuizPicker.pickLessonSession([]), isEmpty);
      expect(QuizPicker.pickChapterSession([]), isEmpty);
    });

    test('1 notion avec 5 questions → retourne exactement 2 questions', () {
      final questions = List.generate(5, (i) => _q('q$i', notionId: 'n1'));
      final result = QuizPicker.pickLessonSession(questions);
      expect(result.length, 2);
    });

    test(
        '2 notions avec 3 questions chacune → retourne 4 questions (2 par notion)',
        () {
      final questions = [
        ...List.generate(3, (i) => _q('a$i', notionId: 'n1')),
        ...List.generate(3, (i) => _q('b$i', notionId: 'n2')),
      ];
      final result = QuizPicker.pickLessonSession(questions);
      expect(result.length, 4);
      final fromN1 = result.where((q) => q.notionId == 'n1').length;
      final fromN2 = result.where((q) => q.notionId == 'n2').length;
      expect(fromN1, 2);
      expect(fromN2, 2);
    });

    test('pool > 15 questions → pickLessonSession retourne ≤ 15', () {
      // 10 notions × 3 questions = 30 questions → pioche 2×10=20 → cap 15
      final questions = List.generate(
        30,
        (i) => _q('q$i', notionId: 'n${i ~/ 3}'),
      );
      final result = QuizPicker.pickLessonSession(questions);
      expect(result.length, lessThanOrEqualTo(15));
    });

    test('pool > 20 questions → pickChapterSession retourne ≤ 20', () {
      // 15 notions × 3 questions = 45 questions → pioche 2×15=30 → cap 20
      final questions = List.generate(
        45,
        (i) => _q('q$i', notionId: 'n${i ~/ 3}'),
      );
      final result = QuizPicker.pickChapterSession(questions);
      expect(result.length, lessThanOrEqualTo(20));
    });

    test('correctIndex des questions retournées est inchangé', () {
      final questions = List.generate(
        4,
        (i) => _q('q$i', notionId: 'n1', correctIndex: i),
      );
      final result = QuizPicker.pickLessonSession(questions);
      for (final q in result) {
        // retrouve la question originale par son id et vérifie le correctIndex
        final original = questions.firstWhere((o) => o.id == q.id);
        expect(q.correctIndex, original.correctIndex);
      }
    });

    test('questions sans notionId sont regroupées et limitées à 2', () {
      final questions = List.generate(5, (i) => _q('q$i'));
      final result = QuizPicker.pickLessonSession(questions);
      // Toutes les questions n'ont pas de notionId → 1 groupe → max 2
      expect(result.length, 2);
      expect(result.every((q) => q.notionId == null), isTrue);
    });
  });
}
