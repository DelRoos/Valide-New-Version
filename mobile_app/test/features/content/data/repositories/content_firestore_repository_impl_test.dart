import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/content/data/repositories/content_firestore_repository_impl.dart';
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
  });
}
