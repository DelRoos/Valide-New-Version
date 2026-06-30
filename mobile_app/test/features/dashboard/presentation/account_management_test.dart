// Matrice de scénarios gestion de compte — Story A.2.
//
// Groupes :
//   V (visiteur / anonyme) : V1–V7
//   A (authentifié)        : A1–A9
//
// Convention de pump : pumpWidget → pump() → pump(300ms).
// Le 1er pump laisse le stream auth s'installer (microtask).
// Le 2e pump déclenche les post-frame callbacks et les animations de dialog.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valide_school/core/catalogue/providers.dart';
import 'package:valide_school/core/firebase/providers.dart';
import 'package:valide_school/features/account/domain/account_deletion_failure.dart';
import 'package:valide_school/features/account/domain/account_deletion_status.dart';
import 'package:valide_school/features/account/providers.dart';
import 'package:valide_school/features/dashboard/presentation/profile_tab_page.dart';
import 'package:valide_school/features/dashboard/presentation/widgets/complete_profile_dialog.dart';
import 'package:valide_school/features/dashboard/presentation/widgets/profile_account_section.dart';
import 'package:valide_school/features/onboarding/domain/account_linking_state.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/presentation/state/onboarding_notifier.dart';
import 'package:valide_school/features/onboarding/presentation/state/onboarding_providers.dart';
import 'package:valide_school/features/onboarding/presentation/state/onboarding_state.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

import '../../../_helpers/fakes.dart';

// ─── Stubs & Fakes ────────────────────────────────────────────────────────────

/// FakeAuth avec tracking de l'appel signOut().
class _TrackingFakeAuth extends FakeAuth {
  _TrackingFakeAuth({super.isAnonymous, super.displayName});

  bool signOutCalled = false;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

class _StubSubSystemNotifier extends SubSystemNotifier {
  _StubSubSystemNotifier(this._initial);
  final SubSystem? _initial;
  @override
  SubSystem? build() => _initial;
}

/// Stub AccountLinkingNotifier — reste idle, ne touche pas Firebase.
class _StubAccountLinkingNotifier extends AccountLinkingNotifier {
  @override
  AccountLinkingState build() => const AccountLinkingState.idle();

  @override
  Future<void> linkGoogle() async {}

  @override
  Future<void> linkApple() async {}
}

/// Stub OnboardingNotifier — reset() sans SharedPreferences.
class _StubOnboardingNotifier extends OnboardingNotifier {
  @override
  OnboardingState build() => const OnboardingState();

  @override
  void reset() => state = const OnboardingState();
}

/// Stub AccountDeletionStatusNotifier.
/// [onDeleteNow] : callback appelé quand deleteNow() est invoqué.
/// [failureOnDelete] : si non-null, émet l'erreur au lieu de rester idle.
class _StubAccountDeletionNotifier extends AccountDeletionStatusNotifier {
  _StubAccountDeletionNotifier({this.onDeleteNow, this.failureOnDelete});

  final VoidCallback? onDeleteNow;
  final AccountDeletionFailure? failureOnDelete;

  @override
  AccountDeletionStatus build() => const AccountDeletionStatus.idle();

  @override
  Future<void> deleteNow() async {
    onDeleteNow?.call();
    if (failureOnDelete != null) {
      state = AccountDeletionStatus.error(failureOnDelete!);
    }
    // Si pas d'erreur : reste idle — évite GoRouter.of(context).go('/')
    // non disponible dans cet arbre de test sans GoRouter.
  }

  @override
  Future<void> requestDeletion() async {}

  @override
  Future<void> cancelDeletion() async {}
}

// ─── Données de profil ────────────────────────────────────────────────────────

final _fakeProfileData = <String, dynamic>{
  'displayName': 'Fatou',
  'phoneNumber': '+237671234567',
  'pickedSubjects': <String>[],
  'examTargets': <String>[],
  'levelId': null,
  'streamId': null,
  'schoolId': null,
  'schoolName': null,
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Construit l'arbre de test complet autour de [child].
///
/// [isAnonymous] : simule un visiteur (true) ou un compte permanent (false).
/// [trackingAuth] : si fourni, utilisé à la place de FakeAuth (pour tracker signOut).
/// [deletionOnDeleteNow] : callback invoqué quand deleteNow() est appelé.
/// [deletionFailure] : si non-null, deleteNow() émet cette erreur.
Widget _wrap(
  Widget child, {
  bool isAnonymous = false,
  _TrackingFakeAuth? trackingAuth,
  VoidCallback? deletionOnDeleteNow,
  AccountDeletionFailure? deletionFailure,
}) {
  SharedPreferences.setMockInitialValues({});
  final auth =
      trackingAuth ?? FakeAuth(isAnonymous: isAnonymous, displayName: 'Fatou');

  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(auth),
      currentUserProvider.overrideWith(
        (ref) => Stream.value(auth.currentUser),
      ),
      userProfileRepositoryProvider.overrideWithValue(
        FakeUserProfileRepository(profileData: _fakeProfileData),
      ),
      catalogueProvider.overrideWith(
        (ref) async => throw UnimplementedError('catalogue not used'),
      ),
      subSystemNotifierProvider.overrideWith(
        () => _StubSubSystemNotifier(null),
      ),
      onboardingNotifierProvider.overrideWith(
        () => _StubOnboardingNotifier(),
      ),
      accountLinkingNotifierProvider.overrideWith(
        () => _StubAccountLinkingNotifier(),
      ),
      accountDeletionStatusNotifierProvider.overrideWith(
        () => _StubAccountDeletionNotifier(
          onDeleteNow: deletionOnDeleteNow,
          failureOnDelete: deletionFailure,
        ),
      ),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0),
          ),
          child: child!,
        ),
        home: child,
      ),
    ),
  );
}

