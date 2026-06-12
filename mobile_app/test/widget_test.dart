// Story 1.9 — apres migration `/hello` -> `/dashboard`, ces 2 tests verifient
// que la bascule i18n (FR vs EN) s'applique au DashboardPage atteint post-splash.
// Le group « HelloPage responsive — sentinelle E0 » a ete retire : la sentinelle
// Story 0.21 a deja servi son but, HelloPage reste accessible via /hello pour
// debug mais n'est plus la cible production du splash.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/app.dart';
import 'package:valide_school/core/catalogue/domain/catalogue_failure.dart';
import 'package:valide_school/core/config/feature_flags.dart';
import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/core/firebase/providers.dart';
import 'package:valide_school/features/onboarding/domain/profile_completion_state.dart';
import 'package:valide_school/features/onboarding/providers.dart';

import '_helpers/fakes.dart';

// Story 0.22 — splash anime 1800 ms + 300 ms hold. Tests ciblant la page metier
// post-splash doivent attendre la transition (marge securite : 2200 ms).
const Duration _kSplashSettleDuration = Duration(milliseconds: 2200);

Future<void> _settleSplashToDashboard(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_kSplashSettleDuration);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<SharedPreferences> _prefsWith({
  required String subSystem,
  required String language,
}) async {
  SharedPreferences.setMockInitialValues({
    'onboarding.subsystem': subSystem,
    'onboarding.language': language,
  });
  return SharedPreferences.getInstance();
}

void main() {
  testWidgets(
    'Locale FR par defaut : DashboardPage affiche "Bienvenue !" post-splash',
    (WidgetTester tester) async {
      final prefs =
          await _prefsWith(subSystem: 'francophone', language: 'fr');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            featureFlagsProvider.overrideWithValue(
              const FeatureFlags(useNewOnboardingFlow: false),
            ),
            appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
            profileCompletionProvider.overrideWith(
              (ref) => Stream.value(ProfileCompletionState.complete),
            ),
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
      await _settleSplashToDashboard(tester);

      expect(find.text('Bienvenue !'), findsOneWidget);
      expect(find.text('Welcome!'), findsNothing);
    },
  );

  testWidgets(
    'Locale EN derivee de subSystem anglophone : DashboardPage affiche "Welcome!"',
    (WidgetTester tester) async {
      final prefs =
          await _prefsWith(subSystem: 'anglophone', language: 'en');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            featureFlagsProvider.overrideWithValue(
              const FeatureFlags(useNewOnboardingFlow: false),
            ),
            appStartupCatalogueCheckProvider.overrideWith((ref) async => true),
            profileCompletionProvider.overrideWith(
              (ref) => Stream.value(ProfileCompletionState.complete),
            ),
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
      await _settleSplashToDashboard(tester);

      expect(find.text('Welcome!'), findsOneWidget);
      expect(find.text('Bienvenue !'), findsNothing);
    },
  );
}
