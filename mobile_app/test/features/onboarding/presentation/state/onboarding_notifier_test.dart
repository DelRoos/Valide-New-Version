import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/presentation/state/onboarding_providers.dart';
import 'package:valide_school/features/onboarding/presentation/state/onboarding_state.dart';
import 'package:valide_school/features/onboarding/providers.dart'
    show sharedPreferencesProvider;

/// Helper : container Riverpod avec SharedPreferences mocke. `initial` peut
/// fournir des cles pre-existantes (test loadFromPersistence).
Future<ProviderContainer> _buildContainer({
  Map<String, Object> initial = const {},
}) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  // =========================================================================
  // SETTERS
  // =========================================================================
  group('OnboardingNotifier — setSubSystem', () {
    test('persiste en SharedPreferences + state.subSystem + step -> 1',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      await container
          .read(onboardingNotifierProvider.notifier)
          .setSubSystem(SubSystem.francophone);

      final state = container.read(onboardingNotifierProvider);
      expect(state.subSystem, SubSystem.francophone);
      expect(state.currentStep, 1);

      // Verifier persistance via une seconde lecture independante.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('onboarding.subsystem'), 'francophone');
      expect(prefs.getString('onboarding.language'), 'fr');
    });

    test('anglophone -> persiste en correctement', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      await container
          .read(onboardingNotifierProvider.notifier)
          .setSubSystem(SubSystem.anglophone);

      final state = container.read(onboardingNotifierProvider);
      expect(state.subSystem, SubSystem.anglophone);
      expect(state.currentStep, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('onboarding.subsystem'), 'anglophone');
    });
  });

  group('OnboardingNotifier — setTrackId', () {
    test('pose le trackId + currentStep -> 3', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container
          .read(onboardingNotifierProvider.notifier)
          .setTrackId('general');

      final state = container.read(onboardingNotifierProvider);
      expect(state.trackId, 'general');
      expect(state.currentStep, 3);
    });
  });

  group('OnboardingNotifier — setLevelId', () {
    test('requiresPicker=true -> currentStep 4', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container
          .read(onboardingNotifierProvider.notifier)
          .setLevelId('francophone_terminale', requiresPicker: true);

      final state = container.read(onboardingNotifierProvider);
      expect(state.levelId, 'francophone_terminale');
      expect(state.levelRequiresPicker, isTrue);
      expect(state.currentStep, 4);
    });

    test('requiresPicker=false (mode derived) -> currentStep 5 (skip step 4)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container
          .read(onboardingNotifierProvider.notifier)
          .setLevelId('francophone_6e', requiresPicker: false);

      final state = container.read(onboardingNotifierProvider);
      expect(state.levelId, 'francophone_6e');
      expect(state.levelRequiresPicker, isFalse);
      expect(state.currentStep, 5);
    });
  });

  group('OnboardingNotifier — setStreamAndSubjects', () {
    test('pose stream + subjects + currentStep -> 5', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container.read(onboardingNotifierProvider.notifier).setStreamAndSubjects(
        streamId: 'francophone_terminale_d',
        pickedSubjects: ['math', 'physics', 'svt'],
      );

      final state = container.read(onboardingNotifierProvider);
      expect(state.streamId, 'francophone_terminale_d');
      expect(state.pickedSubjects, ['math', 'physics', 'svt']);
      expect(state.currentStep, 5);
    });

    test('streamId null (mode free_with_obligatory) -> accepte', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container.read(onboardingNotifierProvider.notifier).setStreamAndSubjects(
        streamId: null,
        pickedSubjects: ['math'],
      );

      final state = container.read(onboardingNotifierProvider);
      expect(state.streamId, isNull);
      expect(state.pickedSubjects, ['math']);
    });
  });

  group('OnboardingNotifier — setAuthProvider', () {
    test('OAuth Google avec displayName -> skip step 6 -> step 7', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container.read(onboardingNotifierProvider.notifier).setAuthProvider(
            OnboardingAuthProvider.google,
            displayName: 'Fatou Mballa',
          );

      final state = container.read(onboardingNotifierProvider);
      expect(state.authProvider, OnboardingAuthProvider.google);
      expect(state.userDisplayName, 'Fatou Mballa');
      expect(state.isVisitor, isFalse);
      expect(state.currentStep, 7);
    });

    test('OAuth Apple sans displayName -> step 6 (saisie requise)', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container
          .read(onboardingNotifierProvider.notifier)
          .setAuthProvider(OnboardingAuthProvider.apple);

      final state = container.read(onboardingNotifierProvider);
      expect(state.authProvider, OnboardingAuthProvider.apple);
      expect(state.userDisplayName, isNull);
      expect(state.isVisitor, isFalse);
      expect(state.currentStep, 6);
    });

    test('Visiteur (guest) -> isVisitor=true + step 6 (pas de name OAuth)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container
          .read(onboardingNotifierProvider.notifier)
          .setAuthProvider(OnboardingAuthProvider.guest);

      final state = container.read(onboardingNotifierProvider);
      expect(state.authProvider, OnboardingAuthProvider.guest);
      expect(state.isVisitor, isTrue);
      expect(state.currentStep, 6);
    });

    test('OAuth avec displayName vide string -> step 6 (pas considere fourni)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container
          .read(onboardingNotifierProvider.notifier)
          .setAuthProvider(OnboardingAuthProvider.google, displayName: '');

      final state = container.read(onboardingNotifierProvider);
      expect(state.currentStep, 6);
    });
  });

  group('OnboardingNotifier — setUserDisplayName', () {
    test('pose name + currentStep -> 7', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container
          .read(onboardingNotifierProvider.notifier)
          .setUserDisplayName('James Tanyi');

      final state = container.read(onboardingNotifierProvider);
      expect(state.userDisplayName, 'James Tanyi');
      expect(state.currentStep, 7);
    });
  });

  group('OnboardingNotifier — setPhoneNumber / skipPhone', () {
    test('compte non-visiteur -> currentStep 8 (school)', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container
          .read(onboardingNotifierProvider.notifier)
          .setPhoneNumber('+237671234567');

      final state = container.read(onboardingNotifierProvider);
      expect(state.phoneNumber, '+237671234567');
      expect(state.phoneSkipped, isFalse);
      expect(state.currentStep, 8);
    });

    test('visiteur (isVisitor=true) -> currentStep 9 (skip school)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.setAuthProvider(OnboardingAuthProvider.guest);
      notifier.setUserDisplayName('Eyong');
      notifier.setPhoneNumber('+237671234567');

      final state = container.read(onboardingNotifierProvider);
      expect(state.isVisitor, isTrue);
      expect(state.currentStep, 9);
    });

    test('skipPhone -> phoneSkipped=true + meme transition', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container.read(onboardingNotifierProvider.notifier).skipPhone();

      final state = container.read(onboardingNotifierProvider);
      expect(state.phoneNumber, isNull);
      expect(state.phoneSkipped, isTrue);
      expect(state.currentStep, 8);
    });
  });

  group('OnboardingNotifier — setSchool / setPendingSchoolRequest / skipSchool',
      () {
    test('setSchool -> currentStep 9', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container.read(onboardingNotifierProvider.notifier).setSchool(
            schoolId: 'school_yde_42',
            schoolName: 'College Vogt',
          );

      final state = container.read(onboardingNotifierProvider);
      expect(state.schoolId, 'school_yde_42');
      expect(state.schoolName, 'College Vogt');
      expect(state.schoolSkipped, isFalse);
      expect(state.pendingSchoolRequestId, isNull);
      expect(state.currentStep, 9);
    });

    test('setPendingSchoolRequest -> pose pendingRequestId + schoolName',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container
          .read(onboardingNotifierProvider.notifier)
          .setPendingSchoolRequest(
            pendingRequestId: 'req_abc123',
            schoolName: 'New School Buea',
          );

      final state = container.read(onboardingNotifierProvider);
      expect(state.schoolId, isNull);
      expect(state.pendingSchoolRequestId, 'req_abc123');
      expect(state.schoolName, 'New School Buea');
      expect(state.currentStep, 9);
    });

    test('skipSchool -> schoolSkipped=true + tous schoolFields null',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container.read(onboardingNotifierProvider.notifier).skipSchool();

      final state = container.read(onboardingNotifierProvider);
      expect(state.schoolId, isNull);
      expect(state.schoolName, isNull);
      expect(state.pendingSchoolRequestId, isNull);
      expect(state.schoolSkipped, isTrue);
      expect(state.currentStep, 9);
    });
  });

  // =========================================================================
  // RESET DOWNSTREAM
  // =========================================================================
  group('OnboardingNotifier — reset downstream sur changement amont', () {
    test('setTrackId apres level + stream poses -> reset downstream',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.setTrackId('general');
      notifier.setLevelId('francophone_terminale', requiresPicker: true);
      notifier.setStreamAndSubjects(
        streamId: 'francophone_terminale_d',
        pickedSubjects: ['math'],
      );

      // Re-tap track : reset downstream.
      notifier.setTrackId('technical');

      final state = container.read(onboardingNotifierProvider);
      expect(state.trackId, 'technical');
      expect(state.levelId, isNull);
      expect(state.levelRequiresPicker, isFalse);
      expect(state.streamId, isNull);
      expect(state.pickedSubjects, isEmpty);
      expect(state.currentStep, 3);
    });

    test('setLevelId apres stream pose -> reset stream + subjects', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.setLevelId('francophone_terminale', requiresPicker: true);
      notifier.setStreamAndSubjects(
        streamId: 'francophone_terminale_d',
        pickedSubjects: ['math', 'physics'],
      );

      // Re-tap level : reset stream/subjects.
      notifier.setLevelId('francophone_1ere', requiresPicker: true);

      final state = container.read(onboardingNotifierProvider);
      expect(state.levelId, 'francophone_1ere');
      expect(state.streamId, isNull);
      expect(state.pickedSubjects, isEmpty);
    });

    test(
        'reset() retourne au state initial sans toucher SharedPreferences',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.setSubSystem(SubSystem.francophone);
      notifier.setTrackId('general');

      notifier.reset();

      expect(container.read(onboardingNotifierProvider),
          const OnboardingState());

      // SharedPreferences inchangees.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('onboarding.subsystem'), 'francophone');
    });
  });

  // =========================================================================
  // TRANSITIONS next()
  // =========================================================================
  group('OnboardingNotifier — next() conditionnel', () {
    test('step 0 -> 1', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      container.read(onboardingNotifierProvider.notifier).next();
      expect(container.read(onboardingNotifierProvider).currentStep, 1);
    });

    test('step 1 -> 2 (hero -> track)', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(currentStep: 1);
      notifier.next();
      expect(container.read(onboardingNotifierProvider).currentStep, 2);
    });

    test('step 3 -> 4 si levelRequiresPicker=true', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(
        currentStep: 3,
        levelRequiresPicker: true,
      );
      notifier.next();
      expect(container.read(onboardingNotifierProvider).currentStep, 4);
    });

    test('step 3 -> 5 si levelRequiresPicker=false (mode derived)', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(currentStep: 3);
      notifier.next();
      expect(container.read(onboardingNotifierProvider).currentStep, 5);
    });

    test('step 5 -> 7 si userDisplayName non vide (OAuth a fourni)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(
        currentStep: 5,
        userDisplayName: 'Fatou',
      );
      notifier.next();
      expect(container.read(onboardingNotifierProvider).currentStep, 7);
    });

    test('step 5 -> 6 si userDisplayName vide', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(currentStep: 5);
      notifier.next();
      expect(container.read(onboardingNotifierProvider).currentStep, 6);
    });

    test('step 7 -> 9 si isVisitor=true (skip school)', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(currentStep: 7, isVisitor: true);
      notifier.next();
      expect(container.read(onboardingNotifierProvider).currentStep, 9);
    });

    test('step 7 -> 8 si isVisitor=false', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(currentStep: 7);
      notifier.next();
      expect(container.read(onboardingNotifierProvider).currentStep, 8);
    });

    test('step 9 -> 9 (clamp final, no-op)', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(currentStep: 9);
      notifier.next();
      expect(container.read(onboardingNotifierProvider).currentStep, 9);
    });
  });

  // =========================================================================
  // TRANSITIONS back()
  // =========================================================================
  group('OnboardingNotifier — back() conditionnel', () {
    test('step 0 -> 0 (clamp initial, no-op)', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      container.read(onboardingNotifierProvider.notifier).back();
      expect(container.read(onboardingNotifierProvider).currentStep, 0);
    });

    test('step 5 -> 4 si levelRequiresPicker=true', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(
        currentStep: 5,
        levelRequiresPicker: true,
      );
      notifier.back();
      expect(container.read(onboardingNotifierProvider).currentStep, 4);
    });

    test(
        'step 5 -> 3 si levelRequiresPicker=false (symetrie skip step 4 derived)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(currentStep: 5);
      notifier.back();
      expect(container.read(onboardingNotifierProvider).currentStep, 3);
    });

    test('step 7 -> 5 si userDisplayName non vide (symetrie skip step 6)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(
        currentStep: 7,
        userDisplayName: 'Fatou',
      );
      notifier.back();
      expect(container.read(onboardingNotifierProvider).currentStep, 5);
    });

    test('step 9 -> 7 si isVisitor=true (symetrie skip step 8)', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(currentStep: 9, isVisitor: true);
      notifier.back();
      expect(container.read(onboardingNotifierProvider).currentStep, 7);
    });

    test('step 9 -> 8 si isVisitor=false', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(currentStep: 9);
      notifier.back();
      expect(container.read(onboardingNotifierProvider).currentStep, 8);
    });

    test('back ne reset PAS les valeurs amont (preservation pre-remplissage)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(
        currentStep: 7,
        trackId: 'general',
        levelId: 'francophone_terminale',
        streamId: 'francophone_terminale_d',
        levelRequiresPicker: true,
      );
      notifier.back();

      final state = container.read(onboardingNotifierProvider);
      expect(state.currentStep, 6);
      expect(state.trackId, 'general');
      expect(state.levelId, 'francophone_terminale');
      expect(state.streamId, 'francophone_terminale_d');
    });
  });

  // =========================================================================
  // loadFromPersistence
  // =========================================================================
  group('OnboardingNotifier — loadFromPersistence', () {
    test('SharedPreferences vide -> no-op (state initial)', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      await container
          .read(onboardingNotifierProvider.notifier)
          .loadFromPersistence();

      expect(container.read(onboardingNotifierProvider),
          const OnboardingState());
    });

    test('subSystem=francophone persiste -> hydrate + currentStep 1',
        () async {
      final container = await _buildContainer(initial: {
        'onboarding.subsystem': 'francophone',
        'onboarding.language': 'fr',
      });
      addTearDown(container.dispose);

      await container
          .read(onboardingNotifierProvider.notifier)
          .loadFromPersistence();

      final state = container.read(onboardingNotifierProvider);
      expect(state.subSystem, SubSystem.francophone);
      expect(state.currentStep, 1);
    });

    test('subSystem=anglophone persiste -> hydrate', () async {
      final container = await _buildContainer(initial: {
        'onboarding.subsystem': 'anglophone',
        'onboarding.language': 'en',
      });
      addTearDown(container.dispose);

      await container
          .read(onboardingNotifierProvider.notifier)
          .loadFromPersistence();

      final state = container.read(onboardingNotifierProvider);
      expect(state.subSystem, SubSystem.anglophone);
      expect(state.currentStep, 1);
    });
  });
}