/// Pump standard : 3 étapes suffisent pour laisser le stream auth s'installer
/// et les post-frame callbacks (showDialog) s'exécuter.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 300));
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // Dimensionner la vue de test pour que tout le contenu soit visible.
  setUp(() {
    // Réinitialiser la vue par défaut entre les tests.
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUPE V — Visiteur (utilisateur anonyme)
  // ──────────────────────────────────────────────────────────────────────────

  group('V — Visiteur (anonyme)', () {
    testWidgets(
      'V1 : CompleteProfileDialog s\'affiche automatiquement sur la tab Profil',
      (tester) async {
        tester.view.physicalSize = const Size(375, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(const ProfileTabPage(), isAnonymous: true),
        );
        await _settle(tester);

        expect(find.byType(CompleteProfileDialog), findsOneWidget);
      },
    );

    testWidgets(
      'V2 : CompleteProfileDialog est dismissible via le bouton ✕',
      (tester) async {
        tester.view.physicalSize = const Size(375, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(const ProfileTabPage(), isAnonymous: true),
        );
        await _settle(tester);

        // Dialog présent
        expect(find.byType(CompleteProfileDialog), findsOneWidget);

        // Tapper le bouton ✕
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Dialog fermé
        expect(find.byType(CompleteProfileDialog), findsNothing);
      },
    );

    testWidgets(
      'V4 : bouton "Modifier" → CompleteProfileDialog (pas ProfileEditSheet)',
      (tester) async {
        tester.view.physicalSize = const Size(375, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(const ProfileTabPage(), isAnonymous: true),
        );
        await _settle(tester);

        // Fermer le dialog auto-show pour tester "Modifier"
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Tapper "Modifier"
        await tester.tap(find.text('Modifier'));
        await tester.pumpAndSettle();

        // CompleteProfileDialog doit réapparaître (pas un sheet d'édition)
        expect(find.byType(CompleteProfileDialog), findsOneWidget);
      },
    );

    testWidgets(
      'V5 : "Mon école" → CompleteProfileDialog (pas SchoolEditSheet)',
      (tester) async {
        tester.view.physicalSize = const Size(375, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(const ProfileTabPage(), isAnonymous: true),
        );
        await _settle(tester);

        // Fermer le dialog auto-show
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Tapper "Mon école"
        await tester.tap(find.text('Mon école'));
        await tester.pumpAndSettle();

        expect(find.byType(CompleteProfileDialog), findsOneWidget);
      },
    );

    testWidgets(
      'V6 : "Se déconnecter" → CompleteProfileDialog (signOut non appelé)',
      (tester) async {
        tester.view.physicalSize = const Size(375, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final auth = _TrackingFakeAuth(isAnonymous: true, displayName: 'Fatou');

        await tester.pumpWidget(
          _wrap(const ProfileTabPage(), trackingAuth: auth),
        );
        await _settle(tester);

        // Fermer le dialog auto-show
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Tapper "Se déconnecter"
        await tester.tap(find.text('Se déconnecter'));
        await tester.pumpAndSettle();

        // Dialog présent → signOut non appelé
        expect(find.byType(CompleteProfileDialog), findsOneWidget);
        expect(auth.signOutCalled, isFalse);
      },
    );

    testWidgets(
      'V7 : bouton "Supprimer mon compte" absent pour les utilisateurs anonymes',
      (tester) async {
        tester.view.physicalSize = const Size(375, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(
            const Scaffold(body: SingleChildScrollView(child: ProfileAccountSection())),
            isAnonymous: true,
          ),
        );
        await _settle(tester);

        expect(find.text('Supprimer mon compte'), findsNothing);
      },
    );
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUPE A — Authentifié
  // ──────────────────────────────────────────────────────────────────────────

  group('A — Authentifié', () {
    testWidgets(
      'A1 : aucun CompleteProfileDialog auto-show pour un utilisateur connecté',
      (tester) async {
        tester.view.physicalSize = const Size(375, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(const ProfileTabPage(), isAnonymous: false),
        );
        await _settle(tester);

        expect(find.byType(CompleteProfileDialog), findsNothing);
      },
    );

    testWidgets(
      'A4 : bouton "Supprimer mon compte" présent pour les utilisateurs authentifiés',
      (tester) async {
        tester.view.physicalSize = const Size(375, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(
            const Scaffold(body: SingleChildScrollView(child: ProfileAccountSection())),
            isAnonymous: false,
          ),
        );
        await _settle(tester);

        expect(find.text('Supprimer mon compte'), findsOneWidget);
      },
    );

    testWidgets(
      'A5 : "Se déconnecter" → dialog de confirmation → confirmer → signOut() appelé',
      (tester) async {
        tester.view.physicalSize = const Size(375, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final auth =
            _TrackingFakeAuth(isAnonymous: false, displayName: 'Fatou');

        await tester.pumpWidget(
          _wrap(const ProfileTabPage(), trackingAuth: auth),
        );
        await _settle(tester);

        // Aucun CompleteProfileDialog auto-show
        expect(find.byType(CompleteProfileDialog), findsNothing);

        // Tapper "Se déconnecter" → dialog de confirmation
        await tester.tap(find.text('Se déconnecter'));
        await tester.pumpAndSettle();

        // Le dialog de confirmation apparaît, signOut pas encore appelé
        expect(find.text('Se déconnecter ?'), findsOneWidget);
        expect(auth.signOutCalled, isFalse);

        // Confirmer dans le dialog
        await tester.tap(find.text('Confirmer la déconnexion'));
        await tester.pumpAndSettle();

        // signOut appelé
        expect(auth.signOutCalled, isTrue);
      },
    );

    testWidgets(
      'A6 : supprimer → dialog de confirmation → confirmer → deleteNow() appelé',
      (tester) async {
        tester.view.physicalSize = const Size(375, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        var deleteNowCalled = false;

        await tester.pumpWidget(
          _wrap(
            const Scaffold(body: SingleChildScrollView(child: ProfileAccountSection())),
            isAnonymous: false,
            deletionOnDeleteNow: () => deleteNowCalled = true,
          ),
        );
        await _settle(tester);

        // Tapper "Supprimer mon compte"
        await tester.tap(find.text('Supprimer mon compte'));
        await tester.pumpAndSettle();

        // Dialog de confirmation présent
        expect(find.text('Es-tu sûr ?'), findsOneWidget);

        // Confirmer la suppression
        await tester.tap(find.text('Confirmer la suppression'));
        await tester.pump();

        expect(deleteNowCalled, isTrue);
      },
    );

    testWidgets(
      'A7 : supprimer → dialog de confirmation → annuler → dialog fermé, deleteNow() non appelé',
      (tester) async {
        tester.view.physicalSize = const Size(375, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        var deleteNowCalled = false;

        await tester.pumpWidget(
          _wrap(
            const Scaffold(body: SingleChildScrollView(child: ProfileAccountSection())),
            isAnonymous: false,
            deletionOnDeleteNow: () => deleteNowCalled = true,
          ),
        );
        await _settle(tester);

        // Ouvrir dialog de confirmation
        await tester.tap(find.text('Supprimer mon compte'));
        await tester.pumpAndSettle();
        expect(find.text('Es-tu sûr ?'), findsOneWidget);

        // Annuler
        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();

        // Dialog fermé, deleteNow non appelé
        expect(find.text('Es-tu sûr ?'), findsNothing);
        expect(deleteNowCalled, isFalse);
      },
    );

    testWidgets(
      'A8 : deleteNow() → erreur réseau → toast "Pas de connexion"',
      (tester) async {
        tester.view.physicalSize = const Size(375, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(
            const Scaffold(body: SingleChildScrollView(child: ProfileAccountSection())),
            isAnonymous: false,
            deletionFailure: const AccountDeletionFailure.network(),
          ),
        );
        await _settle(tester);

        // Ouvrir et confirmer
        await tester.tap(find.text('Supprimer mon compte'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirmer la suppression'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Toast erreur réseau visible
        expect(find.textContaining('Pas de connexion'), findsOneWidget);

        // Drainer le timer AppToast (4.4 s fake time) pour éviter qu'il
        // persiste après la fin du test et pollue le test suivant.
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'A9 : deleteNow() → requires-recent-login → toast "Session expirée"',
      (tester) async {
        tester.view.physicalSize = const Size(375, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(
            const Scaffold(body: SingleChildScrollView(child: ProfileAccountSection())),
            isAnonymous: false,
            deletionFailure: const AccountDeletionFailure.requiresRecentLogin(),
          ),
        );
        await _settle(tester);

        // Ouvrir et confirmer
        await tester.tap(find.text('Supprimer mon compte'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirmer la suppression'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Toast session expirée
        expect(find.textContaining('Session expirée'), findsOneWidget);

        // Drainer le timer AppToast
        await tester.pump(const Duration(seconds: 5));
      },
    );
  });
}
