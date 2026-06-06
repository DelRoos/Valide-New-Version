// Story 1.2 — Providers Riverpod feature onboarding.
//
// 3 providers exposés :
//   1. `sharedPreferencesProvider` : instance préchargée en `main.dart`.
//      L'override en `ProviderScope` est OBLIGATOIRE — sans lui, toute
//      lecture lève `UnimplementedError` (garde défensive).
//   2. `subsystemPrefsProvider` : wrapper lazy autour de SharedPreferences.
//   3. `subSystemNotifierProvider` : state in-memory du sous-système choisi,
//      initialisé synchroniquement depuis SharedPreferences au build.
//      Notifie ses watchers (LocaleNotifier, GoRouter redirect) au changement.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/subsystem_prefs.dart';
import 'domain/sub_system.dart';

/// SharedPreferences préchargée en `main.dart` avant `runApp`.
///
/// MUST be overridden in `ProviderScope.overrides` :
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// runApp(ProviderScope(
///   overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
///   child: const ValideApp(),
/// ));
/// ```
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider doit être overridé dans ProviderScope.overrides '
    'avec l\'instance préchargée par main.dart. Voir Story 1.2 AC4.',
  );
});

/// Wrapper lazy autour de SharedPreferences pour le sous-système.
final subsystemPrefsProvider = Provider<SubsystemPrefs>((ref) {
  return SubsystemPrefs(ref.watch(sharedPreferencesProvider));
});

/// État courant du sous-système. Synchrone (le `sharedPreferencesProvider`
/// est préchargé). Notifie les watchers (LocaleNotifier dans `app.dart`,
/// redirect global de GoRouter dans `app_router.dart`) au changement.
class SubSystemNotifier extends Notifier<SubSystem?> {
  @override
  SubSystem? build() => ref.read(subsystemPrefsProvider).read();

  /// Persiste le choix + met à jour le state in-memory. La bascule de
  /// `MaterialApp.locale` se fait automatiquement (LocaleNotifier `ref.watch`).
  /// Le router re-évalue son redirect (refreshListenable écoute ce notifier).
  Future<void> set(SubSystem subSystem) async {
    await ref.read(subsystemPrefsProvider).write(subSystem);
    state = subSystem;
  }
}

final subSystemNotifierProvider =
    NotifierProvider<SubSystemNotifier, SubSystem?>(SubSystemNotifier.new);
