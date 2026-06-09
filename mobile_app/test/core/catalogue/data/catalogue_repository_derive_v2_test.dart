// Tests CatalogueRepositoryFirestoreImpl.derive() v2 — Story 1.13.
//
// Vérifient le DerivedProfile enrichi (pickerMode + obligatorySubjects +
// optionalSubjects + min/maxSubjects) sur 3 personas v2 :
//  1. Fatou Tle D francophone : pickerMode derived, 11 matières v2 (post-1.12)
//  2. James Upper Sixth S2 anglo : pickerMode optOut, canOptOut true, 3 matières
//     + lecture des transversales optionalSubjects (computer_science, ict,
//     religious_studies, economics)
//  3. Eyong TVE AL ELET : pickerMode tvePicker, min 6, max 8, obligatorySubjects
//     EN+FR

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/catalogue/data/catalogue_repository_firestore_impl.dart';
import 'package:valide_school/core/catalogue/domain/models.dart';

// =======================================================================
// Seed helpers — subset matrice v2 pour tests
// =======================================================================

Future<void> _seedSubjects(FakeFirebaseFirestore fs) async {
  // Francophone (Fatou Tle D)
  for (final s in [
    ('francophone_math', 'Math', 'function-square', 10),
    ('francophone_physique', 'Physique', 'atom', 22),
    ('francophone_chimie', 'Chimie', 'flask-conical', 24),
    ('francophone_svt', 'SVT', 'leaf', 30),
    ('francophone_environnement', 'Environnement', 'leaf', 32),
    ('francophone_fr', 'Français', 'book-open-text', 40),
    ('francophone_en', 'Anglais', 'languages', 50),
    ('francophone_philo', 'Philo', 'brain', 60),
    ('francophone_hg', 'HG', 'landmark', 70),
    ('francophone_info', 'Info', 'code-2', 85),
    ('francophone_eps', 'EPS', 'dumbbell', 90),
  ]) {
    await fs.collection('subjects').doc(s.$1).set({
      'subSystem': 'francophone',
      'name': {'fr': s.$2, 'en': s.$2},
      'icon': s.$3,
      'isActive': true,
      'sortOrder': s.$4,
    });
  }
  // Anglophone (James Upper Sixth S2 + transversales)
  for (final s in [
    ('anglophone_chemistry', 'Chemistry', 'flask-conical', 20),
    ('anglophone_physics', 'Physics', 'atom', 30),
    ('anglophone_biology', 'Biology', 'dna', 40),
    ('anglophone_computer_science', 'CS', 'code-2', 130),
    ('anglophone_ict', 'ICT', 'code-2', 135),
    ('anglophone_religious_studies', 'RS', 'book-marked', 175),
    ('anglophone_economics', 'Economics', 'shopping-bag', 100),
    ('anglophone_english_lang', 'English', 'languages', 10),
    ('anglophone_french', 'French', 'languages', 15),
  ]) {
    await fs.collection('subjects').doc(s.$1).set({
      'subSystem': 'anglophone',
      'name': {'fr': s.$2, 'en': s.$2},
      'icon': s.$3,
      'isActive': true,
      'sortOrder': s.$4,
    });
  }
}

Future<void> _seedSeriesV2(FakeFirebaseFirestore fs) async {
  // Fatou — francophone_terminale_d (pickerMode derived par defaults safe)
  await fs.collection('series').doc('francophone_terminale_d').set({
    'subSystem': 'francophone',
    'niveauId': 'francophone_terminale',
    'filiereId': 'generale',
    'name': {'fr': 'Tle D', 'en': 'Tle D'},
    'canOptOut': false,
    'isActive': true,
    'sortOrder': 75,
    'pickerMode': 'derived',
  });
  // James — anglophone_upper_sixth_s2 (pickerMode opt_out + min 3 max 5)
  await fs.collection('series').doc('anglophone_upper_sixth_s2').set({
    'subSystem': 'anglophone',
    'niveauId': 'anglophone_upper_sixth',
    'filiereId': 'generale',
    'name': {'fr': 'Upper Sixth S2', 'en': 'Upper Sixth S2'},
    'canOptOut': true,
    'isActive': true,
    'sortOrder': 220,
    'pickerMode': 'opt_out',
    'minSubjects': 3,
    'maxSubjects': 5,
  });
  // Eyong — anglophone_tve_al_elet (pickerMode tve_picker + min 6 max 8)
  await fs.collection('series').doc('anglophone_tve_al_elet').set({
    'subSystem': 'anglophone',
    'niveauId': 'anglophone_tve_al',
    'filiereId': 'technique',
    'name': {'fr': 'TVE AL ELET', 'en': 'TVE AL ELET'},
    'canOptOut': false,
    'isActive': true, // activé pour test (Story 1.12 défaut false)
    'sortOrder': 1203,
    'pickerMode': 'tve_picker',
    'minSubjects': 6,
    'maxSubjects': 8,
    'professionalSubjectIds': <String>[],
    'relatedProfessionalSubjectIds': <String>[],
    'otherSubjectIds': <String>[],
  });
}

