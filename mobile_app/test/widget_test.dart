import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/app.dart';

void main() {
  testWidgets('La route racine redirige vers /hello et affiche "Hello Valide"',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ValideApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello Valide'), findsOneWidget);
  });
}
