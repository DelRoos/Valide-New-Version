import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:valide_school/core/widgets/pedagogical_content.dart';

Future<void> pumpInApp(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: child),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('PedagogicalContent — rendu statique', () {
    testWidgets('Markdown pur : délègue à GptMarkdown sans crash',
        (tester) async {
      await pumpInApp(
        tester,
        const PedagogicalContent(
          data: '# Bonjour\n\nCeci est un paragraphe **gras**.',
        ),
      );
      // Smoke test : le widget délègue à GptMarkdown.
      expect(find.byType(GptMarkdown), findsOneWidget);
    });

    testWidgets('Markdown + LaTeX inline rend sans crash', (tester) async {
      await pumpInApp(
        tester,
        const PedagogicalContent(
          data: 'Formule : \$x^2 + y^2 = z^2\$ dans le texte.',
        ),
      );
      // Validation visuelle des formules LaTeX = golden test (hors P0).
      // Ici : on vérifie juste que le rendu n'a pas levé d'exception.
      expect(find.byType(GptMarkdown), findsOneWidget);
    });
  });

  group('PedagogicalContent.streaming — rendu progressif', () {
    testWidgets('délègue à GptMarkdown via StreamBuilder', (tester) async {
      final controller = StreamController<String>();
      addTearDown(controller.close);

      await pumpInApp(
        tester,
        PedagogicalContent.streaming(stream: controller.stream),
      );

      // StreamBuilder + GptMarkdown (rendu vide initial avec '').
      expect(find.byType(StreamBuilder<String>), findsOneWidget);
      expect(find.byType(GptMarkdown), findsOneWidget);
    });

    testWidgets('met à jour GptMarkdown au fil des chunks', (tester) async {
      final controller = StreamController<String>();
      addTearDown(controller.close);

      await pumpInApp(
        tester,
        PedagogicalContent.streaming(stream: controller.stream),
      );

      controller.add('# Titre');
      await tester.pump(const Duration(milliseconds: 100));
      controller.add('# Titre\n\nContenu');
      await tester.pump(const Duration(milliseconds: 100));

      // gpt_markdown gere les chunks progressivement, rebuild a chaque
      // donnee. Smoke : on verifie juste qu'il reste un GptMarkdown.
      expect(find.byType(GptMarkdown), findsOneWidget);
    });
  });
}
