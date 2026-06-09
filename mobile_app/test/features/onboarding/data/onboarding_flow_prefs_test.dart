// Story 1.8 — Tests data OnboardingFlowPrefs (3 cas).
//
// (a) read sans valeur prefs -> OnboardingFlowState() vide
// (b) write puis read -> meme state (roundtrip)
// (c) clear -> read retourne state vide

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/features/onboarding/data/onboarding_flow_prefs.dart';
import 'package:valide_school/features/onboarding/domain/onboarding_flow_state.dart';

void main() {
  group('OnboardingFlowPrefs — Story 1.8', () {
    test('(a) read sans valeur prefs -> OnboardingFlowState vide', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final sut = OnboardingFlowPrefs(prefs);

      expect(sut.read(), const OnboardingFlowState());
    });

    test('(b) write puis read -> meme state (roundtrip)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final sut = OnboardingFlowPrefs(prefs);

      const state = OnboardingFlowState(
        filiereId: 'generale',
        niveauId: 'francophone_terminale',
        serieId: 'francophone_terminale_d',
      );
      await sut.write(state);

      expect(sut.read(), state);
      // Verifie aussi les cles SharedPreferences pour eviter regression silencieuse.
      expect(prefs.getString('onboarding.flow.filiere_id'), 'generale');
      expect(
        prefs.getString('onboarding.flow.niveau_id'),
        'francophone_terminale',
      );
      expect(
        prefs.getString('onboarding.flow.serie_id'),
        'francophone_terminale_d',
      );
    });

    test('(c) clear -> read retourne state vide + cles supprimees', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding.flow.filiere_id': 'generale',
        'onboarding.flow.niveau_id': 'francophone_terminale',
        'onboarding.flow.serie_id': 'francophone_terminale_d',
      });
      final prefs = await SharedPreferences.getInstance();
      final sut = OnboardingFlowPrefs(prefs);

      await sut.clear();

      expect(sut.read(), const OnboardingFlowState());
      expect(prefs.getString('onboarding.flow.filiere_id'), isNull);
      expect(prefs.getString('onboarding.flow.niveau_id'), isNull);
      expect(prefs.getString('onboarding.flow.serie_id'), isNull);
    });

    test('(d) write avec niveau null -> remove de la cle (pas de "null" string)',
        () async {
      SharedPreferences.setMockInitialValues({
        'onboarding.flow.niveau_id': 'francophone_terminale',
        'onboarding.flow.serie_id': 'francophone_terminale_d',
      });
      final prefs = await SharedPreferences.getInstance();
      final sut = OnboardingFlowPrefs(prefs);

      await sut.write(const OnboardingFlowState(filiereId: 'generale'));

      expect(prefs.getString('onboarding.flow.filiere_id'), 'generale');
      expect(prefs.getString('onboarding.flow.niveau_id'), isNull);
      expect(prefs.getString('onboarding.flow.serie_id'), isNull);
    });
  });
}
