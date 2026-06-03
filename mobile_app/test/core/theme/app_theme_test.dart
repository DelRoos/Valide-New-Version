import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valide_school/core/theme/app_theme.dart';
import 'package:valide_school/core/theme/tokens.dart';

void main() {
  testWidgets('buildLightTheme expose primary == AppColors.primary',
      (WidgetTester tester) async {
    Color? capturedPrimary;
    Color? capturedBg;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Builder(
          builder: (context) {
            capturedPrimary = Theme.of(context).colorScheme.primary;
            capturedBg = Theme.of(context).scaffoldBackgroundColor;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(capturedPrimary, equals(AppColors.primary));
    expect(capturedBg, equals(AppColors.bg));
  });
}
