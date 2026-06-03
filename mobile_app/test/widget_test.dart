import 'package:flutter_test/flutter_test.dart';

import 'package:valide_school/main.dart';

void main() {
  testWidgets('ValideApp affiche le titre Valide School', (WidgetTester tester) async {
    await tester.pumpWidget(const ValideApp());

    expect(find.text('Valide School'), findsOneWidget);
  });
}
