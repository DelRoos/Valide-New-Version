import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/features/content/data/models/lesson_model.dart';
import 'package:valide_school/features/content/domain/entities/lesson_entity.dart';

void main() {
  group('LessonModel.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('succès : mappe tous les champs correctement', () async {
      await fakeFirestore.collection('lessons').doc('l01').set({
        'chapterId': 'ch01',
        'order': 1,
        'title': {'fr': 'Limites finies', 'en': 'Finite Limits'},
        'content': {
          'fr': '# Contenu FR\nUn paragraphe.',
          'en': '# Content EN\nA paragraph.',
        },
        'subtitle': {'fr': 'Notion clé', 'en': 'Key notion'},
        'durationMinutes': 8,
      });

      final doc = await fakeFirestore.collection('lessons').doc('l01').get();
      final entity = LessonModel.fromFirestore(doc).toEntity();

      expect(entity.lessonId, 'l01');
      expect(entity.chapterId, 'ch01');
      expect(entity.order, 1);
      expect(entity.titleFr, 'Limites finies');
      expect(entity.titleEn, 'Finite Limits');
      expect(entity.contentFr, '# Contenu FR\nUn paragraphe.');
      expect(entity.contentEn, '# Content EN\nA paragraph.');
      expect(entity.subtitleFr, 'Notion clé');
      expect(entity.subtitleEn, 'Key notion');
      expect(entity.durationMinutes, 8);
    });

    test('content.en absent → contentEn vide', () async {
      await fakeFirestore.collection('lessons').doc('l02').set({
        'chapterId': 'ch01',
        'order': 2,
        'title': {'fr': 'Dérivées', 'en': 'Derivatives'},
        'content': {'fr': '# FR'},
      });

      final doc = await fakeFirestore.collection('lessons').doc('l02').get();
      final entity = LessonModel.fromFirestore(doc).toEntity();

      expect(entity.contentFr, '# FR');
      expect(entity.contentEn, '');
    });

    test('durationMinutes absent → défaut 0', () async {
      await fakeFirestore.collection('lessons').doc('l03').set({
        'chapterId': 'ch01',
        'order': 3,
        'title': {'fr': 'Intégrales', 'en': 'Integrals'},
        'content': {'fr': '', 'en': ''},
      });

      final doc = await fakeFirestore.collection('lessons').doc('l03').get();
      final entity = LessonModel.fromFirestore(doc).toEntity();

      expect(entity.durationMinutes, 0);
    });

    test('subtitle absent → subtitleFr et subtitleEn nulls', () async {
      await fakeFirestore.collection('lessons').doc('l04').set({
        'chapterId': 'ch01',
        'order': 4,
        'title': {'fr': 'Matrices', 'en': 'Matrices'},
        'content': {'fr': '...', 'en': '...'},
      });

      final doc = await fakeFirestore.collection('lessons').doc('l04').get();
      final entity = LessonModel.fromFirestore(doc).toEntity();

      expect(entity.subtitleFr, isNull);
      expect(entity.subtitleEn, isNull);
    });

    test('toEntity retourne un LessonEntity', () async {
      await fakeFirestore.collection('lessons').doc('l05').set({
        'chapterId': 'ch01',
        'order': 5,
        'title': {'fr': 'Vecteurs', 'en': 'Vectors'},
        'content': {'fr': '', 'en': ''},
      });

      final doc = await fakeFirestore.collection('lessons').doc('l05').get();
      final entity = LessonModel.fromFirestore(doc).toEntity();

      expect(entity, isA<LessonEntity>());
    });
  });
}
