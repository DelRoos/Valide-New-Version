// Story 1.2 — tests unitaires SubsystemPrefs.
//
// Aller-retour write/read + valeurs corrompues.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/features/onboarding/data/subsystem_prefs.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';

void main() {
  group('SubsystemPrefs — Story 1.2', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('read() retourne null au premier lancement (aucune valeur stockee)',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final subject = SubsystemPrefs(prefs);

      expect(subject.read(), isNull);
    });

    test('write(francophone) puis read() retourne SubSystem.francophone',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final subject = SubsystemPrefs(prefs);

      await subject.write(SubSystem.francophone);

      expect(subject.read(), SubSystem.francophone);
      // Langue derivee egalement persistee pour usage futur (Story 1.3+).
      expect(prefs.getString('onboarding.language'), 'fr');
    });

    test('write(anglophone) puis read() retourne SubSystem.anglophone + lang en',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final subject = SubsystemPrefs(prefs);

      await subject.write(SubSystem.anglophone);

      expect(subject.read(), SubSystem.anglophone);
      expect(prefs.getString('onboarding.language'), 'en');
    });

    test('read() retourne null sur valeur corrompue (string inattendue)',
        () async {
      SharedPreferences.setMockInitialValues({
        'onboarding.subsystem': 'klingon',
      });
      final prefs = await SharedPreferences.getInstance();
      final subject = SubsystemPrefs(prefs);

      expect(subject.read(), isNull);
    });
  });
}
