// Story 1.8 — Tests OnboardingFlowNotifier persistance (3 cas).
//
// (a) build avec prefs prepopulees -> state restaure
// (b) selectFiliere -> pref filiere_id ecrit (et niveau/serie cleared)
// (c) backTo(filiere) -> prefs niveau + serie efaces

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/features/onboarding/domain/onboarding_flow_state.dart';
import 'package:valide_school/features/onboarding/providers.dart';

void main() {
  group('OnboardingFlowNotifier persistance — Story 1.8', () {
    test('(a) build avec prefs prepopulees -> state restaure', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding.flow.filiere_id': 'generale',
        'onboarding.flow.niveau_id': 'francophone_terminale',
        'onboarding.flow.serie_id': 'francophone_terminale_d',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final state = container.read(onboardingFlowProvider);
      expect(
        state,
        const OnboardingFlowState(
          filiereId: 'generale',
          niveauId: 'francophone_terminale',
          serieId: 'francophone_terminale_d',
        ),
      );
    });

    test('(b) selectFiliere -> pref filiere_id ecrit + niveau/serie cleared',
        () async {
      // Pre-pop avec niveau + serie pour verifier qu'ils sont bien effaces au
      // re-choix de filiere (resetFrom(filiere) -> tout vide).
      SharedPreferences.setMockInitialValues({
        'onboarding.flow.niveau_id': 'old_niveau',
        'onboarding.flow.serie_id': 'old_serie',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(onboardingFlowProvider.notifier).selectFiliere('generale');

      // L'etat in-memory bouge immediatement.
      expect(
        container.read(onboardingFlowProvider),
        const OnboardingFlowState(filiereId: 'generale'),
      );

      // La persistance est fire-and-forget : on attend la microtask pour
      // verifier que SharedPreferences a recu l'ecriture.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(prefs.getString('onboarding.flow.filiere_id'), 'generale');
      expect(prefs.getString('onboarding.flow.niveau_id'), isNull);
      expect(prefs.getString('onboarding.flow.serie_id'), isNull);
    });

    test('(c) backTo(niveau) apres flow complet -> prefs serie efacee', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding.flow.filiere_id': 'generale',
        'onboarding.flow.niveau_id': 'francophone_terminale',
        'onboarding.flow.serie_id': 'francophone_terminale_d',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // backTo(serie) reset l'etat a partir de serie (inclus). Cf. OnboardingFlowState.
      container
          .read(onboardingFlowProvider.notifier)
          .backTo(OnboardingFlowStep.serie);

      expect(
        container.read(onboardingFlowProvider),
        const OnboardingFlowState(
          filiereId: 'generale',
          niveauId: 'francophone_terminale',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(prefs.getString('onboarding.flow.filiere_id'), 'generale');
      expect(
        prefs.getString('onboarding.flow.niveau_id'),
        'francophone_terminale',
      );
      expect(prefs.getString('onboarding.flow.serie_id'), isNull);
    });
  });
}
