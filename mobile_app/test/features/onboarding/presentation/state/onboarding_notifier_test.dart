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

  group('OnboardingNotifier — setTrackIdDraft (audit 2026-06-13)', () {
    test('pose le trackId SANS transition (currentStep reste 2)', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardingNotifierProvider.notifier);
      // On part de step 2 (apres hero intro).
      notifier.next(); // 0 -> 1
      notifier.next(); // 1 -> 2
      expect(container.read(onboardingNotifierProvider).currentStep, 2);

      notifier.setTrackIdDraft('general');

      final state = container.read(onboardingNotifierProvider);
      expect(state.trackId, 'general',
          reason: 'draft doit poser le trackId');
      expect(state.currentStep, 2,
          reason: 'draft NE TRANSITIONNE PAS (l\'utilisateur valide via CTA)');
    });

    test('reset downstream meme en draft (level/stream/picked)', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardingNotifierProvider.notifier);
      // Simule un etat aval pollue (level + stream + matieres choisies).
      notifier.setTrackId('general'); // step -> 3
      notifier.setLevelId('francophone_terminale', requiresPicker: true);
      notifier.setStreamAndSubjects(
        streamId: 'francophone_terminale_d',
        pickedSubjects: const ['math', 'physics'],
      );

      // L'utilisateur revient au step 2 et change d'avis pour technique.
      notifier.setTrackIdDraft('technique');

      final state = container.read(onboardingNotifierProvider);
      expect(state.trackId, 'technique');
      expect(state.levelId, isNull, reason: 'level invalide par track switch');
      expect(state.streamId, isNull);
      expect(state.pickedSubjects, isEmpty);
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

    test('requiresPicker=false (mode derived) -> currentStep 4 (recap toujours)',
        () async {
      // audit 2026-06-14 — toutes les classes passent par step 4 (recap);
      // le skip step 4 pour les niveaux derived a ete supprime.
      final container = await _buildContainer();
      addTearDown(container.dispose);

      container
          .read(onboardingNotifierProvider.notifier)
          .setLevelId('francophone_6e', requiresPicker: false);

      final state = container.read(onboardingNotifierProvider);
      expect(state.levelId, 'francophone_6e');
      expect(state.levelRequiresPicker, isFalse);
      expect(state.currentStep, 4);
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
    test(
        'OAuth Google avec displayName + profil rempli -> step 6 (pre-fill)',
        () async {
      // Audit 2026-06-13 (PR3) + fix: setAuthProvider va au step 6 seulement
      // si trackId est pose (profil scolaire deja rempli, ex. jumpToAuth
      // depuis step 1 APRES steps 2-4). Sans trackId (jumpToAuth avant steps
      // 2-4) -> step 2 pour reprendre le flow normal.
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(
        currentStep: 5,
        trackId: 'general',
        levelId: 'francophone_terminale',
        streamId: 'francophone_terminale_d',
      );

      notifier.setAuthProvider(
        OnboardingAuthProvider.google,
        displayName: 'Fatou Mballa',
      );

      final state = container.read(onboardingNotifierProvider);
      expect(state.authProvider, OnboardingAuthProvider.google);
      expect(state.userDisplayName, 'Fatou Mballa');
      expect(state.isVisitor, isFalse);
      expect(state.currentStep, 6);
    });

    test('OAuth Apple sans displayName + profil rempli -> step 6 (saisie)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(
        currentStep: 5,
        trackId: 'general',
        levelId: 'francophone_terminale',
        streamId: 'francophone_terminale_d',
      );

      notifier.setAuthProvider(OnboardingAuthProvider.apple);

      final state = container.read(onboardingNotifierProvider);
      expect(state.authProvider, OnboardingAuthProvider.apple);
      expect(state.userDisplayName, isNull);
      expect(state.isVisitor, isFalse);
      expect(state.currentStep, 6);
    });

    test(
        'Visiteur (guest) -> isVisitor=true + currentStep inchange '
        '(AuthChoiceStepBody nav direct /dashboard, pas de page success)',
        () async {
      // Decision produit 2026-06-13 : visiteur saute nom + telephone + ecole
      // ET la page success. AuthChoiceStepBody fait flush + nav directement.
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(currentStep: 5);

      notifier.setAuthProvider(OnboardingAuthProvider.guest);

      final state = container.read(onboardingNotifierProvider);
      expect(state.authProvider, OnboardingAuthProvider.guest);
      expect(state.isVisitor, isTrue);
      expect(state.currentStep, 5);
    });

    test('OAuth avec displayName vide + profil rempli -> step 6 (saisie)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(
        currentStep: 5,
        trackId: 'general',
        levelId: 'francophone_terminale',
        streamId: 'francophone_terminale_d',
      );

      notifier.setAuthProvider(OnboardingAuthProvider.google, displayName: '');

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

    test(
        'step 3 -> 4 toujours (audit 2026-06-14 : tous les niveaux passent '
        'par le recap step 4, plus de skip mode derived)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(currentStep: 3);
      notifier.next();
      expect(container.read(onboardingNotifierProvider).currentStep, 4);
    });

    test(
        'step 5 -> 6 toujours (audit PR3 : edition displayName toujours autorisee)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(
        currentStep: 5,
        userDisplayName: 'Fatou',
      );
      notifier.next();
      expect(container.read(onboardingNotifierProvider).currentStep, 6);
    });

    test('step 5 -> 6 si userDisplayName vide', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(currentStep: 5);
      notifier.next();
      expect(container.read(onboardingNotifierProvider).currentStep, 6);
    });

    test('step 7 -> 8 (chemin lineaire compte permanent)', () async {
      // Visiteur n'utilise pas next() apres step 5 : AuthChoiceStepBody nav
      // direct /dashboard. Seul le compte permanent passe par step 7 -> 8.
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

    test('step 5 -> 4 si trackId pose (retour recap picker)', () async {
      // fix: back() depuis step 5 va a step 4 seulement si trackId est pose.
      // Sans trackId (jumpToAuth) -> step 1. On set trackId pour tester
      // le cas "retour recap matieres" du flow normal.
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(
        currentStep: 5,
        trackId: 'general',
        levelRequiresPicker: true,
      );
      notifier.back();
      expect(container.read(onboardingNotifierProvider).currentStep, 4);
    });

    test(
        'step 5 -> 4 si trackId pose, meme mode derived (audit 2026-06-14)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(
        currentStep: 5,
        trackId: 'general',
      );
      notifier.back();
      expect(container.read(onboardingNotifierProvider).currentStep, 4);
    });

    test('step 7 -> 6 toujours (audit PR3 : pas de skip step 6 OAuth)',
        () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.state = const OnboardingState(
        currentStep: 7,
        userDisplayName: 'Fatou',
      );
      notifier.back();
      expect(container.read(onboardingNotifierProvider).currentStep, 6);
    });

    test('step 9 -> 8 (visiteur n arrive jamais au step 9)', () async {
      // Visiteur n'arrive jamais a step 9 (nav direct dashboard depuis
      // AuthChoiceStepBody). Seul le compte permanent fait back 9 -> 8.
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

    test(
        'audit PR1 — draft persiste (trackId + levelId + currentStep) -> restaure complet',
        () async {
      // Simule un user qui kill l'app apres step 3 (level pose, step=4 si
      // requiresPicker). Au relaunch, il doit reprendre exactement la.
      const draftJson =
          '{"currentStep":4,"trackId":"general","levelId":"francophone_terminale",'
          '"levelRequiresPicker":true,"streamId":null,"pickedSubjects":[],'
          '"userDisplayName":null,"schoolId":null,"schoolName":null,'
          '"pendingSchoolRequestId":null,"schoolSkipped":false,"phoneSkipped":false,'
          '"isVisitor":false,"authProvider":null}';
      final container = await _buildContainer(initial: {
        'onboarding.subsystem': 'francophone',
        'onboarding.language': 'fr',
        'onboarding.draft': draftJson,
      });
      addTearDown(container.dispose);

      await container
          .read(onboardingNotifierProvider.notifier)
          .loadFromPersistence();

      final state = container.read(onboardingNotifierProvider);
      expect(state.subSystem, SubSystem.francophone);
      expect(state.trackId, 'general');
      expect(state.levelId, 'francophone_terminale');
      expect(state.levelRequiresPicker, isTrue);
      expect(state.currentStep, 4);
      expect(state.pickedSubjects, isEmpty);
    });

    test('draft corrompu (JSON invalide) -> fallback no-op safe', () async {
      final container = await _buildContainer(initial: {
        'onboarding.subsystem': 'francophone',
        'onboarding.draft': '{not-json}',
      });
      addTearDown(container.dispose);

      await container
          .read(onboardingNotifierProvider.notifier)
          .loadFromPersistence();

      final state = container.read(onboardingNotifierProvider);
      // Fallback : subSystem restaure, currentStep=1 (comportement pre-PR1).
      expect(state.subSystem, SubSystem.francophone);
      expect(state.currentStep, 1);
    });

    test('setters persistent automatiquement le draft', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.setTrackId('general');
      notifier.setLevelId('francophone_terminale', requiresPicker: true);

      // Laisser le fire-and-forget completer.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('onboarding.draft');
      expect(raw, isNotNull);
      expect(raw, contains('"trackId":"general"'));
      expect(raw, contains('"levelId":"francophone_terminale"'));
    });

    test('clearPersistedDraft efface le draft (utilise post-flush success)',
        () async {
      final container = await _buildContainer(initial: {
        'onboarding.draft': '{"currentStep":4,"trackId":"general"}',
      });
      addTearDown(container.dispose);

      await container
          .read(onboardingNotifierProvider.notifier)
          .clearPersistedDraft();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('onboarding.draft'), isNull);
    });
  });
}
