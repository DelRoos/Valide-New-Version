// Tests des factories `fromFirestore(DocumentSnapshot)` — Story 1.1c AC1+AC6.
//
// Utilise `FakeFirebaseFirestore` pour produire des `DocumentSnapshot` réels
// (typés `Map<String, dynamic>`) sans dépendre d'un device.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/core/catalogue/data/firestore_mappers.dart';

Future<void> _seed(
  FakeFirebaseFirestore fs,
  String collection,
  String id,
  Map<String, dynamic> data,
) async {
  await fs.collection(collection).doc(id).set(data);
}

void main() {
  group('firestore_mappers — Story 1.1c', () {
    test('filiereFromFirestore parse name fr+en + isActive + sortOrder',
        () async {
      final fs = FakeFirebaseFirestore();
      await _seed(fs, 'filieres', 'generale', {
        'name': {'fr': 'Générale', 'en': 'General'},
        'isActive': true,
        'sortOrder': 10,
      });

      final snap = await fs.collection('filieres').doc('generale').get();
      final filiere = filiereFromFirestore(snap);

      expect(filiere.filiereId, 'generale');
      expect(filiere.name, {'fr': 'Générale', 'en': 'General'});
      expect(filiere.isActive, true);
      expect(filiere.sortOrder, 10);
    });

    test('subjectFromFirestore parse icon Lucide + bilingual name', () async {
      final fs = FakeFirebaseFirestore();
      await _seed(fs, 'subjects', 'francophone_math', {
        'subSystem': 'francophone',
        'name': {'fr': 'Mathématiques', 'en': 'Mathematics'},
        'icon': 'function-square',
        'isActive': true,
        'sortOrder': 100,
      });

      final snap =
          await fs.collection('subjects').doc('francophone_math').get();
      final subject = subjectFromFirestore(snap);

      expect(subject.subjectId, 'francophone_math');
      expect(subject.subSystem, 'francophone');
      expect(subject.icon, 'function-square');
      expect(subject.name['fr'], 'Mathématiques');
      expect(subject.name['en'], 'Mathematics');
      expect(subject.isActive, true);
    });

    test(
        'derivationRuleFromFirestore parse subjectIds + examTargetIds + '
        'matchSerie nullable', () async {
      final fs = FakeFirebaseFirestore();
      // 1) Avec matchSerie défini
      await _seed(fs, 'derivation_rules', 'rule_francophone_generale_terminale_d', {
        'matchSubSystem': 'francophone',
        'matchFiliere': 'generale',
        'matchNiveau': 'francophone_terminale',
        'matchSerie': 'francophone_terminale_d',
        'subjectIds': [
          'francophone_math',
          'francophone_pct',
          'francophone_svt',
        ],
        'examTargetIds': ['exam_bac_francophone_d'],
        'canOptOut': false,
        'isActive': true,
      });
      // 2) Avec matchSerie null (niveau sans série, ex. 6ᵉ)
      await _seed(fs, 'derivation_rules', 'rule_francophone_generale_6e_none', {
        'matchSubSystem': 'francophone',
        'matchFiliere': 'generale',
        'matchNiveau': 'francophone_6e',
        'matchSerie': null,
        'subjectIds': ['francophone_math', 'francophone_fr'],
        'examTargetIds': [],
        'canOptOut': false,
        'isActive': true,
      });

      final snapD = await fs
          .collection('derivation_rules')
          .doc('rule_francophone_generale_terminale_d')
          .get();
      final ruleD = derivationRuleFromFirestore(snapD);
      expect(ruleD.matchSubSystem, 'francophone');
      expect(ruleD.matchSerie, 'francophone_terminale_d');
      expect(ruleD.subjectIds.length, 3);
      expect(ruleD.examTargetIds, ['exam_bac_francophone_d']);
      expect(ruleD.canOptOut, false);

      final snap6 = await fs
          .collection('derivation_rules')
          .doc('rule_francophone_generale_6e_none')
          .get();
      final rule6 = derivationRuleFromFirestore(snap6);
      expect(rule6.matchSerie, isNull);
      expect(rule6.examTargetIds, isEmpty);
    });

    test('niveauFromFirestore parse filiereIds[] multiple', () async {
      final fs = FakeFirebaseFirestore();
      await _seed(fs, 'niveaux', 'francophone_terminale', {
        'subSystem': 'francophone',
        'name': {'fr': 'Terminale', 'en': 'Terminale'},
        'filiereIds': ['generale', 'technique'],
        'isActive': true,
        'sortOrder': 70,
      });

      final snap =
          await fs.collection('niveaux').doc('francophone_terminale').get();
      final niveau = niveauFromFirestore(snap);

      expect(niveau.niveauId, 'francophone_terminale');
      expect(niveau.subSystem, 'francophone');
      expect(niveau.filiereIds, ['generale', 'technique']);
      expect(niveau.filiereIds.length, 2);
    });
  });
}
