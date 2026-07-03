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
      // Le blob Markdown vit dans lessons/{id}/content/main — absent du document principal.
      expect(entity.contentFr, isNull);
      expect(entity.contentEn, isNull);
      expect(entity.subtitleFr, 'Notion clé');
      expect(entity.subtitleEn, 'Key notion');
      expect(entity.durationMinutes, 8);
    });

    test('content dans le doc principal est ignoré (lu depuis sous-doc content/main)', () async {
      // Vérifie que LessonModel.fromFirestore n'essaie pas de lire le champ
      // content du document principal — il vit dans lessons/{id}/content/main.
      await fakeFirestore.collection('lessons').doc('l02').set({
        'chapterId': 'ch01',
        'order': 2,
        'title': {'fr': 'Dérivées', 'en': 'Derivatives'},
        'content': {'fr': '# FR'},  // ce champ est ignoré par LessonModel
      });

      final doc = await fakeFirestore.collection('lessons').doc('l02').get();
      final entity = LessonModel.fromFirestore(doc).toEntity();

      expect(entity.contentFr, isNull);
      expect(entity.contentEn, isNull);
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
