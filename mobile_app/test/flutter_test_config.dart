import 'dart:async';

import 'package:golden_toolkit/golden_toolkit.dart';

// Story E1bis-0 — bootstrap global tests : charge les polices de l'app
// (Nunito Sans + JetBrains Mono) AVANT chaque test. Sans cela, les
// goldens utilisent la font systeme Ahem et sont irreproductibles entre
// plateformes / CI.
//
// Reference : https://pub.dev/packages/golden_toolkit#loading-fonts
//
// Note : golden_toolkit est marque `discontinued` sur pub.dev mais reste
// fonctionnel (derniere release 0.15.0). Story future pourra basculer
// vers une alternative (alchemist, screenshot_widget) si necessaire.
//
// Configuration : on appelle `loadAppFonts()` directement (pas via
// runWithConfiguration qui exige une liste `defaultDevices` non-vide).
// Les goldens sont generes via matchesGoldenFile + setSurfaceSize, donc
// pas besoin du systeme multiScreenGolden de golden_toolkit.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  await testMain();
}