Future<void> _seedExamTargets(FakeFirebaseFirestore fs) async {
  for (final e in [
    ('exam_bac_francophone_d', 'BAC D', 'francophone'),
    ('exam_gce_a_level_anglophone_s2', 'A-Level S2', 'anglophone'),
    ('exam_tve_al_anglophone_elet', 'TVE AL ELET', 'anglophone'),
  ]) {
    await fs.collection('exam_targets').doc(e.$1).set({
      'subSystem': e.$3,
      'name': {'fr': e.$2, 'en': e.$2},
      'isActive': true,
      'sortOrder': 100,
    });
  }
}

Future<void> _seedRulesV2(FakeFirebaseFirestore fs) async {
  // Fatou Tle D v2 — 11 matières
  await fs
      .collection('derivation_rules')
      .doc('rule_francophone_generale_terminale_d')
      .set({
    'matchSubSystem': 'francophone',
    'matchFiliere': 'generale',
    'matchNiveau': 'francophone_terminale',
    'matchSerie': 'francophone_terminale_d',
    'subjectIds': [
      'francophone_math',
      'francophone_physique',
      'francophone_chimie',
      'francophone_svt',
      'francophone_environnement',
      'francophone_fr',
      'francophone_en',
      'francophone_philo',
      'francophone_hg',
      'francophone_info',
      'francophone_eps',
    ],
    'examTargetIds': ['exam_bac_francophone_d'],
    'canOptOut': false,
    'isActive': true,
    'obligatorySubjectIds': <String>[],
    'optionalSubjectIds': <String>[],
  });
  // James Upper Sixth S2 — 3 matières dérivées (Series) + 4 transversales
  await fs
      .collection('derivation_rules')
      .doc('rule_anglophone_generale_upper_sixth_s2')
      .set({
    'matchSubSystem': 'anglophone',
    'matchFiliere': 'generale',
    'matchNiveau': 'anglophone_upper_sixth',
    'matchSerie': 'anglophone_upper_sixth_s2',
    'subjectIds': [
      'anglophone_chemistry',
      'anglophone_physics',
      'anglophone_biology',
    ],
    'examTargetIds': ['exam_gce_a_level_anglophone_s2'],
    'canOptOut': true,
    'isActive': true,
    'obligatorySubjectIds': [
      'anglophone_chemistry',
      'anglophone_physics',
      'anglophone_biology',
    ],
    'optionalSubjectIds': [
      'anglophone_computer_science',
      'anglophone_ict',
      'anglophone_religious_studies',
      'anglophone_economics',
    ],
  });
  // Eyong TVE AL ELET — squelette (subjectIds vides post-1.12) + EN+FR oblig.
  await fs
      .collection('derivation_rules')
      .doc('rule_anglophone_technique_tve_al_elet')
      .set({
    'matchSubSystem': 'anglophone',
    'matchFiliere': 'technique',
    'matchNiveau': 'anglophone_tve_al',
    'matchSerie': 'anglophone_tve_al_elet',
    'subjectIds': <String>[],
    'examTargetIds': ['exam_tve_al_anglophone_elet'],
    'canOptOut': false,
    'isActive': true,
    'obligatorySubjectIds': [
      'anglophone_english_lang',
      'anglophone_french',
    ],
    'optionalSubjectIds': <String>[],
  });
}

// =======================================================================
// Tests
// =======================================================================

