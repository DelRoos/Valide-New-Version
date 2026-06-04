import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/app.dart';

void main() {
  testWidgets(
    'Locale FR par défaut : affiche « Bonjour Valide »',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: ValideApp()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Bonjour Valide'), findsOneWidget);
      expect(find.text('Hello Valide'), findsNothing);
    },
  );

  testWidgets(
    'Locale EN forcée : affiche « Hello Valide »',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith(() => _EnglishLocaleNotifier()),
          ],
          child: const ValideApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Hello Valide'), findsOneWidget);
      expect(find.text('Bonjour Valide'), findsNothing);
    },
  );
}

class _EnglishLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('en');
}
