// Story 1.3 — Tests unitaires OnboardingFlowState + Notifier.

import 'package:flutter_test/flutter_test.dart';
import 'package:valide_school/features/onboarding/domain/onboarding_flow_state.dart';

void main() {
  group('OnboardingFlowState — Story 1.3', () {
    test('etat initial : tous null, currentStep == filiere', () {
      const state = OnboardingFlowState();
      expect(state.filiereId, isNull);
      expect(state.niveauId, isNull);
      expect(state.serieId, isNull);
      expect(state.currentStep, OnboardingFlowStep.filiere);
      expect(state.isComplete, isFalse);
    });

    test('copyWith filiere -> currentStep == niveau', () {
      final state = const OnboardingFlowState().copyWith(filiereId: 'generale');
      expect(state.filiereId, 'generale');
      expect(state.currentStep, OnboardingFlowStep.niveau);
      expect(state.isComplete, isFalse);
    });

    test('copyWith filiere + niveau -> currentStep == recap', () {
      final state = const OnboardingFlowState().copyWith(
        filiereId: 'generale',
        niveauId: 'francophone_terminale',
      );
      expect(state.currentStep, OnboardingFlowStep.recap);
      expect(state.isComplete, isTrue);
    });

    test('copyWith complet avec serie : recap + isComplete true', () {
      final state = const OnboardingFlowState().copyWith(
        filiereId: 'generale',
        niveauId: 'francophone_terminale',
        serieId: 'francophone_terminale_d',
      );
      expect(state.currentStep, OnboardingFlowStep.recap);
      expect(state.isComplete, isTrue);
      expect(state.serieId, 'francophone_terminale_d');
    });

    test('resetFrom(filiere) -> tous null', () {
      final state = const OnboardingFlowState(
        filiereId: 'generale',
        niveauId: 'francophone_terminale',
        serieId: 'francophone_terminale_d',
      );
      final reset = state.resetFrom(OnboardingFlowStep.filiere);
      expect(reset.filiereId, isNull);
      expect(reset.niveauId, isNull);
      expect(reset.serieId, isNull);
    });

    test('resetFrom(niveau) preserve filiereId', () {
      final state = const OnboardingFlowState(
        filiereId: 'generale',
        niveauId: 'francophone_terminale',
        serieId: 'francophone_terminale_d',
      );
      final reset = state.resetFrom(OnboardingFlowStep.niveau);
      expect(reset.filiereId, 'generale');
      expect(reset.niveauId, isNull);
      expect(reset.serieId, isNull);
    });

    test('resetFrom(serie) preserve filiere + niveau', () {
      final state = const OnboardingFlowState(
        filiereId: 'generale',
        niveauId: 'francophone_terminale',
        serieId: 'francophone_terminale_d',
      );
      final reset = state.resetFrom(OnboardingFlowStep.serie);
      expect(reset.filiereId, 'generale');
      expect(reset.niveauId, 'francophone_terminale');
      expect(reset.serieId, isNull);
    });

    test('Equatable : deux states identiques sont egaux', () {
      const a = OnboardingFlowState(filiereId: 'generale');
      const b = OnboardingFlowState(filiereId: 'generale');
      expect(a, equals(b));
    });
  });
}