void main() {
  group('CatalogueRepository.derive() v2 — Story 1.13', () {
    test(
        'Fatou Tle D francophone : pickerMode derived + 11 matieres + '
        'obligatory/optional vides + canOptOut false', () async {
      final fs = FakeFirebaseFirestore();
      await _seedSubjects(fs);
      await _seedSeriesV2(fs);
      await _seedExamTargets(fs);
      await _seedRulesV2(fs);

      final repo = CatalogueRepositoryFirestoreImpl(fs);
      final result = await repo.derive(
        subSystem: 'francophone',
        filiere: 'generale',
        niveau: 'francophone_terminale',
        serie: 'francophone_terminale_d',
      );

      expect(result.isRight(), true);
      final profile = result.getRight().toNullable()!;
      expect(profile.subjects.length, 11);
      expect(profile.examTargets.length, 1);
      expect(profile.examTargets.first.examTargetId, 'exam_bac_francophone_d');
      // v2 enriched fields
      expect(profile.pickerMode, PickerMode.derived);
      expect(profile.canOptOut, false);
      expect(profile.obligatorySubjects, isEmpty);
      expect(profile.optionalSubjects, isEmpty);
      expect(profile.minSubjects, isNull);
      expect(profile.maxSubjects, isNull);
    });

    test(
        'James Upper Sixth S2 anglo : pickerMode optOut + canOptOut true + '
        '3 matieres + 4 transversales optionalSubjects', () async {
      final fs = FakeFirebaseFirestore();
      await _seedSubjects(fs);
      await _seedSeriesV2(fs);
      await _seedExamTargets(fs);
      await _seedRulesV2(fs);

      final repo = CatalogueRepositoryFirestoreImpl(fs);
      final result = await repo.derive(
        subSystem: 'anglophone',
        filiere: 'generale',
        niveau: 'anglophone_upper_sixth',
        serie: 'anglophone_upper_sixth_s2',
      );

      expect(result.isRight(), true);
      final profile = result.getRight().toNullable()!;
      expect(profile.subjects.length, 3);
      expect(profile.subjects.map((s) => s.subjectId).toSet(), {
        'anglophone_chemistry',
        'anglophone_physics',
        'anglophone_biology',
      });
      // v2 enriched fields — Story 1.4 non-régression critique
      expect(profile.pickerMode, PickerMode.optOut);
      expect(profile.canOptOut, true); // source série v2
      expect(profile.obligatorySubjects.length, 3); // = subjects (Series obl.)
      expect(profile.optionalSubjects.length, 4); // 4 transversales
      expect(profile.optionalSubjects.map((s) => s.subjectId).toSet(), {
        'anglophone_computer_science',
        'anglophone_ict',
        'anglophone_religious_studies',
        'anglophone_economics',
      });
      expect(profile.minSubjects, 3);
      expect(profile.maxSubjects, 5);
    });

    test(
        'Eyong TVE AL ELET : pickerMode tvePicker + min 6 max 8 + '
        'obligatorySubjects EN+FR + subjects vides squelette Story 1.17', () async {
      final fs = FakeFirebaseFirestore();
      await _seedSubjects(fs);
      await _seedSeriesV2(fs);
      await _seedExamTargets(fs);
      await _seedRulesV2(fs);

      final repo = CatalogueRepositoryFirestoreImpl(fs);
      final result = await repo.derive(
        subSystem: 'anglophone',
        filiere: 'technique',
        niveau: 'anglophone_tve_al',
        serie: 'anglophone_tve_al_elet',
      );

      expect(result.isRight(), true);
      final profile = result.getRight().toNullable()!;
      expect(profile.subjects, isEmpty); // squelette Story 1.17 affinera
      expect(profile.examTargets.length, 1);
      expect(profile.examTargets.first.examTargetId, 'exam_tve_al_anglophone_elet');
      // v2 enriched fields
      expect(profile.pickerMode, PickerMode.tvePicker);
      expect(profile.canOptOut, false);
      expect(profile.obligatorySubjects.length, 2);
      expect(profile.obligatorySubjects.map((s) => s.subjectId).toSet(), {
        'anglophone_english_lang',
        'anglophone_french',
      });
      expect(profile.optionalSubjects, isEmpty);
      expect(profile.minSubjects, 6);
      expect(profile.maxSubjects, 8);
    });

    test(
        'derive() sans série (niveau Form 1 anglo par ex.) : pickerMode '
        'fallback derived + min/max null', () async {
      final fs = FakeFirebaseFirestore();
      await _seedSubjects(fs);
      // Pas de série seedée pour ce cas
      await _seedExamTargets(fs);
      // Rule Form 1 avec matchSerie: null
      await fs
          .collection('derivation_rules')
          .doc('rule_anglophone_generale_form_1_none')
          .set({
        'matchSubSystem': 'anglophone',
        'matchFiliere': 'generale',
        'matchNiveau': 'anglophone_form_1',
        'matchSerie': null,
        'subjectIds': ['anglophone_english_lang', 'anglophone_french'],
        'examTargetIds': <String>[],
        'canOptOut': false,
        'isActive': true,
      });

      final repo = CatalogueRepositoryFirestoreImpl(fs);
      final result = await repo.derive(
        subSystem: 'anglophone',
        filiere: 'generale',
        niveau: 'anglophone_form_1',
      );

      expect(result.isRight(), true);
      final profile = result.getRight().toNullable()!;
      expect(profile.subjects.length, 2);
      // Pas de série → fallback PickerMode.derived
      expect(profile.pickerMode, PickerMode.derived);
      expect(profile.canOptOut, false);
      expect(profile.minSubjects, isNull);
      expect(profile.maxSubjects, isNull);
    });
  });
}
