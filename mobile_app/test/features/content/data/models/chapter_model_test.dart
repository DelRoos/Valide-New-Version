import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/content/data/models/chapter_model.dart';
import 'package:valide_school/features/content/domain/entities/chapter_entity.dart';

void main() {
  group('ChapterModel.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('succès : mappe tous les champs correctement', () async {
      await fakeFirestore.collection('chapters').doc('ch01').set({
        'subjectId': 'francophone_math',
        'order': 1,
        'title': {'fr': 'Limites', 'en': 'Limits'},
        'description': {
          'fr': 'Desc FR',
          'en': 'Desc EN',
        },
        'lessonCount': 3,
        'quizCount': 2,
        'exerciseCount': 5,
        'progressPercent': 60,
        'studentCount': 1200,
      });

      final doc = await fakeFirestore.collection('chapters').doc('ch01').get();
      final model = ChapterModel.fromFirestore(doc);
      final entity = model.toEntity();

      expect(entity.chapterId, 'ch01');
      expect(entity.subjectId, 'francophone_math');
      expect(entity.order, 1);
      expect(entity.titleFr, 'Limites');
      expect(entity.titleEn, 'Limits');
      expect(entity.descriptionFr, 'Desc FR');
      expect(entity.descriptionEn, 'Desc EN');
      expect(entity.lessonCount, 3);
      expect(entity.quizCount, 2);
      expect(entity.exerciseCount, 5);
      expect(entity.progressPercent, 60);
      expect(entity.studentCount, 1200);
    });

    test('champ description absent → entité sans description', () async {
      await fakeFirestore.collection('chapters').doc('ch02').set({
        'subjectId': 'math',
        'order': 2,
        'title': {'fr': 'Dérivation', 'en': 'Differentiation'},
      });

      final doc = await fakeFirestore.collection('chapters').doc('ch02').get();
      final entity = ChapterModel.fromFirestore(doc).toEntity();

      expect(entity.descriptionFr, isNull);
      expect(entity.descriptionEn, isNull);
    });

    test('title partiel (seulement fr) → titleEn vide', () async {
      await fakeFirestore.collection('chapters').doc('ch03').set({
        'subjectId': 'math',
        'order': 3,
        'title': {'fr': 'Intégration'},
      });

      final doc = await fakeFirestore.collection('chapters').doc('ch03').get();
      final entity = ChapterModel.fromFirestore(doc).toEntity();

      expect(entity.titleFr, 'Intégration');
      expect(entity.titleEn, '');
    });

    test('progressPercent absent → défaut 0', () async {
      await fakeFirestore.collection('chapters').doc('ch04').set({
        'subjectId': 'math',
        'order': 4,
        'title': {'fr': 'Stats', 'en': 'Statistics'},
      });

      final doc = await fakeFirestore.collection('chapters').doc('ch04').get();
      final entity = ChapterModel.fromFirestore(doc).toEntity();

      expect(entity.progressPercent, 0);
      expect(entity.studentCount, 0);
      expect(entity.lessonCount, 0);
    });

    test('toEntity retourne un ChapterEntity', () async {
      await fakeFirestore.collection('chapters').doc('ch05').set({
        'subjectId': 'physics',
        'order': 1,
        'title': {'fr': 'Optique', 'en': 'Optics'},
      });

      final doc = await fakeFirestore.collection('chapters').doc('ch05').get();
      final entity = ChapterModel.fromFirestore(doc).toEntity();

      expect(entity, isA<ChapterEntity>());
    });
  });
}
