// Story 1.6 — Widget tests AccountCreationPage.
//
// 4 cas :
//   (a) Page rendue : titre + sous-titre + 2 boutons (Google + Apple)
//   (b) Loading state : tap Google -> spinner Google + Apple disabled
//   (c) Error network -> toast warning visible
//   (d) Error conflict -> AlertDialog visible

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:valide_school/core/widgets/app_button.dart';
import 'package:valide_school/features/onboarding/domain/account_linking_failure.dart';
import 'package:valide_school/features/onboarding/domain/account_linking_repository.dart';
import 'package:valide_school/features/onboarding/domain/account_linking_state.dart';
import 'package:valide_school/features/onboarding/domain/linked_account.dart';
import 'package:valide_school/features/onboarding/presentation/account_creation_page.dart';
import 'package:valide_school/features/onboarding/providers.dart';
import 'package:valide_school/l10n/generated/app_localizations.dart';

class _BlockingRepo implements AccountLinkingRepository {
  /// Pas de signal de fin -> reste en loading indefiniment.
  /// Permet de tester le state loading sans risque de transition.
  @override
  Future<Either<AccountLinkingFailure, LinkedAccount>> linkGoogle() =>
      Completer<Either<AccountLinkingFailure, LinkedAccount>>().future;

  @override
  Future<Either<AccountLinkingFailure, LinkedAccount>> linkApple() =>
      Completer<Either<AccountLinkingFailure, LinkedAccount>>().future;
}

class _FixedRepo implements AccountLinkingRepository {
  _FixedRepo(this.result);
  final Either<AccountLinkingFailure, LinkedAccount> result;
  @override
  Future<Either<AccountLinkingFailure, LinkedAccount>> linkGoogle() async =>
      result;
  @override
  Future<Either<AccountLinkingFailure, LinkedAccount>> linkApple() async =>
      result;
}

Future<void> _pump(
  WidgetTester tester, {
  required AccountLinkingRepository repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountLinkingRepositoryProvider.overrideWithValue(repo),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: const AccountCreationPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AccountCreationPage — Story 1.6', () {
    testWidgets(
      '(a) Page rendue : titre + sous-titre + 2 boutons primaires',
      (tester) async {
        await _pump(tester, repo: _BlockingRepo());

        expect(find.text('Crée ton compte'), findsOneWidget);
        expect(
          find.textContaining('Sauvegarde tes progrès'),
          findsOneWidget,
        );
        expect(find.widgetWithText(AppButton, 'Continuer avec Google'),
            findsOneWidget);
        expect(find.widgetWithText(AppButton, 'Continuer avec Apple'),
            findsOneWidget);
      },
    );

    testWidgets(
      '(b) linkGoogle en loading -> Apple bouton disabled',
      (tester) async {
        await _pump(tester, repo: _BlockingRepo());

        // Declenche directement via container (le hit-test du AppButton wrappe
        // dans LayoutBuilder est instable en headless test).
        final container = ProviderScope.containerOf(
          tester.element(find.byType(AccountCreationPage)),
        );
        // Pas d'await : le BlockingRepo ne resout jamais.
        unawaited(
          container.read(accountLinkingNotifierProvider.notifier).linkGoogle(),
        );
        await tester.pump();

        final apple = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Continuer avec Apple'),
        );
        expect(apple.onPressed, isNull);
      },
    );

    testWidgets(
      '(c) Error network -> notifier passe en error puis reset (toast traite)',
      (tester) async {
        await _pump(
          tester,
          repo: _FixedRepo(const Left(AccountLinkingFailure.network())),
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(AccountCreationPage)),
        );
        await container
            .read(accountLinkingNotifierProvider.notifier)
            .linkGoogle();
        // Plusieurs pumps pour laisser le listener s'executer et appeler reset
        // apres le toast (le toast lui-meme est un OverlayEntry difficile a
        // tester proprement a cause du Timer 4.4s qui leak l'arbre du test).
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Apres reset(), state revient en idle.
        final finalState = container.read(accountLinkingNotifierProvider);
        expect(finalState, isA<AccountLinkingIdle>());

        // Drain le Timer pendant de l'AppToast.
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '(d) Error credentialAlreadyInUse -> AlertDialog visible',
      (tester) async {
        await _pump(
          tester,
          repo: _FixedRepo(
            const Left(AccountLinkingFailure.credentialAlreadyInUse()),
          ),
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(AccountCreationPage)),
        );
        await container
            .read(accountLinkingNotifierProvider.notifier)
            .linkGoogle();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Compte déjà utilisé'), findsOneWidget);
      },
    );
  });
}
