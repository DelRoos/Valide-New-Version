// Story 1.2 — tests widget SubsystemChoicePage.
//
// 4 scenarios couvrent les AC1-AC5 :
//   1. Splash + subSystem absent -> navigation vers /onboarding/subsystem
//   2. Tap Anglophone -> modale de confirmation s'affiche
//   3. Tap Continuer -> persistance SharedPreferences + bascule locale EN
//   4. Garde first-launch : subSystem present -> redirect / quand on tente d'y aller

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/app.dart';
import 'package:valide_school/core/catalogue/domain/catalogue_failure.dart';
import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/core/firebase/providers.dart';
import 'package:valide_school/features/onboarding/domain/profile_completion_state.dart';
import 'package:valide_school/features/onboarding/providers.dart';

import '../../../_helpers/fakes.dart';

// Story 0.22 — splash anime 2100 ms avant nav.
const Duration _kSplashSettleDuration = Duration(milliseconds: 2200);

Future<void> _settleSplash(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_kSplashSettleDuration);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<SharedPreferences> _preparePrefs(
  Map<String, Object> initialValues,
) async {
  SharedPreferences.setMockInitialValues(initialValues);
  return SharedPreferences.getInstance();
}

void main() {
  group('SubsystemChoicePage — Story 1.2', () {
    testWidgets(
      'AC1 — subSystem absent : splash navigue vers /onboarding/subsystem',
      (tester) async {
        final prefs = await _preparePrefs({});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
              // Story 1.5 — bypass garde profil-incomplet (Firebase indispo en test).
              profileCompletionProvider.overrideWith(
                (ref) => Stream.value(ProfileCompletionState.complete),
              ),
            ],
            child: const ValideApp(),
          ),
        );
        await _settleSplash(tester);

        // Page de choix affichee : titre FR + 2 boutons.
        expect(find.text('Choisis ta langue et ton programme'), findsOneWidget);
        expect(find.text('Tu ne pourras pas changer après.'), findsOneWidget);
        expect(find.text('Francophone'), findsOneWidget);
        expect(find.text('Anglophone'), findsOneWidget);
      },
    );

    testWidgets(
      'AC3 — tap Anglophone : modale de confirmation s\'affiche',
      (tester) async {
        final prefs = await _preparePrefs({});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
              // Story 1.5 — bypass garde profil-incomplet (Firebase indispo en test).
              profileCompletionProvider.overrideWith(
                (ref) => Stream.value(ProfileCompletionState.complete),
              ),
            ],
            child: const ValideApp(),
          ),
        );
        await _settleSplash(tester);

        await tester.tap(find.text('Anglophone'));
        await tester.pumpAndSettle();

        // Modale : titre + body + 2 boutons (Annuler secondary + Continuer primary).
        expect(find.text('Confirmer ton choix'), findsOneWidget);
        expect(
          find.text(
            'Ce choix fixe la langue et le programme. Tu ne pourras pas changer après.',
          ),
          findsOneWidget,
        );
        expect(find.text('Annuler'), findsOneWidget);
        expect(find.text('Continuer'), findsOneWidget);
      },
    );

    testWidgets(
      'AC3 — tap Continuer : persiste subSystem + ferme la modale',
      (tester) async {
        final prefs = await _preparePrefs({});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
              profileCompletionProvider.overrideWith(
                (ref) => Stream.value(ProfileCompletionState.complete),
              ),
              // Story 1.9 — tap Continuer navigue vers /dashboard qui requiert
              // firebaseAuth + repo + derived overrides (sinon FirebaseAuth crash).
              firebaseAuthProvider.overrideWithValue(
                FakeAuth(isAnonymous: false, displayName: null),
              ),
              userProfileRepositoryProvider.overrideWithValue(
                FakeUserProfileRepository(profileData: null),
              ),
              derivedProfileProvider.overrideWith(
                (ref) async => Left(
                  CatalogueFailure.noMatchingRule(
                    subSystem: 'anglophone',
                    filiere: 'generale',
                    niveau: 'anglophone_upper_sixth',
                    serie: null,
                  ),
                ),
              ),
              effectiveDerivedSubjectsProvider.overrideWith(
                (ref) => const Stream<List<Subject>>.empty(),
              ),
            ],
            child: const ValideApp(),
          ),
        );
        await _settleSplash(tester);

        // Tap Anglophone puis Continuer.
        await tester.tap(find.text('Anglophone'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continuer'));
        // Pump quelques frames pour propager la fermeture modale + set state.
        // On evite pumpAndSettle qui boucle sur l'anim splash relance.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Effet metier : persistance SharedPreferences ecrite.
        expect(prefs.getString('onboarding.subsystem'), 'anglophone');
        expect(prefs.getString('onboarding.language'), 'en');

        // La modale n'est plus a l'ecran.
        expect(find.text('Confirmer ton choix'), findsNothing);
      },
    );

    testWidgets(
      'AC5 — garde first-launch : subSystem present, splash va direct /dashboard',
      (tester) async {
        // Simule un user francophone qui a deja choisi son sous-systeme.
        final prefs = await _preparePrefs({
          'onboarding.subsystem': 'francophone',
          'onboarding.language': 'fr',
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
              profileCompletionProvider.overrideWith(
                (ref) => Stream.value(ProfileCompletionState.complete),
              ),
              // Story 1.9 — DashboardPage requiert Firebase + repo + derived.
              firebaseAuthProvider.overrideWithValue(
                FakeAuth(isAnonymous: false, displayName: null),
              ),
              userProfileRepositoryProvider.overrideWithValue(
                FakeUserProfileRepository(profileData: null),
              ),
              derivedProfileProvider.overrideWith(
                (ref) async => Left(
                  CatalogueFailure.noMatchingRule(
                    subSystem: 'francophone',
                    filiere: 'generale',
                    niveau: 'francophone_terminale',
                    serie: null,
                  ),
                ),
              ),
              effectiveDerivedSubjectsProvider.overrideWith(
                (ref) => const Stream<List<Subject>>.empty(),
              ),
            ],
            child: const ValideApp(),
          ),
        );
        await _settleSplash(tester);

        // Page de choix n'est PAS affichee -> on est direct sur /dashboard en FR.
        expect(find.text('Choisis ta langue et ton programme'), findsNothing);
        expect(find.text('Bienvenue !'), findsOneWidget);
      },
    );
  });
}
