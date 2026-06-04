import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
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
    testWidgets('Markdown pur : délègue à SmoothMarkdown sans crash',
        (tester) async {
      await pumpInApp(
        tester,
        const PedagogicalContent(
          data: '# Bonjour\n\nCeci est un paragraphe **gras**.',
        ),
      );
      // Smoke test : le widget délègue à SmoothMarkdown.
      expect(find.byType(SmoothMarkdown), findsOneWidget);
      expect(find.byType(StreamMarkdown), findsNothing);
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
      expect(find.byType(SmoothMarkdown), findsOneWidget);
    });

    testWidgets('selectable=false par défaut', (tester) async {
      await pumpInApp(
        tester,
        const PedagogicalContent(data: 'Simple texte.'),
      );
      // Pas de SelectionArea quand selectable=false.
      expect(find.byType(SelectionArea), findsNothing);
    });
  });

  group('PedagogicalContent.streaming — rendu progressif', () {
    testWidgets('délègue à StreamMarkdown', (tester) async {
      final controller = StreamController<String>();
      addTearDown(controller.close);

      await pumpInApp(
        tester,
        PedagogicalContent.streaming(stream: controller.stream),
      );

      expect(find.byType(StreamMarkdown), findsOneWidget);
      expect(find.byType(SmoothMarkdown), findsNothing);
    });

    testWidgets('accumule les chunks dans StreamMarkdown', (tester) async {
      final controller = StreamController<String>();
      addTearDown(controller.close);

      await pumpInApp(
        tester,
        PedagogicalContent.streaming(stream: controller.stream),
      );

      controller.add('#');
      await tester.pump(const Duration(milliseconds: 100));
      controller.add(' Ti');
      await tester.pump(const Duration(milliseconds: 100));
      controller.add('tre');
      await tester.pump(const Duration(milliseconds: 100));

      // Le widget StreamMarkdown reçoit bien le flux (smoke level).
      // La validation textuelle exacte nécessite l'inspection RichText
      // qui dépend de la version du package (hors scope P0).
      expect(find.byType(StreamMarkdown), findsOneWidget);
    });
  });
}
