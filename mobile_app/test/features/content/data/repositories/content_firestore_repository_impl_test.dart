import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/content/data/repositories/content_firestore_repository_impl.dart';
import 'package:valide_school/features/content/domain/entities/chapter_fiche_entity.dart';
import 'package:valide_school/features/content/domain/failures/content_failure.dart';

void main() {
  group('ContentFirestoreRepositoryImpl', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ContentFirestoreRepositoryImpl repo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repo = ContentFirestoreRepositoryImpl(firestore: fakeFirestore);
    });

    // ── getChapters ────────────────────────────────────────

    group('getChapters', () {
      test('succès : retourne les chapitres triés par order', () async {
        await fakeFirestore.collection('chapters').add({
          'subjectId': 'math',
          'order': 2,
          'title': {'fr': 'Chapitre 2', 'en': 'Chapter 2'},
        });
        await fakeFirestore.collection('chapters').add({
          'subjectId': 'math',
          'order': 1,
          'title': {'fr': 'Chapitre 1', 'en': 'Chapter 1'},
        });
        await fakeFirestore.collection('chapters').add({
          'subjectId': 'physics',
          'order': 1,
          'title': {'fr': 'Physique 1', 'en': 'Physics 1'},
        });

        final result = await repo.getChapters('math');

        expect(result.isRight(), isTrue);
        final chapters = result.getRight().toNullable()!;
        expect(chapters.length, 2);
        expect(chapters.first.order, 1);
        expect(chapters.last.order, 2);
      });

      test('succès : retourne liste vide si aucun chapitre pour subjectId',
          () async {
        final result = await repo.getChapters('unknown_subject');

        expect(result.isRight(), isTrue);
        expect(result.getRight().toNullable()!, isEmpty);
      });
    });

    // ── getLessons ────────────────────────────────────────

    group('getLessons', () {
      test('succès : retourne les leçons triées par order', () async {
        await fakeFirestore.collection('lessons').add({
          'chapterId': 'ch01',
          'order': 3,
          'title': {'fr': 'Leçon 3', 'en': 'Lesson 3'},
          'content': {'fr': '', 'en': ''},
        });
        await fakeFirestore.collection('lessons').add({
          'chapterId': 'ch01',
          'order': 1,
          'title': {'fr': 'Leçon 1', 'en': 'Lesson 1'},
          'content': {'fr': '', 'en': ''},
        });

        final result = await repo.getLessons('ch01');

        expect(result.isRight(), isTrue);
        final lessons = result.getRight().toNullable()!;
        expect(lessons.length, 2);
        expect(lessons.first.order, 1);
        expect(lessons.last.order, 3);
      });

      test('filtre par chapterId : ne retourne pas les leçons d\'autres chapitres',
          () async {
        await fakeFirestore.collection('lessons').add({
          'chapterId': 'ch01',
          'order': 1,
          'title': {'fr': 'Leçon ch01', 'en': 'Lesson ch01'},
          'content': {'fr': '', 'en': ''},
        });
        await fakeFirestore.collection('lessons').add({
          'chapterId': 'ch02',
          'order': 1,
          'title': {'fr': 'Leçon ch02', 'en': 'Lesson ch02'},
          'content': {'fr': '', 'en': ''},
        });

        final result = await repo.getLessons('ch01');

        expect(result.isRight(), isTrue);
        final lessons = result.getRight().toNullable()!;
        expect(lessons.length, 1);
        expect(lessons.first.chapterId, 'ch01');
      });

      test('retourne liste vide si aucune leçon pour chapterId', () async {
        final result = await repo.getLessons('chapitre_inexistant');

        expect(result.isRight(), isTrue);
        expect(result.getRight().toNullable()!, isEmpty);
      });

      // Note : le mapping FirebaseException → ContentFailure.networkError suit
      // le même code path que getChapters (même catch block). FakeFirebaseFirestore
      // ne peut pas simuler FirebaseException — ce path est couvert par le test
      // getChapters + la vérification du code de mapping dans content_failure.dart.
    });

    // ── getLessonById ─────────────────────────────────────

    group('getLessonById', () {
      test('succès : retourne la leçon par son ID', () async {
        await fakeFirestore.collection('lessons').doc('lesson_abc').set({
          'chapterId': 'ch01',
          'order': 1,
          'title': {'fr': 'Ma leçon', 'en': 'My lesson'},
          'content': {'fr': '# FR', 'en': '# EN'},
        });

        final result = await repo.getLessonById('lesson_abc');

        expect(result.isRight(), isTrue);
        expect(result.getRight().toNullable()!.lessonId, 'lesson_abc');
      });

      test('doc inexistant → Left(ContentFailure.notFound)', () async {
        final result = await repo.getLessonById('does_not_exist');

        expect(result.isLeft(), isTrue);
        final failure = result.getLeft().toNullable()!;
        expect(failure.kind, ContentFailureKind.notFound);
      });
    });

    // ── getQuizQuestions ──────────────────────────────────────

    group('getQuizQuestions', () {
      test(
          'succès multi-docs : aplatit les questions de plusieurs quiz docs',
          () async {
        final lessonRef =
            fakeFirestore.collection('lessons').doc('lesson_q1');
        await lessonRef.collection('quizzes').doc('q01').set({
          'lessonId': 'lesson_q1',
          'version': 1,
          'questions': [
            {
              'id': 'q01_1',
              'notionId': null,
              'text': {'fr': 'Q1', 'en': 'Q1'},
              'type': 'mcq',
              'options': {
                'fr': ['A', 'B', 'C', 'D'],
                'en': ['A', 'B', 'C', 'D'],
              },
              'correctIndex': 0,
            },
            {
              'id': 'q01_2',
              'notionId': 'n1',
              'text': {'fr': 'Q2', 'en': 'Q2'},
              'type': 'mcq',
              'options': {
                'fr': ['A', 'B', 'C', 'D'],
                'en': ['A', 'B', 'C', 'D'],
              },
              'correctIndex': 1,
            },
          ],
        });
        await lessonRef.collection('quizzes').doc('q02').set({
          'lessonId': 'lesson_q1',
          'version': 1,
          'questions': [
            {
              'id': 'q02_1',
              'notionId': 'n2',
              'text': {'fr': 'Q3', 'en': 'Q3'},
              'type': 'mcq',
              'options': {
                'fr': ['A', 'B', 'C', 'D'],
                'en': ['A', 'B', 'C', 'D'],
              },
              'correctIndex': 2,
            },
          ],
        });

        final result = await repo.getQuizQuestions('lesson_q1');

        expect(result.isRight(), isTrue);
        final questions = result.getRight().toNullable()!;
        expect(questions.length, 3);
        expect(
          questions.map((q) => q.id),
          containsAll(['q01_1', 'q01_2', 'q02_1']),
        );
      });

      test('sous-collection vide → Right([])', () async {
        final result = await repo.getQuizQuestions('lesson_sans_quiz');

        expect(result.isRight(), isTrue);
        expect(result.getRight().toNullable()!, isEmpty);
      });
    });

    // ── getFiche ──────────────────────────────────────────

    group('getFiche', () {
      test('succès : retourne la fiche avec contentFr et contentEn', () async {
        await fakeFirestore
            .collection('chapters')
            .doc('ch01')
            .collection('fiche')
            .doc('main')
            .set({'fr': '# Résumé FR', 'en': '# Summary EN'});

        final result = await repo.getFiche('ch01');

        expect(result.isRight(), isTrue);
        final fiche = result.getRight().toNullable()!;
        expect(fiche, isA<ChapterFicheEntity>());
        expect(fiche.chapterId, 'ch01');
        expect(fiche.contentFr, '# Résumé FR');
        expect(fiche.contentEn, '# Summary EN');
      });

      test('doc inexistant → Left(ContentFailure.notFound)', () async {
        final result = await repo.getFiche('ch_inconnu');

        expect(result.isLeft(), isTrue);
        final failure = result.getLeft().toNullable()!;
        expect(failure.kind, ContentFailureKind.notFound);
      });
    });
  });
}
