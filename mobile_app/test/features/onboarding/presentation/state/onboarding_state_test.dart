import 'package:flutter_test/flutter_test.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/presentation/state/onboarding_state.dart';

void main() {
  group('OnboardingState — constructeur initial', () {
    test('produit currentStep=0 et tous les champs draft nuls/empty/false',
        () {
      const state = OnboardingState();

      expect(state.currentStep, 0);
      expect(state.subSystem, isNull);
      expect(state.trackId, isNull);
      expect(state.levelId, isNull);
      expect(state.levelRequiresPicker, isFalse);
      expect(state.streamId, isNull);
      expect(state.pickedSubjects, isEmpty);
      expect(state.userDisplayName, isNull);
      expect(state.phoneNumber, isNull);
      expect(state.phoneSkipped, isFalse);
      expect(state.schoolId, isNull);
      expect(state.schoolName, isNull);
      expect(state.pendingSchoolRequestId, isNull);
      expect(state.schoolSkipped, isFalse);
      expect(state.isVisitor, isFalse);
      expect(state.authProvider, isNull);
    });
  });

  group('OnboardingState — copyWith', () {
    test('preserve les champs non touches', () {
      const initial = OnboardingState(
        currentStep: 3,
        subSystem: SubSystem.francophone,
        trackId: 'general',
        levelId: 'francophone_terminale',
        levelRequiresPicker: true,
      );

      final updated = initial.copyWith(streamId: 'francophone_terminale_d');

      expect(updated.currentStep, 3);
      expect(updated.subSystem, SubSystem.francophone);
      expect(updated.trackId, 'general');
      expect(updated.levelId, 'francophone_terminale');
      expect(updated.levelRequiresPicker, isTrue);
      expect(updated.streamId, 'francophone_terminale_d');
    });

    test('permet de remettre un champ nullable a null via la sentinelle', () {
      const initial = OnboardingState(
        currentStep: 4,
        streamId: 'francophone_terminale_d',
        pickedSubjects: ['math', 'physics'],
      );

      final reset = initial.copyWith(
        streamId: null,
        pickedSubjects: const <String>[],
      );

      expect(reset.streamId, isNull);
      expect(reset.pickedSubjects, isEmpty);
    });

    test('ne touche pas un champ nullable si parametre absent', () {
      const initial = OnboardingState(
        userDisplayName: 'Fatou Mballa',
        phoneNumber: '+237671234567',
      );

      final updated = initial.copyWith(currentStep: 9);

      expect(updated.userDisplayName, 'Fatou Mballa');
      expect(updated.phoneNumber, '+237671234567');
      expect(updated.currentStep, 9);
    });
  });

  group('OnboardingState — Equatable', () {
    test('deux states identiques sont egaux', () {
      const a = OnboardingState(
        currentStep: 2,
        subSystem: SubSystem.anglophone,
        trackId: 'technical',
      );
      const b = OnboardingState(
        currentStep: 2,
        subSystem: SubSystem.anglophone,
        trackId: 'technical',
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('deux states avec un champ different ne sont pas egaux', () {
      const a = OnboardingState(currentStep: 2);
      const b = OnboardingState(currentStep: 3);

      expect(a, isNot(equals(b)));
    });

    test('pickedSubjects fait partie de l equality', () {
      const a = OnboardingState(pickedSubjects: ['math']);
      const b = OnboardingState(pickedSubjects: ['math', 'physics']);

      expect(a, isNot(equals(b)));
    });
  });

  group('OnboardingState — toFirestorePayload', () {
    test('n inclut que les champs non-null + isAnonymous toujours present',
        () {
      const state = OnboardingState();

      final payload = state.toFirestorePayload();

      expect(payload.keys, contains('isAnonymous'));
      expect(payload['isAnonymous'], isFalse);
      expect(payload.containsKey('subSystem'), isFalse);
      expect(payload.containsKey('trackId'), isFalse);
      expect(payload.containsKey('levelId'), isFalse);
      expect(payload.containsKey('streamId'), isFalse);
      expect(payload.containsKey('pickedSubjects'), isFalse);
      expect(payload.containsKey('displayName'), isFalse);
      expect(payload.containsKey('phoneNumber'), isFalse);
      expect(payload.containsKey('schoolId'), isFalse);
      expect(payload.containsKey('schoolName'), isFalse);
      expect(payload.containsKey('pendingSchoolRequestId'), isFalse);
      expect(payload.containsKey('authProvider'), isFalse);
    });

    test('serialise les champs poses + traduit subSystem et authProvider en id',
        () {
      const state = OnboardingState(
        subSystem: SubSystem.francophone,
        trackId: 'general',
        levelId: 'francophone_terminale',
        streamId: 'francophone_terminale_d',
        pickedSubjects: ['math', 'physics'],
        userDisplayName: 'Fatou Mballa',
        phoneNumber: '+237671234567',
        schoolId: 'school_yde_42',
        schoolName: 'College Vogt',
        authProvider: OnboardingAuthProvider.google,
        isVisitor: false,
      );

      final payload = state.toFirestorePayload();

      expect(payload['subSystem'], 'francophone');
      expect(payload['trackId'], 'general');
      expect(payload['levelId'], 'francophone_terminale');
      expect(payload['streamId'], 'francophone_terminale_d');
      expect(payload['pickedSubjects'], ['math', 'physics']);
      expect(payload['displayName'], 'Fatou Mballa');
      expect(payload['phoneNumber'], '+237671234567');
      expect(payload['schoolId'], 'school_yde_42');
      expect(payload['schoolName'], 'College Vogt');
      expect(payload['authProvider'], 'google');
      expect(payload['isAnonymous'], isFalse);
    });

    test('serialise pendingSchoolRequestId + isAnonymous=true en mode visiteur',
        () {
      const state = OnboardingState(
        subSystem: SubSystem.anglophone,
        pendingSchoolRequestId: 'req_abc123',
        schoolName: 'New School Buea',
        authProvider: OnboardingAuthProvider.guest,
        isVisitor: true,
      );

      final payload = state.toFirestorePayload();

      expect(payload['pendingSchoolRequestId'], 'req_abc123');
      expect(payload['schoolName'], 'New School Buea');
      expect(payload['authProvider'], 'guest');
      expect(payload['isAnonymous'], isTrue);
    });
  });

  group('OnboardingAuthProvider — fromString', () {
    test('parse les valeurs canoniques', () {
      expect(OnboardingAuthProvider.fromString('google'),
          OnboardingAuthProvider.google);
      expect(OnboardingAuthProvider.fromString('apple'),
          OnboardingAuthProvider.apple);
      expect(OnboardingAuthProvider.fromString('guest'),
          OnboardingAuthProvider.guest);
    });

    test('retourne null pour entree inconnue ou null', () {
      expect(OnboardingAuthProvider.fromString(null), isNull);
      expect(OnboardingAuthProvider.fromString(''), isNull);
      expect(OnboardingAuthProvider.fromString('facebook'), isNull);
      expect(OnboardingAuthProvider.fromString('GOOGLE'), isNull);
    });
  });
}
